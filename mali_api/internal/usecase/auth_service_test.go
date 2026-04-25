package usecase

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/mali-app/mali_api/internal/domain"
	"golang.org/x/crypto/bcrypt"
)

type mockUserRepository struct {
	createFn      func(ctx context.Context, user *domain.User) (*domain.User, error)
	findByEmailFn func(ctx context.Context, email string) (*domain.User, error)
	findByPhoneFn func(ctx context.Context, phone string) (*domain.User, error)
}

func (m *mockUserRepository) Create(ctx context.Context, user *domain.User) (*domain.User, error) {
	return m.createFn(ctx, user)
}

func (m *mockUserRepository) FindByEmail(ctx context.Context, email string) (*domain.User, error) {
	if m.findByEmailFn == nil {
		return nil, errors.New("not implemented")
	}
	return m.findByEmailFn(ctx, email)
}

func (m *mockUserRepository) FindByPhone(ctx context.Context, phone string) (*domain.User, error) {
	if m.findByPhoneFn == nil {
		return nil, errors.New("not implemented")
	}
	return m.findByPhoneFn(ctx, phone)
}

func (m *mockUserRepository) FindByID(context.Context, uuid.UUID) (*domain.User, error) {
	return nil, errors.New("not implemented")
}

func (m *mockUserRepository) UpdatePassword(context.Context, uuid.UUID, string) error {
	return errors.New("not implemented")
}

type mockRefreshTokenRepository struct {
	tokens map[string]*domain.RefreshToken
}

func (m *mockRefreshTokenRepository) Create(_ context.Context, token *domain.RefreshToken) error {
	if m.tokens == nil {
		m.tokens = make(map[string]*domain.RefreshToken)
	}
	copied := *token
	m.tokens[token.TokenHash] = &copied
	return nil
}

func (m *mockRefreshTokenRepository) FindByTokenHash(_ context.Context, tokenHash string) (*domain.RefreshToken, error) {
	if m.tokens == nil {
		return nil, pgx.ErrNoRows
	}

	token, ok := m.tokens[tokenHash]
	if !ok {
		return nil, pgx.ErrNoRows
	}

	copied := *token
	return &copied, nil
}

func (m *mockRefreshTokenRepository) RevokeByID(_ context.Context, id uuid.UUID, revokedAt time.Time) error {
	for _, token := range m.tokens {
		if token.ID == id {
			revokedAtCopy := revokedAt
			token.RevokedAt = &revokedAtCopy
			return nil
		}
	}

	return pgx.ErrNoRows
}

func TestRegisterUseCase_DuplicateEmailReturnsConflict(t *testing.T) {
	t.Parallel()

	userRepo := &mockUserRepository{
		createFn: func(ctx context.Context, user *domain.User) (*domain.User, error) {
			return nil, &pgconn.PgError{Code: "23505"}
		},
	}

	service, err := NewAuthService(userRepo, &mockRefreshTokenRepository{}, "access-secret", "refresh-secret")
	if err != nil {
		t.Fatalf("create auth service: %v", err)
	}

	_, err = service.RegisterUseCase(context.Background(), RegisterInput{
		Email:    "duplicate@example.com",
		Name:     "Duplicate",
		Password: "password123",
	})
	if err == nil {
		t.Fatal("expected conflict error")
	}
	if !errors.Is(err, ErrConflict) {
		t.Fatalf("expected ErrConflict, got: %v", err)
	}
}

func TestRegisterUseCase_MissingEmailAndPhoneReturnsValidationError(t *testing.T) {
	t.Parallel()

	userRepo := &mockUserRepository{
		createFn: func(ctx context.Context, user *domain.User) (*domain.User, error) {
			return user, nil
		},
	}

	service, err := NewAuthService(userRepo, &mockRefreshTokenRepository{}, "access-secret", "refresh-secret")
	if err != nil {
		t.Fatalf("create auth service: %v", err)
	}

	_, err = service.RegisterUseCase(context.Background(), RegisterInput{
		Name:     "No Contact",
		Password: "password123",
	})
	if err == nil {
		t.Fatal("expected validation error")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got: %v", err)
	}
}

