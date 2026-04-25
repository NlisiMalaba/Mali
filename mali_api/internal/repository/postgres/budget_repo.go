package postgres

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/repository/sqlc"
)

type BudgetRepository struct {
	queries *sqlc.Queries
}

func NewBudgetRepository(queries *sqlc.Queries) *BudgetRepository {
	return &BudgetRepository{queries: queries}
}

var _ domain.IBudgetRepository = (*BudgetRepository)(nil)

func (r *BudgetRepository) Upsert(ctx context.Context, budget *domain.Budget) (*domain.Budget, error) {
	dbUserID, err := pgUUIDFromUUID(budget.UserID)
	if err != nil {
		return nil, fmt.Errorf("parse budget user id: %w", err)
	}
	dbCategoryID, err := pgUUIDFromUUID(budget.CategoryID)
	if err != nil {
		return nil, fmt.Errorf("parse budget category id: %w", err)
	}
	dbAmount, err := numericFromString(budget.Amount)
	if err != nil {
		return nil, fmt.Errorf("parse budget amount: %w", err)
	}

	row, err := r.queries.UpsertBudget(ctx, sqlc.UpsertBudgetParams{
		UserID:     dbUserID,
		CategoryID: dbCategoryID,
		Currency:   budget.Currency,
		Amount:     dbAmount,
		Month:      budget.Month,
		Year:       budget.Year,
		Rollover:   pgtype.Bool{Bool: budget.Rollover, Valid: true},
	})
	if err != nil {
		return nil, fmt.Errorf("upsert budget: %w", err)
	}

	mapped, err := mapSQLCBudgetToDomain(row)
	if err != nil {
		return nil, fmt.Errorf("map upsert budget: %w", err)
	}
	return mapped, nil
}

func (r *BudgetRepository) ListByUserMonth(
	ctx context.Context,
	userID uuid.UUID,
	month, year int32,
) ([]*domain.Budget, error) {
	dbUserID, err := pgUUIDFromUUID(userID)
	if err != nil {
		return nil, fmt.Errorf("parse user id: %w", err)
	}

	rows, err := r.queries.GetBudgetsByUserMonth(ctx, sqlc.GetBudgetsByUserMonthParams{
		UserID: dbUserID,
		Month:  month,
		Year:   year,
	})
	if err != nil {
		return nil, fmt.Errorf("list budgets by user month: %w", err)
	}

	out := make([]*domain.Budget, 0, len(rows))
	for _, row := range rows {
		mapped, mapErr := mapSQLCBudgetToDomain(row)
		if mapErr != nil {
			return nil, fmt.Errorf("map budget: %w", mapErr)
		}
		out = append(out, mapped)
	}
	return out, nil
}

func (r *BudgetRepository) GetSpentByCategory(
	ctx context.Context,
	userID, categoryID uuid.UUID,
	month, year int32,
) (string, error) {
	dbUserID, err := pgUUIDFromUUID(userID)
	if err != nil {
		return "", fmt.Errorf("parse user id: %w", err)
	}
	dbCategoryID, err := pgUUIDFromUUID(categoryID)
	if err != nil {
		return "", fmt.Errorf("parse category id: %w", err)
	}

	spent, err := r.queries.GetBudgetSpent(ctx, sqlc.GetBudgetSpentParams{
		UserID:     dbUserID,
		CategoryID: dbCategoryID,
		Year:       year,
		Month:      month,
	})
	if err != nil {
		return "", fmt.Errorf("get budget spent: %w", err)
	}

	value, err := stringFromNumeric(spent)
	if err != nil {
		return "", fmt.Errorf("parse spent amount: %w", err)
	}
	return value, nil
}

func mapSQLCBudgetToDomain(budget sqlc.Budget) (*domain.Budget, error) {
	id, err := uuidFromPG(budget.ID)
	if err != nil {
		return nil, fmt.Errorf("parse id: %w", err)
	}
	userID, err := uuidFromPG(budget.UserID)
	if err != nil {
		return nil, fmt.Errorf("parse user_id: %w", err)
	}
	categoryID, err := uuidFromPG(budget.CategoryID)
	if err != nil {
		return nil, fmt.Errorf("parse category_id: %w", err)
	}
	amount, err := stringFromNumeric(budget.Amount)
	if err != nil {
		return nil, fmt.Errorf("parse amount: %w", err)
	}

	return &domain.Budget{
		ID:         id,
		UserID:     userID,
		CategoryID: categoryID,
		Currency:   budget.Currency,
		Amount:     amount,
		Month:      budget.Month,
		Year:       budget.Year,
		Rollover:   budget.Rollover.Valid && budget.Rollover.Bool,
	}, nil
}

