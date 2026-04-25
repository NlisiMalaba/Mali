package handler

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/usecase"
)

type WalletUseCaser interface {
	CreateWallet(ctx context.Context, input usecase.CreateWalletInput) (*domain.Wallet, error)
	ListWallets(ctx context.Context, userID uuid.UUID) ([]*domain.Wallet, error)
	UpdateName(ctx context.Context, input usecase.UpdateWalletNameInput) error
	Delete(ctx context.Context, input usecase.DeleteWalletInput) error
}

type WalletHandler struct {
	walletService WalletUseCaser
	validator     *validator.Validate
}

type CreateWalletRequestDTO struct {
	Name       string `json:"name" validate:"required"`
	Currency   string `json:"currency" validate:"required,len=3"`
	WalletType string `json:"wallet_type" validate:"required"`
	Balance    string `json:"balance"`
}

type UpdateWalletRequestDTO struct {
	Name string `json:"name" validate:"required"`
}

type WalletResponseDTO struct {
	ID             string `json:"id"`
	Name           string `json:"name"`
	Currency       string `json:"currency"`
	WalletType     string `json:"wallet_type"`
	Balance        string `json:"balance"`
	RunningBalance string `json:"running_balance"`
	IsActive       bool   `json:"is_active"`
	CreatedAt      string `json:"created_at"`
}

func NewWalletHandler(walletService WalletUseCaser, validate *validator.Validate) *WalletHandler {
	if validate == nil {
		validate = validator.New()
	}

	return &WalletHandler{
		walletService: walletService,
		validator:     validate,
	}
}

func (h *WalletHandler) ListWallets(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}

	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	wallets, err := h.walletService.ListWallets(c.UserContext(), userID)
	if err != nil {
		status, code := mapWalletError(err)
		return respondError(c, status, code, err.Error())
	}

	items := make([]WalletResponseDTO, 0, len(wallets))
	for _, wallet := range wallets {
		items = append(items, toWalletResponse(wallet))
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"wallets": items,
	})
}

func (h *WalletHandler) CreateWallet(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}

	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	var req CreateWalletRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}

	req.Name = strings.TrimSpace(req.Name)
	req.Currency = strings.TrimSpace(req.Currency)
	req.WalletType = strings.TrimSpace(req.WalletType)
	req.Balance = strings.TrimSpace(req.Balance)

	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	createdWallet, err := h.walletService.CreateWallet(c.UserContext(), usecase.CreateWalletInput{
		UserID:     userID,
		Name:       req.Name,
		Currency:   req.Currency,
		WalletType: req.WalletType,
		Balance:    req.Balance,
	})
	if err != nil {
		status, code := mapWalletError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"wallet": toWalletResponse(createdWallet),
	})
}

func (h *WalletHandler) UpdateWallet(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}

	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	walletID, err := walletIDParam(c)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	var req UpdateWalletRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}
	req.Name = strings.TrimSpace(req.Name)
	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	if err := h.walletService.UpdateName(c.UserContext(), usecase.UpdateWalletNameInput{
		UserID:   userID,
		WalletID: walletID,
		Name:     req.Name,
	}); err != nil {
		status, code := mapWalletError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "wallet updated successfully",
	})
}

func (h *WalletHandler) DeleteWallet(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}

	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	walletID, err := walletIDParam(c)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	if err := h.walletService.Delete(c.UserContext(), usecase.DeleteWalletInput{
		UserID:   userID,
		WalletID: walletID,
	}); err != nil {
		status, code := mapWalletError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "wallet deleted successfully",
	})
}

func (h *WalletHandler) ensureConfigured(c *fiber.Ctx) error {
	if h.walletService != nil {
		return nil
	}
	return respondError(c, fiber.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "wallet service is not configured")
}

func authenticatedUserID(c *fiber.Ctx) (uuid.UUID, error) {
	rawUserID, ok := c.Locals("userID").(string)
	if !ok || strings.TrimSpace(rawUserID) == "" {
		return uuid.Nil, errors.New("missing authenticated user")
	}

	userID, err := uuid.Parse(strings.TrimSpace(rawUserID))
	if err != nil {
		return uuid.Nil, errors.New("invalid authenticated user")
	}
	return userID, nil
}

func walletIDParam(c *fiber.Ctx) (uuid.UUID, error) {
	walletID := strings.TrimSpace(c.Params("id"))
	if walletID == "" {
		return uuid.Nil, errors.New("wallet id is required")
	}
	parsed, err := uuid.Parse(walletID)
	if err != nil {
		return uuid.Nil, errors.New("invalid wallet id")
	}
	return parsed, nil
}

func mapWalletError(err error) (int, string) {
	switch {
	case errors.Is(err, usecase.ErrValidation):
		return fiber.StatusBadRequest, "VALIDATION_ERROR"
	default:
		return fiber.StatusInternalServerError, "INTERNAL_ERROR"
	}
}

func toWalletResponse(wallet *domain.Wallet) WalletResponseDTO {
	if wallet == nil {
		return WalletResponseDTO{}
	}

	return WalletResponseDTO{
		ID:             wallet.ID.String(),
		Name:           wallet.Name,
		Currency:       wallet.Currency,
		WalletType:     wallet.WalletType,
		Balance:        wallet.Balance,
		RunningBalance: wallet.Balance,
		IsActive:       wallet.IsActive,
		CreatedAt:      wallet.CreatedAt.UTC().Format(time.RFC3339),
	}
}

