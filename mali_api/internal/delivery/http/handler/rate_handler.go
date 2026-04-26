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

type RateUseCaser interface {
	SetManualRate(ctx context.Context, input usecase.SetManualRateInput) (*domain.ExchangeRate, error)
	GetRates(ctx context.Context, input usecase.GetRatesInput) ([]*domain.ExchangeRate, error)
	GetLatestRate(ctx context.Context, input usecase.GetLatestRateInput) (*domain.ExchangeRate, error)
}

type RateHandler struct {
	rateService RateUseCaser
	validator   *validator.Validate
}

type SetManualRateRequestDTO struct {
	FromCurrency string `json:"from_currency" validate:"required,len=3"`
	ToCurrency   string `json:"to_currency" validate:"required,len=3"`
	Rate         string `json:"rate" validate:"required"`
	ValidAt      string `json:"valid_at"`
}

type RateResponseDTO struct {
	ID           string `json:"id"`
	UserID       string `json:"user_id"`
	FromCurrency string `json:"from_currency"`
	ToCurrency   string `json:"to_currency"`
	Rate         string `json:"rate"`
	Source       string `json:"source"`
	ValidAt      string `json:"valid_at"`
}

func NewRateHandler(rateService RateUseCaser, validate *validator.Validate) *RateHandler {
	if validate == nil {
		validate = validator.New()
	}
	return &RateHandler{
		rateService: rateService,
		validator:   validate,
	}
}

func (h *RateHandler) ListRates(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	rates, err := h.rateService.GetRates(c.UserContext(), usecase.GetRatesInput{UserID: userID})
	if err != nil {
		status, code := mapRateError(err)
		return respondError(c, status, code, err.Error())
	}

	items := make([]RateResponseDTO, 0, len(rates))
	for _, rate := range rates {
		items = append(items, toRateResponse(rate))
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"rates": items,
	})
}

func (h *RateHandler) SetManualRate(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	var req SetManualRateRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}
	req.FromCurrency = strings.TrimSpace(req.FromCurrency)
	req.ToCurrency = strings.TrimSpace(req.ToCurrency)
	req.Rate = strings.TrimSpace(req.Rate)
	req.ValidAt = strings.TrimSpace(req.ValidAt)
	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	var validAt time.Time
	if req.ValidAt != "" {
		parsed, parseErr := time.Parse(time.RFC3339, req.ValidAt)
		if parseErr != nil {
			return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid valid_at")
		}
		validAt = parsed
	}

	created, err := h.rateService.SetManualRate(c.UserContext(), usecase.SetManualRateInput{
		UserID:       userID,
		FromCurrency: req.FromCurrency,
		ToCurrency:   req.ToCurrency,
		Rate:         req.Rate,
		ValidAt:      validAt,
	})
	if err != nil {
		status, code := mapRateError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"rate": toRateResponse(created),
	})
}

func (h *RateHandler) GetLatestRate(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	fromCurrency := strings.TrimSpace(c.Query("from_currency"))
	toCurrency := strings.TrimSpace(c.Query("to_currency"))
	if fromCurrency == "" || toCurrency == "" {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "from_currency and to_currency are required")
	}

	rate, err := h.rateService.GetLatestRate(c.UserContext(), usecase.GetLatestRateInput{
		UserID:       userID,
		FromCurrency: fromCurrency,
		ToCurrency:   toCurrency,
	})
	if err != nil {
		status, code := mapRateError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"rate": toRateResponse(rate),
	})
}

func (h *RateHandler) ensureConfigured(c *fiber.Ctx) error {
	if h.rateService != nil {
		return nil
	}
	return respondError(c, fiber.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "rate service is not configured")
}

func mapRateError(err error) (int, string) {
	switch {
	case errors.Is(err, usecase.ErrValidation):
		return fiber.StatusBadRequest, "VALIDATION_ERROR"
	default:
		return fiber.StatusInternalServerError, "INTERNAL_ERROR"
	}
}

func toRateResponse(rate *domain.ExchangeRate) RateResponseDTO {
	if rate == nil {
		return RateResponseDTO{}
	}
	return RateResponseDTO{
		ID:           rate.ID.String(),
		UserID:       rate.UserID.String(),
		FromCurrency: rate.FromCurrency,
		ToCurrency:   rate.ToCurrency,
		Rate:         rate.Rate,
		Source:       rate.Source,
		ValidAt:      rate.ValidAt.UTC().Format(time.RFC3339),
	}
}

