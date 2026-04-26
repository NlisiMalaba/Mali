package handler

import (
	"context"
	"errors"
	"strconv"
	"strings"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/mali-app/mali_api/internal/usecase"
)

type AnalyticsUseCaser interface {
	GetMonthlyReport(ctx context.Context, input usecase.GetMonthlyReportInput) (*usecase.MonthlyReport, error)
	GetMonthlyTrend(ctx context.Context, input usecase.GetMonthlyTrendInput) ([]usecase.MonthlyTrendSummary, error)
	GetCategoryBreakdown(ctx context.Context, input usecase.GetCategoryBreakdownInput) ([]usecase.CategorySummary, error)
}

type AnalyticsHandler struct {
	analyticsService AnalyticsUseCaser
	validator        *validator.Validate
}

func NewAnalyticsHandler(analyticsService AnalyticsUseCaser, validate *validator.Validate) *AnalyticsHandler {
	if validate == nil {
		validate = validator.New()
	}
	return &AnalyticsHandler{
		analyticsService: analyticsService,
		validator:        validate,
	}
}

func (h *AnalyticsHandler) GetMonthlyReport(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	month, year, err := parseMonthYearQuery(c)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	trendMonths, err := parseOptionalInt32(c.Query("trend_months"))
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid trend_months")
	}

	report, err := h.analyticsService.GetMonthlyReport(c.UserContext(), usecase.GetMonthlyReportInput{
		UserID:      userID,
		Month:       month,
		Year:        year,
		TrendMonths: trendMonths,
	})
	if err != nil {
		status, code := mapAnalyticsError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"report": report})
}

func (h *AnalyticsHandler) GetMonthlyTrends(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	month, year, err := parseMonthYearQuery(c)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}
	months, err := parseOptionalInt32(c.Query("months"))
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid months")
	}

	trends, err := h.analyticsService.GetMonthlyTrend(c.UserContext(), usecase.GetMonthlyTrendInput{
		UserID: userID,
		Month:  month,
		Year:   year,
		Months: months,
	})
	if err != nil {
		status, code := mapAnalyticsError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"trends": trends})
}

func (h *AnalyticsHandler) GetCategoryBreakdown(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	month, year, err := parseMonthYearQuery(c)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	limitValue := strings.TrimSpace(c.Query("limit"))
	limit := 0
	if limitValue != "" {
		parsed, parseErr := strconv.Atoi(limitValue)
		if parseErr != nil {
			return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid limit")
		}
		limit = parsed
	}

	categories, err := h.analyticsService.GetCategoryBreakdown(c.UserContext(), usecase.GetCategoryBreakdownInput{
		UserID: userID,
		Month:  month,
		Year:   year,
		Limit:  limit,
	})
	if err != nil {
		status, code := mapAnalyticsError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"categories": categories})
}

func (h *AnalyticsHandler) ensureConfigured(c *fiber.Ctx) error {
	if h.analyticsService != nil {
		return nil
	}
	return respondError(c, fiber.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "analytics service is not configured")
}

func parseMonthYearQuery(c *fiber.Ctx) (int32, int32, error) {
	monthValue := strings.TrimSpace(c.Query("month"))
	yearValue := strings.TrimSpace(c.Query("year"))
	if monthValue == "" || yearValue == "" {
		return 0, 0, errors.New("month and year are required")
	}

	monthInt, err := strconv.Atoi(monthValue)
	if err != nil {
		return 0, 0, errors.New("invalid month")
	}
	yearInt, err := strconv.Atoi(yearValue)
	if err != nil {
		return 0, 0, errors.New("invalid year")
	}

	return int32(monthInt), int32(yearInt), nil
}

func parseOptionalInt32(raw string) (int32, error) {
	value := strings.TrimSpace(raw)
	if value == "" {
		return 0, nil
	}
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return 0, err
	}
	return int32(parsed), nil
}

func mapAnalyticsError(err error) (int, string) {
	switch {
	case errors.Is(err, usecase.ErrValidation):
		return fiber.StatusBadRequest, "VALIDATION_ERROR"
	default:
		return fiber.StatusInternalServerError, "INTERNAL_ERROR"
	}
}

