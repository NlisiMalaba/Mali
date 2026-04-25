package handler

import (
	"context"
	"errors"
	"strconv"
	"strings"
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/usecase"
)

type TransactionUseCaser interface {
	CreateTransaction(ctx context.Context, input usecase.LogTransactionInput) (*domain.Transaction, bool, error)
	ListTransactions(ctx context.Context, input usecase.ListTransactionsInput) (*usecase.ListTransactionsOutput, error)
	GetTransaction(ctx context.Context, input usecase.GetTransactionInput) (*domain.Transaction, error)
	DeleteTransaction(ctx context.Context, input usecase.DeleteTransactionInput) error
}

type TransactionHandler struct {
	transactionService TransactionUseCaser
	validator          *validator.Validate
}

type CreateTransactionRequestDTO struct {
	WalletID           string  `json:"wallet_id" validate:"required,uuid4"`
	CategoryID         *string `json:"category_id,omitempty" validate:"omitempty,uuid4"`
	Type               string  `json:"type" validate:"required,oneof=income expense transfer"`
	Amount             string  `json:"amount" validate:"required"`
	Currency           string  `json:"currency" validate:"required,len=3"`
	Notes              string  `json:"notes"`
	Source             string  `json:"source" validate:"required"`
	TransactedAt       string  `json:"transacted_at" validate:"required"`
	SyncID             *string `json:"sync_id,omitempty" validate:"omitempty,uuid4"`
	TransferToWalletID *string `json:"transfer_to_wallet_id,omitempty" validate:"omitempty,uuid4"`
	ExchangeRate       string  `json:"exchange_rate"`
}

type TransactionResponseDTO struct {
	ID                 string  `json:"id"`
	UserID             string  `json:"user_id"`
	WalletID           string  `json:"wallet_id"`
	CategoryID         *string `json:"category_id,omitempty"`
	Type               string  `json:"type"`
	Amount             string  `json:"amount"`
	Currency           string  `json:"currency"`
	Notes              *string `json:"notes,omitempty"`
	Source             string  `json:"source"`
	TransactedAt       string  `json:"transacted_at"`
	CreatedAt          string  `json:"created_at"`
	SyncID             *string `json:"sync_id,omitempty"`
	TransferToWalletID *string `json:"transfer_to_wallet_id,omitempty"`
	ExchangeRate       *string `json:"exchange_rate,omitempty"`
}

func NewTransactionHandler(transactionService TransactionUseCaser, validate *validator.Validate) *TransactionHandler {
	if validate == nil {
		validate = validator.New()
	}
	return &TransactionHandler{
		transactionService: transactionService,
		validator:          validate,
	}
}

func (h *TransactionHandler) CreateTransaction(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	var req CreateTransactionRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}
	req.Type = strings.ToLower(strings.TrimSpace(req.Type))
	req.Amount = strings.TrimSpace(req.Amount)
	req.Currency = strings.TrimSpace(req.Currency)
	req.Notes = strings.TrimSpace(req.Notes)
	req.Source = strings.TrimSpace(req.Source)
	req.TransactedAt = strings.TrimSpace(req.TransactedAt)
	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	walletID, err := uuid.Parse(req.WalletID)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid wallet_id")
	}
	transactedAt, err := time.Parse(time.RFC3339, req.TransactedAt)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid transacted_at")
	}

	var categoryID *uuid.UUID
	if req.CategoryID != nil {
		parsed, parseErr := uuid.Parse(strings.TrimSpace(*req.CategoryID))
		if parseErr != nil {
			return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid category_id")
		}
		categoryID = &parsed
	}

	var syncID *uuid.UUID
	if req.SyncID != nil {
		parsed, parseErr := uuid.Parse(strings.TrimSpace(*req.SyncID))
		if parseErr != nil {
			return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid sync_id")
		}
		syncID = &parsed
	}

	var transferToWalletID *uuid.UUID
	if req.TransferToWalletID != nil {
		parsed, parseErr := uuid.Parse(strings.TrimSpace(*req.TransferToWalletID))
		if parseErr != nil {
			return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid transfer_to_wallet_id")
		}
		transferToWalletID = &parsed
	}

	created, existed, err := h.transactionService.CreateTransaction(c.UserContext(), usecase.LogTransactionInput{
		UserID:             userID,
		WalletID:           walletID,
		CategoryID:         categoryID,
		Type:               req.Type,
		Amount:             req.Amount,
		Currency:           req.Currency,
		Notes:              req.Notes,
		Source:             req.Source,
		TransactedAt:       transactedAt,
		SyncID:             syncID,
		TransferToWalletID: transferToWalletID,
		ExchangeRate:       strings.TrimSpace(req.ExchangeRate),
	})
	if err != nil {
		status, code := mapTransactionError(err)
		return respondError(c, status, code, err.Error())
	}

	if existed {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"transaction": toTransactionResponse(created),
		})
	}
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"transaction": toTransactionResponse(created),
	})
}

func (h *TransactionHandler) ListTransactions(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	listInput, err := buildListTransactionsInput(c, userID)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	listed, err := h.transactionService.ListTransactions(c.UserContext(), listInput)
	if err != nil {
		status, code := mapTransactionError(err)
		return respondError(c, status, code, err.Error())
	}

	items := make([]TransactionResponseDTO, 0, len(listed.Transactions))
	for _, tx := range listed.Transactions {
		items = append(items, toTransactionResponse(tx))
	}

	response := fiber.Map{
		"transactions": items,
	}
	if listed.NextCursor != nil {
		response["next_cursor"] = fiber.Map{
			"transacted_at": listed.NextCursor.TransactedAt.UTC().Format(time.RFC3339),
			"id":            listed.NextCursor.ID.String(),
		}
	}
	return c.Status(fiber.StatusOK).JSON(response)
}

