package usecase

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
)

type CategoryService struct {
	categoryRepository domain.ICategoryRepository
}

type CreateCategoryInput struct {
	UserID   uuid.UUID
	Name     string
	Icon     string
	ColorHex string
	Type     string
}

func NewCategoryService(categoryRepository domain.ICategoryRepository) (*CategoryService, error) {
	if categoryRepository == nil {
		return nil, fmt.Errorf("%w: category repository is required", ErrValidation)
	}
	return &CategoryService{categoryRepository: categoryRepository}, nil
}

func (s *CategoryService) ListCategories(ctx context.Context, userID uuid.UUID) ([]*domain.Category, error) {
	if s.categoryRepository == nil {
		return nil, fmt.Errorf("category service dependencies are not configured")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	systemCategories, err := s.categoryRepository.GetSystemCategories(ctx)
	if err != nil {
		return nil, fmt.Errorf("get system categories: %w", err)
	}
	userCategories, err := s.categoryRepository.GetUserCategories(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get user categories: %w", err)
	}

	merged := make([]*domain.Category, 0, len(systemCategories)+len(userCategories))
	merged = append(merged, systemCategories...)
	merged = append(merged, userCategories...)
	return merged, nil
}

func (s *CategoryService) CreateCategory(ctx context.Context, input CreateCategoryInput) (*domain.Category, error) {
	if s.categoryRepository == nil {
		return nil, fmt.Errorf("category service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	name := strings.TrimSpace(input.Name)
	icon := strings.TrimSpace(input.Icon)
	colorHex := strings.TrimSpace(input.ColorHex)
	categoryType := strings.ToLower(strings.TrimSpace(input.Type))

	if name == "" {
		return nil, fmt.Errorf("%w: category name is required", ErrValidation)
	}
	if icon == "" {
		return nil, fmt.Errorf("%w: category icon is required", ErrValidation)
	}
	if colorHex == "" {
		return nil, fmt.Errorf("%w: category color is required", ErrValidation)
	}
	if categoryType != "income" && categoryType != "expense" {
		return nil, fmt.Errorf("%w: category type must be income or expense", ErrValidation)
	}

	userID := input.UserID
	created, err := s.categoryRepository.CreateUserCategory(ctx, &domain.Category{
		UserID:   &userID,
		Name:     name,
		Icon:     icon,
		ColorHex: colorHex,
		Type:     categoryType,
	})
	if err != nil {
		return nil, fmt.Errorf("create user category: %w", err)
	}
	return created, nil
}

