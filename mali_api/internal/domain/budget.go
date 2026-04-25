package domain

import (
	"context"

	"github.com/google/uuid"
)

type Budget struct {
	ID         uuid.UUID
	UserID     uuid.UUID
	CategoryID uuid.UUID
	Currency   string
	Amount     string
	Month      int32
	Year       int32
	Rollover   bool
}

type IBudgetRepository interface {
	Upsert(ctx context.Context, budget *Budget) (*Budget, error)
	ListByUserMonth(ctx context.Context, userID uuid.UUID, month, year int32) ([]*Budget, error)
	GetSpentByCategory(ctx context.Context, userID, categoryID uuid.UUID, month, year int32) (string, error)
}