func (h *TransactionHandler) GetTransaction(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	transactionID, err := transactionIDParam(c)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	record, err := h.transactionService.GetTransaction(c.UserContext(), usecase.GetTransactionInput{
		UserID:        userID,
		TransactionID: transactionID,
	})
	if err != nil {
		status, code := mapTransactionError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"transaction": toTransactionResponse(record),
	})
}

func (h *TransactionHandler) DeleteTransaction(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}
	transactionID, err := transactionIDParam(c)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	if err := h.transactionService.DeleteTransaction(c.UserContext(), usecase.DeleteTransactionInput{
		UserID:        userID,
		TransactionID: transactionID,
	}); err != nil {
		status, code := mapTransactionError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "transaction deleted successfully",
	})
}

func (h *TransactionHandler) ensureConfigured(c *fiber.Ctx) error {
	if h.transactionService != nil {
		return nil
	}
	return respondError(c, fiber.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "transaction service is not configured")
}

func transactionIDParam(c *fiber.Ctx) (uuid.UUID, error) {
	txID := strings.TrimSpace(c.Params("id"))
	if txID == "" {
		return uuid.Nil, errors.New("transaction id is required")
	}
	parsed, err := uuid.Parse(txID)
	if err != nil {
		return uuid.Nil, errors.New("invalid transaction id")
	}
	return parsed, nil
}

func buildListTransactionsInput(c *fiber.Ctx, userID uuid.UUID) (usecase.ListTransactionsInput, error) {
	input := usecase.ListTransactionsInput{
		UserID: userID,
		Type:   strings.ToLower(strings.TrimSpace(c.Query("type"))),
		Sort:   strings.ToLower(strings.TrimSpace(c.Query("sort"))),
	}

	walletIDValue := strings.TrimSpace(c.Query("wallet_id"))
	if walletIDValue != "" {
		parsed, err := uuid.Parse(walletIDValue)
		if err != nil {
			return usecase.ListTransactionsInput{}, errors.New("invalid wallet_id")
		}
		input.WalletID = &parsed
	}

	categoryIDValue := strings.TrimSpace(c.Query("category_id"))
	if categoryIDValue != "" {
		parsed, err := uuid.Parse(categoryIDValue)
		if err != nil {
			return usecase.ListTransactionsInput{}, errors.New("invalid category_id")
		}
		input.CategoryID = &parsed
	}

	dateFromValue := strings.TrimSpace(c.Query("date_from"))
	if dateFromValue != "" {
		parsed, err := time.Parse(time.RFC3339, dateFromValue)
		if err != nil {
			return usecase.ListTransactionsInput{}, errors.New("invalid date_from")
		}
		input.DateFrom = &parsed
	}

	dateToValue := strings.TrimSpace(c.Query("date_to"))
	if dateToValue != "" {
		parsed, err := time.Parse(time.RFC3339, dateToValue)
		if err != nil {
			return usecase.ListTransactionsInput{}, errors.New("invalid date_to")
		}
		input.DateTo = &parsed
	}

	limitValue := strings.TrimSpace(c.Query("limit"))
	if limitValue != "" {
		parsed, err := strconv.Atoi(limitValue)
		if err != nil {
			return usecase.ListTransactionsInput{}, errors.New("invalid limit")
		}
		input.Limit = parsed
	}

	cursorIDValue := strings.TrimSpace(c.Query("cursor_id"))
	cursorDateValue := strings.TrimSpace(c.Query("cursor_transacted_at"))
	if cursorIDValue != "" || cursorDateValue != "" {
		if cursorIDValue == "" || cursorDateValue == "" {
			return usecase.ListTransactionsInput{}, errors.New("cursor_id and cursor_transacted_at are both required")
		}
		cursorID, err := uuid.Parse(cursorIDValue)
		if err != nil {
			return usecase.ListTransactionsInput{}, errors.New("invalid cursor_id")
		}
		cursorTime, err := time.Parse(time.RFC3339, cursorDateValue)
		if err != nil {
			return usecase.ListTransactionsInput{}, errors.New("invalid cursor_transacted_at")
		}
		input.Cursor = &usecase.TransactionListCursor{
			ID:           cursorID,
			TransactedAt: cursorTime,
		}
	}

	return input, nil
}

func mapTransactionError(err error) (int, string) {
	switch {
	case errors.Is(err, usecase.ErrValidation):
		return fiber.StatusBadRequest, "VALIDATION_ERROR"
	default:
		return fiber.StatusInternalServerError, "INTERNAL_ERROR"
	}
}

func toTransactionResponse(tx *domain.Transaction) TransactionResponseDTO {
	if tx == nil {
		return TransactionResponseDTO{}
	}

	return TransactionResponseDTO{
		ID:                 tx.ID.String(),
		UserID:             tx.UserID.String(),
		WalletID:           tx.WalletID.String(),
		CategoryID:         optionalUUIDString(tx.CategoryID),
		Type:               tx.Type,
		Amount:             tx.Amount,
		Currency:           tx.Currency,
		Notes:              tx.Notes,
		Source:             tx.Source,
		TransactedAt:       tx.TransactedAt.UTC().Format(time.RFC3339),
		CreatedAt:          tx.CreatedAt.UTC().Format(time.RFC3339),
		SyncID:             optionalUUIDString(tx.SyncID),
		TransferToWalletID: optionalUUIDString(tx.TransferToWalletID),
		ExchangeRate:       tx.ExchangeRate,
	}
}

func optionalUUIDString(value *uuid.UUID) *string {
	if value == nil {
		return nil
	}
	out := value.String()
	return &out
}

