package handler

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/usecase"
)

type AuthRegisterUseCaser interface {
	RegisterUseCase(ctx context.Context, input usecase.RegisterInput) (*domain.User, error)
	LoginUseCase(ctx context.Context, input usecase.LoginInput) (*usecase.LoginOutput, error)
	RefreshTokenUseCase(ctx context.Context, input usecase.RefreshTokenInput) (*usecase.RefreshTokenOutput, error)
	LogoutUseCase(ctx context.Context, input usecase.LogoutInput) error
}

const (
	refreshTokenCookieName = "refresh_token"
	refreshTokenCookieTTL  = 30 * 24 * time.Hour
)

type AuthHandler struct {
	authService AuthRegisterUseCaser
	validator   *validator.Validate
}

type RegisterRequestDTO struct {
	Email    string `json:"email" validate:"omitempty,email,required_without=Phone"`
	Phone    string `json:"phone" validate:"omitempty,required_without=Email"`
	Name     string `json:"name" validate:"required"`
	Password string `json:"password" validate:"required,min=8"`
}

type UserProfileResponse struct {
	ID        string  `json:"id"`
	Email     *string `json:"email,omitempty"`
	Phone     *string `json:"phone,omitempty"`
	Name      string  `json:"name"`
	CreatedAt string  `json:"created_at"`
}

type LoginRequestDTO struct {
	Email    string `json:"email" validate:"omitempty,email,required_without=Phone"`
	Phone    string `json:"phone" validate:"omitempty,required_without=Email"`
	Password string `json:"password" validate:"required"`
	DeviceID string `json:"device_id" validate:"required"`
}

type RefreshRequestDTO struct {
	RefreshToken string `json:"refresh_token"`
	DeviceID     string `json:"device_id" validate:"required"`
}

type LogoutRequestDTO struct {
	RefreshToken string `json:"refresh_token"`
}

func NewAuthHandler(authService AuthRegisterUseCaser, validate *validator.Validate) *AuthHandler {
	if validate == nil {
		validate = validator.New()
	}

	return &AuthHandler{
		authService: authService,
		validator:   validate,
	}
}

func (h *AuthHandler) Register(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}

	var req RegisterRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}

	req.Email = strings.TrimSpace(req.Email)
	req.Phone = strings.TrimSpace(req.Phone)
	req.Name = strings.TrimSpace(req.Name)
	req.Password = strings.TrimSpace(req.Password)

	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	createdUser, err := h.authService.RegisterUseCase(c.UserContext(), usecase.RegisterInput{
		Email:    req.Email,
		Phone:    req.Phone,
		Name:     req.Name,
		Password: req.Password,
	})
	if err != nil {
		status, code := mapAuthError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"user": UserProfileResponse{
			ID:        createdUser.ID.String(),
			Email:     createdUser.Email,
			Phone:     createdUser.Phone,
			Name:      createdUser.Name,
			CreatedAt: createdUser.CreatedAt.UTC().Format(time.RFC3339),
		},
	})
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}

	var req LoginRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}

	req.Email = strings.TrimSpace(req.Email)
	req.Phone = strings.TrimSpace(req.Phone)
	req.Password = strings.TrimSpace(req.Password)
	req.DeviceID = strings.TrimSpace(req.DeviceID)

	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	loginOut, err := h.authService.LoginUseCase(c.UserContext(), usecase.LoginInput{
		Email:    req.Email,
		Phone:    req.Phone,
		Password: req.Password,
		DeviceID: req.DeviceID,
	})
	if err != nil {
		status, code := mapAuthError(err)
		return respondError(c, status, code, err.Error())
	}

	setRefreshTokenCookie(c, loginOut.RefreshToken)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"access_token": loginOut.AccessToken,
	})
}

func (h *AuthHandler) Refresh(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}

	var req RefreshRequestDTO
	_ = c.BodyParser(&req)
	req.DeviceID = strings.TrimSpace(req.DeviceID)
	req.RefreshToken = strings.TrimSpace(req.RefreshToken)

	if req.RefreshToken == "" {
		req.RefreshToken = strings.TrimSpace(c.Cookies(refreshTokenCookieName))
	}

	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}
	if req.RefreshToken == "" {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "refresh token is required")
	}

	refreshOut, err := h.authService.RefreshTokenUseCase(c.UserContext(), usecase.RefreshTokenInput{
		RefreshToken: req.RefreshToken,
		DeviceID:     req.DeviceID,
	})
	if err != nil {
		status, code := mapAuthError(err)
		return respondError(c, status, code, err.Error())
	}

	setRefreshTokenCookie(c, refreshOut.RefreshToken)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"access_token": refreshOut.AccessToken,
	})
}

func (h *AuthHandler) Logout(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}

	var req LogoutRequestDTO
	_ = c.BodyParser(&req)
	req.RefreshToken = strings.TrimSpace(req.RefreshToken)
	if req.RefreshToken == "" {
		req.RefreshToken = strings.TrimSpace(c.Cookies(refreshTokenCookieName))
	}

	err := h.authService.LogoutUseCase(c.UserContext(), usecase.LogoutInput{
		RefreshToken: req.RefreshToken,
	})
	if err != nil {
		status, code := mapAuthError(err)
		return respondError(c, status, code, err.Error())
	}

	clearRefreshTokenCookie(c)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "logged out successfully",
	})
}

func (h *AuthHandler) ensureConfigured(c *fiber.Ctx) error {
	if h.authService != nil {
		return nil
	}

	return respondError(c, fiber.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "auth service is not configured")
}

func mapAuthError(err error) (int, string) {
	switch {
	case errors.Is(err, usecase.ErrValidation):
		return fiber.StatusBadRequest, "VALIDATION_ERROR"
	case errors.Is(err, usecase.ErrConflict):
		return fiber.StatusConflict, "CONFLICT"
	case errors.Is(err, usecase.ErrUnauthorized):
		return fiber.StatusUnauthorized, "UNAUTHORIZED"
	default:
		return fiber.StatusInternalServerError, "INTERNAL_ERROR"
	}
}

func respondError(c *fiber.Ctx, status int, code, message string) error {
	return c.Status(status).JSON(fiber.Map{
		"error": fiber.Map{
			"code":    code,
			"message": message,
		},
	})
}

func setRefreshTokenCookie(c *fiber.Ctx, token string) {
	c.Cookie(&fiber.Cookie{
		Name:     refreshTokenCookieName,
		Value:    token,
		HTTPOnly: true,
		Secure:   false,
		SameSite: fiber.CookieSameSiteStrictMode,
		Path:     "/",
		MaxAge:   int(refreshTokenCookieTTL.Seconds()),
	})
}

func clearRefreshTokenCookie(c *fiber.Ctx) {
	c.Cookie(&fiber.Cookie{
		Name:     refreshTokenCookieName,
		Value:    "",
		HTTPOnly: true,
		Secure:   false,
		SameSite: fiber.CookieSameSiteStrictMode,
		Path:     "/",
		MaxAge:   -1,
	})
}

