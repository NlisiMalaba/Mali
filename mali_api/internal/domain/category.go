package domain

import (
	"context"

	"github.com/google/uuid"
)

type Category struct {
	ID       uuid.UUID
	UserID   *uuid.UUID
	Name     string
	Icon     string
	ColorHex string
	Type     string
}

type ICategoryRepository interface {
	GetSystemCategories(ctx context.Context) ([]*Category, error)
	GetUserCategories(ctx context.Context, userID uuid.UUID) ([]*Category, error)
	CreateUserCategory(ctx context.Context, category *Category) (*Category, error)
}