func TestRegisterUseCase_PasswordStoredAsHash(t *testing.T) {
	t.Parallel()

	var capturedUser *domain.User
	userRepo := &mockUserRepository{
		createFn: func(ctx context.Context, user *domain.User) (*domain.User, error) {
			copied := *user
			capturedUser = &copied
			return &copied, nil
		},
	}

	service, err := NewAuthService(userRepo, &mockRefreshTokenRepository{}, "access-secret", "refresh-secret")
	if err != nil {
		t.Fatalf("create auth service: %v", err)
	}

	rawPassword := "my-plain-password"
	_, err = service.RegisterUseCase(context.Background(), RegisterInput{
		Email:    "hash@example.com",
		Name:     "Hash User",
		Password: rawPassword,
	})
	if err != nil {
		t.Fatalf("register user: %v", err)
	}

	if capturedUser == nil || capturedUser.PasswordHash == nil {
		t.Fatal("expected captured password hash")
	}

	if strings.TrimSpace(*capturedUser.PasswordHash) == "" {
		t.Fatal("expected non-empty password hash")
	}
	if *capturedUser.PasswordHash == rawPassword {
		t.Fatal("password hash should not equal raw password")
	}
	if err := bcrypt.CompareHashAndPassword([]byte(*capturedUser.PasswordHash), []byte(rawPassword)); err != nil {
		t.Fatalf("expected stored hash to match raw password: %v", err)
	}
}

func TestLoginUseCase_WrongPasswordReturnsUnauthorized(t *testing.T) {
	t.Parallel()

	hashed, err := bcrypt.GenerateFromPassword([]byte("correct-password"), bcryptCost)
	if err != nil {
		t.Fatalf("generate hash: %v", err)
	}
	hash := string(hashed)

	userRepo := &mockUserRepository{
		findByEmailFn: func(ctx context.Context, email string) (*domain.User, error) {
			return &domain.User{
				ID:           uuid.New(),
				Email:        &email,
				Name:         "Test User",
				PasswordHash: &hash,
			}, nil
		},
	}

	service, err := NewAuthService(userRepo, &mockRefreshTokenRepository{}, "access-secret", "refresh-secret")
	if err != nil {
		t.Fatalf("create auth service: %v", err)
	}

	_, err = service.LoginUseCase(context.Background(), LoginInput{
		Email:    "user@example.com",
		Password: "wrong-password",
		DeviceID: "device-1",
	})
	if err == nil {
		t.Fatal("expected unauthorized error")
	}
	if !errors.Is(err, ErrUnauthorized) {
		t.Fatalf("expected ErrUnauthorized, got: %v", err)
	}
}

func TestLoginUseCase_UnknownEmailReturnsUnauthorized(t *testing.T) {
	t.Parallel()

	userRepo := &mockUserRepository{
		findByEmailFn: func(ctx context.Context, email string) (*domain.User, error) {
			return nil, pgx.ErrNoRows
		},
	}

	service, err := NewAuthService(userRepo, &mockRefreshTokenRepository{}, "access-secret", "refresh-secret")
	if err != nil {
		t.Fatalf("create auth service: %v", err)
	}

	_, err = service.LoginUseCase(context.Background(), LoginInput{
		Email:    "missing@example.com",
		Password: "password123",
		DeviceID: "device-1",
	})
	if err == nil {
		t.Fatal("expected unauthorized error")
	}
	if !errors.Is(err, ErrUnauthorized) {
		t.Fatalf("expected ErrUnauthorized, got: %v", err)
	}
}

