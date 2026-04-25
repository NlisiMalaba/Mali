package postgres

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/repository/sqlc"
)

type CategoryRepository struct {
	queries *sqlc.Queries
}

func NewCategoryRepository(queries *sqlc.Queries) *CategoryRepository {
	return &CategoryRepository{queries: queries}
}

var _ domain.ICategoryRepository = (*CategoryRepository)(nil)

func (r *CategoryRepository) GetSystemCategories(ctx context.Context) ([]*domain.Category, error) {
	rows, err := r.queries.GetSystemCategories(ctx)
	if err != nil {
		return nil, fmt.Errorf("get system categories: %w", err)
	}

	out := make([]*domain.Category, 0, len(rows))
	for _, row := range rows {
		mapped, mapErr := mapSQLCCategoryToDomain(row)
		if mapErr != nil {
			return nil, fmt.Errorf("map system category: %w", mapErr)
		}
		out = append(out, mapped)
	}
	return out, nil
}

func (r *CategoryRepository) GetUserCategories(ctx context.Context, userID uuid.UUID) ([]*domain.Category, error) {
	dbUserID, err := pgUUIDFromUUID(userID)
	if err != nil {
		return nil, fmt.Errorf("parse user id: %w", err)
	}

	rows, err := r.queries.GetUserCategories(ctx, dbUserID)
	if err != nil {
		return nil, fmt.Errorf("get user categories: %w", err)
	}

	out := make([]*domain.Category, 0, len(rows))
	for _, row := range rows {
		mapped, mapErr := mapSQLCCategoryToDomain(row)
		if mapErr != nil {
			return nil, fmt.Errorf("map user category: %w", mapErr)
		}
		out = append(out, mapped)
	}
	return out, nil
}

func (r *CategoryRepository) CreateUserCategory(ctx context.Context, category *domain.Category) (*domain.Category, error) {
	if category == nil || category.UserID == nil {
		return nil, fmt.Errorf("create user category: user id is required")
	}

	dbUserID, err := pgUUIDFromUUID(*category.UserID)
	if err != nil {
		return nil, fmt.Errorf("parse user id: %w", err)
	}

	created, err := r.queries.CreateUserCategory(ctx, sqlc.CreateUserCategoryParams{
		UserID:   dbUserID,
		Name:     category.Name,
		Icon:     category.Icon,
		ColorHex: category.ColorHex,
		Type:     category.Type,
	})
	if err != nil {
		return nil, fmt.Errorf("create user category: %w", err)
	}

	mapped, err := mapSQLCCategoryToDomain(created)
	if err != nil {
		return nil, fmt.Errorf("map created category: %w", err)
	}
	return mapped, nil
}

func mapSQLCCategoryToDomain(category sqlc.Category) (*domain.Category, error) {
	id, err := uuidFromPG(category.ID)
	if err != nil {
		return nil, fmt.Errorf("parse id: %w", err)
	}

	var userID *uuid.UUID
	if category.UserID.Valid {
		parsed, parseErr := uuidFromPG(category.UserID)
		if parseErr != nil {
			return nil, fmt.Errorf("parse user_id: %w", parseErr)
		}
		userID = &parsed
	}

	return &domain.Category{
		ID:       id,
		UserID:   userID,
		Name:     category.Name,
		Icon:     category.Icon,
		ColorHex: category.ColorHex,
		Type:     category.Type,
	}, nil
}

