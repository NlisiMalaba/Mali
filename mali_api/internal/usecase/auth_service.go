package usecase

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/mali-app/mali_api/internal/domain"
	"golang.org/x/crypto/bcrypt"
)

const bcryptCost = 12

var (
	ErrValidation = errors.New("validation error")
	ErrConflict   = errors.New("conflict")
	ErrUnauthorized = errors.New("unauthorized")
)

const (
	accessTokenTTL  = 15 * time.Minute
	refreshTokenTTL = 30 * 24 * time.Hour
)

type RegisterInput struct {
	Email    string
	Phone    string
	Name     string
	Password string
}

type AuthService struct {
	userRepository         domain.IUserRepository
	refreshTokenRepository domain.IRefreshTokenRepository
	accessSecret           []byte
	refreshSecret          []byte
	now                    func() time.Time
}

func NewAuthService(
	userRepository domain.IUserRepository,
	refreshTokenRepository domain.IRefreshTokenRepository,
	accessTokenSecret string,
	refreshTokenSecret string,
) (*AuthService, error) {
	if strings.TrimSpace(accessTokenSecret) == "" {
		return nil, fmt.Errorf("%w: access token secret is required", ErrValidation)
	}
	if strings.TrimSpace(refreshTokenSecret) == "" {
		return nil, fmt.Errorf("%w: refresh token secret is required", ErrValidation)
	}

	return &AuthService{
		userRepository:         userRepository,
		refreshTokenRepository: refreshTokenRepository,
		accessSecret:           []byte(accessTokenSecret),
		refreshSecret:          []byte(refreshTokenSecret),
		now:                    time.Now,
	}, nil
}

func (s *AuthService) RegisterUseCase(ctx context.Context, input RegisterInput) (*domain.User, error) {
	if s.userRepository == nil {
		return nil, fmt.Errorf("user repository is not configured")
	}

	email := normalizeOptionalField(input.Email)
	phone := normalizeOptionalField(input.Phone)
	name := strings.TrimSpace(input.Name)
	password := strings.TrimSpace(input.Password)

	if email == nil && phone == nil {
		return nil, fmt.Errorf("%w: email or phone is required", ErrValidation)
	}
	if name == "" {
		return nil, fmt.Errorf("%w: name is required", ErrValidation)
	}
	if password == "" {
		return nil, fmt.Errorf("%w: password is required", ErrValidation)
	}

	passwordHashBytes, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	passwordHash := string(passwordHashBytes)
	userToCreate := &domain.User{
		Email:        email,
		Phone:        phone,
		Name:         name,
		PasswordHash: &passwordHash,
	}

	createdUser, err := s.userRepository.Create(ctx, userToCreate)
	if err != nil {
		if isUniqueConstraintViolation(err) {
			return nil, fmt.Errorf("%w: user already exists", ErrConflict)
		}
		return nil, fmt.Errorf("create user: %w", err)
	}

	return createdUser, nil
}

type LoginInput struct {
	Email    string
	Phone    string
	Password string
	DeviceID string
}

type LoginOutput struct {
	AccessToken  string
	RefreshToken string
	User         *domain.User
}

type RefreshTokenInput struct {
	RefreshToken string
	DeviceID     string
}

type RefreshTokenOutput struct {
	AccessToken  string
	RefreshToken string
}

func (s *AuthService) LoginUseCase(ctx context.Context, input LoginInput) (*LoginOutput, error) {
	if s.userRepository == nil || s.refreshTokenRepository == nil {
		return nil, fmt.Errorf("auth service dependencies are not configured")
	}
	if len(s.accessSecret) == 0 || len(s.refreshSecret) == 0 {
		return nil, fmt.Errorf("jwt secrets are not configured")
	}

	email := normalizeOptionalField(input.Email)
	phone := normalizeOptionalField(input.Phone)
	password := strings.TrimSpace(input.Password)
	deviceID := strings.TrimSpace(input.DeviceID)

	if email == nil && phone == nil {
		return nil, fmt.Errorf("%w: email or phone is required", ErrValidation)
	}
	if password == "" {
		return nil, fmt.Errorf("%w: password is required", ErrValidation)
	}
	if deviceID == "" {
		return nil, fmt.Errorf("%w: device_id is required", ErrValidation)
	}

	user, err := s.findUserForLogin(ctx, email, phone)
	if err != nil {
		return nil, err
	}

	if user.PasswordHash == nil || strings.TrimSpace(*user.PasswordHash) == "" {
		return nil, fmt.Errorf("%w: invalid credentials", ErrUnauthorized)
	}

	if err := bcrypt.CompareHashAndPassword([]byte(*user.PasswordHash), []byte(password)); err != nil {
		return nil, fmt.Errorf("%w: invalid credentials", ErrUnauthorized)
	}

	now := s.now()
	accessToken, err := s.generateToken(user.ID, now, accessTokenTTL, "access", s.accessSecret)
	if err != nil {
		return nil, fmt.Errorf("generate access token: %w", err)
	}

	refreshToken, err := s.generateToken(user.ID, now, refreshTokenTTL, "refresh", s.refreshSecret)
	if err != nil {
		return nil, fmt.Errorf("generate refresh token: %w", err)
	}

	refreshTokenID := uuid.New()
	refreshTokenHash := hashToken(refreshToken)
	refreshTokenRecord := &domain.RefreshToken{
		ID:        refreshTokenID,
		UserID:    user.ID,
		TokenHash: refreshTokenHash,
		DeviceID:  deviceID,
		ExpiresAt: now.Add(refreshTokenTTL),
		CreatedAt: now,
	}

	if err := s.refreshTokenRepository.Create(ctx, refreshTokenRecord); err != nil {
		return nil, fmt.Errorf("store refresh token: %w", err)
	}

	return &LoginOutput{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	}, nil
}

