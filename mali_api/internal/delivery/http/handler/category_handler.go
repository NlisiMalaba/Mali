package handler

import (
	"context"
	"errors"
	"strings"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/usecase"
)

type CategoryUseCaser interface {
	ListCategories(ctx context.Context, userID uuid.UUID) ([]*domain.Category, error)
	CreateCategory(ctx context.Context, input usecase.CreateCategoryInput) (*domain.Category, error)
}

type CategoryHandler struct {
	categoryService CategoryUseCaser
	validator       *validator.Validate
}

type CreateCategoryRequestDTO struct {
	Name     string `json:"name" validate:"required"`
	Icon     string `json:"icon" validate:"required"`
	ColorHex string `json:"color_hex" validate:"required"`
	Type     string `json:"type" validate:"required,oneof=income expense"`
}

type CategoryResponseDTO struct {
	ID       string  `json:"id"`
	UserID   *string `json:"user_id,omitempty"`
	Name     string  `json:"name"`
	Icon     string  `json:"icon"`
	ColorHex string  `json:"color_hex"`
	Type     string  `json:"type"`
}

func NewCategoryHandler(categoryService CategoryUseCaser, validate *validator.Validate) *CategoryHandler {
	if validate == nil {
		validate = validator.New()
	}
	return &CategoryHandler{
		categoryService: categoryService,
		validator:       validate,
	}
}

func (h *CategoryHandler) ListCategories(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}

	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	categories, err := h.categoryService.ListCategories(c.UserContext(), userID)
	if err != nil {
		status, code := mapCategoryError(err)
		return respondError(c, status, code, err.Error())
	}

	items := make([]CategoryResponseDTO, 0, len(categories))
	for _, category := range categories {
		items = append(items, toCategoryResponse(category))
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"categories": items,
	})
}

func (h *CategoryHandler) CreateCategory(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}

	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	var req CreateCategoryRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}

	req.Name = strings.TrimSpace(req.Name)
	req.Icon = strings.TrimSpace(req.Icon)
	req.ColorHex = strings.TrimSpace(req.ColorHex)
	req.Type = strings.ToLower(strings.TrimSpace(req.Type))

	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	created, err := h.categoryService.CreateCategory(c.UserContext(), usecase.CreateCategoryInput{
		UserID:   userID,
		Name:     req.Name,
		Icon:     req.Icon,
		ColorHex: req.ColorHex,
		Type:     req.Type,
	})
	if err != nil {
		status, code := mapCategoryError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"category": toCategoryResponse(created),
	})
}

func (h *CategoryHandler) ensureConfigured(c *fiber.Ctx) error {
	if h.categoryService != nil {
		return nil
	}
	return respondError(c, fiber.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "category service is not configured")
}

func mapCategoryError(err error) (int, string) {
	switch {
	case errors.Is(err, usecase.ErrValidation):
		return fiber.StatusBadRequest, "VALIDATION_ERROR"
	default:
		return fiber.StatusInternalServerError, "INTERNAL_ERROR"
	}
}

func toCategoryResponse(category *domain.Category) CategoryResponseDTO {
	if category == nil {
		return CategoryResponseDTO{}
	}

	var userID *string
	if category.UserID != nil {
		value := category.UserID.String()
		userID = &value
	}

	return CategoryResponseDTO{
		ID:       category.ID.String(),
		UserID:   userID,
		Name:     category.Name,
		Icon:     category.Icon,
		ColorHex: category.ColorHex,
		Type:     category.Type,
	}
}