func TestLoginUseCase_SuccessReturnsValidJWT(t *testing.T) {
	t.Parallel()

	hashed, err := bcrypt.GenerateFromPassword([]byte("password123"), bcryptCost)
	if err != nil {
		t.Fatalf("generate hash: %v", err)
	}
	hash := string(hashed)
	userID := uuid.New()
	email := "ok@example.com"

	userRepo := &mockUserRepository{
		findByEmailFn: func(ctx context.Context, inputEmail string) (*domain.User, error) {
			return &domain.User{
				ID:           userID,
				Email:        &email,
				Name:         "Ok User",
				PasswordHash: &hash,
			}, nil
		},
	}

	service, err := NewAuthService(userRepo, &mockRefreshTokenRepository{}, "access-secret", "refresh-secret")
	if err != nil {
		t.Fatalf("create auth service: %v", err)
	}

	out, err := service.LoginUseCase(context.Background(), LoginInput{
		Email:    email,
		Password: "password123",
		DeviceID: "device-1",
	})
	if err != nil {
		t.Fatalf("login use case: %v", err)
	}
	if strings.TrimSpace(out.AccessToken) == "" || strings.TrimSpace(out.RefreshToken) == "" {
		t.Fatal("expected non-empty access and refresh tokens")
	}

	claims := jwt.MapClaims{}
	parsed, err := jwt.ParseWithClaims(out.AccessToken, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte("access-secret"), nil
	})
	if err != nil || parsed == nil || !parsed.Valid {
		t.Fatalf("expected valid access jwt, err=%v", err)
	}
	if claims["sub"] != userID.String() {
		t.Fatalf("unexpected sub claim, got=%v want=%s", claims["sub"], userID.String())
	}
	if claims["token_type"] != "access" {
		t.Fatalf("unexpected token_type claim, got=%v", claims["token_type"])
	}
}

func TestRefreshTokenUseCase_RotationInvalidatesOldToken(t *testing.T) {
	t.Parallel()

	hashed, err := bcrypt.GenerateFromPassword([]byte("password123"), bcryptCost)
	if err != nil {
		t.Fatalf("generate hash: %v", err)
	}
	hash := string(hashed)
	userID := uuid.New()
	email := "rotate@example.com"

	userRepo := &mockUserRepository{
		findByEmailFn: func(ctx context.Context, inputEmail string) (*domain.User, error) {
			return &domain.User{
				ID:           userID,
				Email:        &email,
				Name:         "Rotate User",
				PasswordHash: &hash,
			}, nil
		},
	}
	refreshRepo := &mockRefreshTokenRepository{}

	service, err := NewAuthService(userRepo, refreshRepo, "access-secret", "refresh-secret")
	if err != nil {
		t.Fatalf("create auth service: %v", err)
	}

	loginOut, err := service.LoginUseCase(context.Background(), LoginInput{
		Email:    email,
		Password: "password123",
		DeviceID: "device-rotation",
	})
	if err != nil {
		t.Fatalf("login use case: %v", err)
	}

	refreshOut, err := service.RefreshTokenUseCase(context.Background(), RefreshTokenInput{
		RefreshToken: loginOut.RefreshToken,
		DeviceID:     "device-rotation",
	})
	if err != nil {
		t.Fatalf("refresh token use case: %v", err)
	}
	if strings.TrimSpace(refreshOut.AccessToken) == "" || strings.TrimSpace(refreshOut.RefreshToken) == "" {
		t.Fatal("expected rotated token pair")
	}
	if refreshOut.RefreshToken == loginOut.RefreshToken {
		t.Fatal("expected rotated refresh token to differ from original")
	}

	_, err = service.RefreshTokenUseCase(context.Background(), RefreshTokenInput{
		RefreshToken: loginOut.RefreshToken,
		DeviceID:     "device-rotation",
	})
	if err == nil {
		t.Fatal("expected old refresh token to be rejected")
	}
	if !errors.Is(err, ErrUnauthorized) {
		t.Fatalf("expected ErrUnauthorized when reusing old refresh token, got: %v", err)
	}
}