func (s *AuthService) RefreshTokenUseCase(ctx context.Context, input RefreshTokenInput) (*RefreshTokenOutput, error) {
	if s.userRepository == nil || s.refreshTokenRepository == nil {
		return nil, fmt.Errorf("auth service dependencies are not configured")
	}
	if len(s.accessSecret) == 0 || len(s.refreshSecret) == 0 {
		return nil, fmt.Errorf("jwt secrets are not configured")
	}

	refreshToken := strings.TrimSpace(input.RefreshToken)
	deviceID := strings.TrimSpace(input.DeviceID)

	if refreshToken == "" {
		return nil, fmt.Errorf("%w: refresh token is required", ErrValidation)
	}
	if deviceID == "" {
		return nil, fmt.Errorf("%w: device_id is required", ErrValidation)
	}

	claims, err := s.parseRefreshToken(refreshToken)
	if err != nil {
		return nil, err
	}

	userID, err := parseUserIDFromClaims(claims)
	if err != nil {
		return nil, fmt.Errorf("%w: invalid refresh token", ErrUnauthorized)
	}

	now := s.now()
	storedToken, err := s.refreshTokenRepository.FindByTokenHash(ctx, hashToken(refreshToken))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("%w: refresh token not found", ErrUnauthorized)
		}
		return nil, fmt.Errorf("find refresh token: %w", err)
	}

	if storedToken.RevokedAt != nil {
		return nil, fmt.Errorf("%w: refresh token revoked", ErrUnauthorized)
	}
	if now.After(storedToken.ExpiresAt) {
		return nil, fmt.Errorf("%w: refresh token expired", ErrUnauthorized)
	}
	if storedToken.DeviceID != deviceID {
		return nil, fmt.Errorf("%w: invalid refresh token device", ErrUnauthorized)
	}
	if storedToken.UserID != userID {
		return nil, fmt.Errorf("%w: invalid refresh token subject", ErrUnauthorized)
	}

	if err := s.refreshTokenRepository.RevokeByID(ctx, storedToken.ID, now); err != nil {
		return nil, fmt.Errorf("revoke refresh token: %w", err)
	}

	accessToken, err := s.generateToken(userID, now, accessTokenTTL, "access", s.accessSecret)
	if err != nil {
		return nil, fmt.Errorf("generate access token: %w", err)
	}
	newRefreshToken, err := s.generateToken(userID, now, refreshTokenTTL, "refresh", s.refreshSecret)
	if err != nil {
		return nil, fmt.Errorf("generate refresh token: %w", err)
	}

	newTokenRecord := &domain.RefreshToken{
		ID:        uuid.New(),
		UserID:    userID,
		TokenHash: hashToken(newRefreshToken),
		DeviceID:  deviceID,
		ExpiresAt: now.Add(refreshTokenTTL),
		CreatedAt: now,
	}
	if err := s.refreshTokenRepository.Create(ctx, newTokenRecord); err != nil {
		return nil, fmt.Errorf("store refresh token: %w", err)
	}

	return &RefreshTokenOutput{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
	}, nil
}

func (s *AuthService) findUserForLogin(ctx context.Context, email, phone *string) (*domain.User, error) {
	var (
		user *domain.User
		err  error
	)

	if email != nil {
		user, err = s.userRepository.FindByEmail(ctx, *email)
	} else {
		user, err = s.userRepository.FindByPhone(ctx, *phone)
	}
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("%w: invalid credentials", ErrUnauthorized)
		}
		return nil, fmt.Errorf("find user: %w", err)
	}

	return user, nil
}

func (s *AuthService) generateToken(
	userID uuid.UUID,
	now time.Time,
	ttl time.Duration,
	tokenType string,
	secret []byte,
) (string, error) {
	claims := jwt.MapClaims{
		"sub":        userID.String(),
		"jti":        uuid.NewString(),
		"token_type": tokenType,
		"iat":        now.Unix(),
		"exp":        now.Add(ttl).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString(secret)
	if err != nil {
		return "", err
	}

	return signed, nil
}

func (s *AuthService) parseRefreshToken(tokenString string) (jwt.MapClaims, error) {
	claims := jwt.MapClaims{}
	parsedToken, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		if token.Method == nil {
			return nil, fmt.Errorf("unexpected signing method: <nil>")
		}
		if token.Method.Alg() != jwt.SigningMethodHS256.Alg() {
			return nil, fmt.Errorf("unexpected signing method: %s", token.Method.Alg())
		}
		return s.refreshSecret, nil
	})
	if err != nil || !parsedToken.Valid {
		return nil, fmt.Errorf("%w: invalid refresh token", ErrUnauthorized)
	}

	tokenType, _ := claims["token_type"].(string)
	if tokenType != "refresh" {
		return nil, fmt.Errorf("%w: invalid token type", ErrUnauthorized)
	}

	return claims, nil
}

func normalizeOptionalField(value string) *string {
	v := strings.TrimSpace(value)
	if v == "" {
		return nil
	}
	return &v
}

func isUniqueConstraintViolation(err error) bool {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return false
	}
	return pgErr.Code == "23505"
}

func hashToken(value string) string {
	sum := sha256.Sum256([]byte(value))
	return hex.EncodeToString(sum[:])
}

func parseUserIDFromClaims(claims jwt.MapClaims) (uuid.UUID, error) {
	sub, ok := claims["sub"].(string)
	if !ok || strings.TrimSpace(sub) == "" {
		return uuid.Nil, fmt.Errorf("missing subject")
	}

	parsed, err := uuid.Parse(sub)
	if err != nil {
		return uuid.Nil, err
	}

	return parsed, nil
}

