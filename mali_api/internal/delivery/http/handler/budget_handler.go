package handler

import (
	"context"
	"errors"
	"strconv"
	"strings"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/usecase"
)

type BudgetUseCaser interface {
	UpsertBudget(ctx context.Context, input usecase.UpsertBudgetInput) (*domain.Budget, error)
	GetBudgetStatus(ctx context.Context, input usecase.GetBudgetStatusInput) ([]usecase.BudgetStatus, error)
}

type BudgetHandler struct {
	budgetService BudgetUseCaser
	validator     *validator.Validate
}

type UpsertBudgetRequestDTO struct {
	CategoryID string `json:"category_id" validate:"required,uuid4"`
	Currency   string `json:"currency" validate:"required,len=3"`
	Amount     string `json:"amount" validate:"required"`
	Month      int32  `json:"month" validate:"required,min=1,max=12"`
	Year       int32  `json:"year" validate:"required,min=1"`
	Rollover   bool   `json:"rollover"`
}

type BudgetResponseDTO struct {
	ID         string `json:"id"`
	UserID     string `json:"user_id"`
	CategoryID string `json:"category_id"`
	Currency   string `json:"currency"`
	Amount     string `json:"amount"`
	Month      int32  `json:"month"`
	Year       int32  `json:"year"`
	Rollover   bool   `json:"rollover"`
}

type BudgetStatusResponseDTO struct {
	Budget      BudgetResponseDTO `json:"budget"`
	Spent       string            `json:"spent"`
	Remaining   string            `json:"remaining"`
	PercentUsed string            `json:"percent_used"`
}

func NewBudgetHandler(budgetService BudgetUseCaser, validate *validator.Validate) *BudgetHandler {
	if validate == nil {
		validate = validator.New()
	}
	return &BudgetHandler{
		budgetService: budgetService,
		validator:     validate,
	}
}

func (h *BudgetHandler) UpsertBudget(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	var req UpsertBudgetRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}
	req.CategoryID = strings.TrimSpace(req.CategoryID)
	req.Currency = strings.TrimSpace(req.Currency)
	req.Amount = strings.TrimSpace(req.Amount)
	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	categoryID, err := uuid.Parse(req.CategoryID)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid category_id")
	}

	budget, err := h.budgetService.UpsertBudget(c.UserContext(), usecase.UpsertBudgetInput{
		UserID:     userID,
		CategoryID: categoryID,
		Currency:   req.Currency,
		Amount:     req.Amount,
		Month:      req.Month,
		Year:       req.Year,
		Rollover:   req.Rollover,
	})
	if err != nil {
		status, code := mapBudgetError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"budget": toBudgetResponse(budget),
	})
}

func (h *BudgetHandler) ListBudgetStatus(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	monthValue := strings.TrimSpace(c.Query("month"))
	yearValue := strings.TrimSpace(c.Query("year"))
	if monthValue == "" || yearValue == "" {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "month and year are required")
	}

	month, err := strconv.Atoi(monthValue)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid month")
	}
	year, err := strconv.Atoi(yearValue)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid year")
	}

	statuses, err := h.budgetService.GetBudgetStatus(c.UserContext(), usecase.GetBudgetStatusInput{
		UserID: userID,
		Month:  int32(month),
		Year:   int32(year),
	})
	if err != nil {
		status, code := mapBudgetError(err)
		return respondError(c, status, code, err.Error())
	}

	items := make([]BudgetStatusResponseDTO, 0, len(statuses))
	for _, status := range statuses {
		items = append(items, BudgetStatusResponseDTO{
			Budget:      toBudgetResponse(status.Budget),
			Spent:       status.Spent,
			Remaining:   status.Remaining,
			PercentUsed: status.PercentUsed,
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"budgets": items,
	})
}

func (h *BudgetHandler) ensureConfigured(c *fiber.Ctx) error {
	if h.budgetService != nil {
		return nil
	}
	return respondError(c, fiber.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "budget service is not configured")
}

func mapBudgetError(err error) (int, string) {
	switch {
	case errors.Is(err, usecase.ErrValidation):
		return fiber.StatusBadRequest, "VALIDATION_ERROR"
	default:
		return fiber.StatusInternalServerError, "INTERNAL_ERROR"
	}
}

func toBudgetResponse(budget *domain.Budget) BudgetResponseDTO {
	if budget == nil {
		return BudgetResponseDTO{}
	}
	return BudgetResponseDTO{
		ID:         budget.ID.String(),
		UserID:     budget.UserID.String(),
		CategoryID: budget.CategoryID.String(),
		Currency:   budget.Currency,
		Amount:     budget.Amount,
		Month:      budget.Month,
		Year:       budget.Year,
		Rollover:   budget.Rollover,
	}
}

