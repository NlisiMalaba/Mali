package postgres

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/repository/sqlc"
)

type AnalyticsRepository struct {
	queries *sqlc.Queries
}

func NewAnalyticsRepository(queries *sqlc.Queries) *AnalyticsRepository {
	return &AnalyticsRepository{queries: queries}
}

var _ domain.IAnalyticsRepository = (*AnalyticsRepository)(nil)

func (r *AnalyticsRepository) GetMonthlyTotals(
	ctx context.Context,
	userID uuid.UUID,
	month, year int32,
) ([]*domain.MonthlyTotal, error) {
	dbUserID, err := pgUUIDFromUUID(userID)
	if err != nil {
		return nil, fmt.Errorf("parse user id: %w", err)
	}

	rows, err := r.queries.GetMonthlyTotals(ctx, sqlc.GetMonthlyTotalsParams{
		UserID: dbUserID,
		Month:  month,
		Year:   year,
	})
	if err != nil {
		return nil, fmt.Errorf("get monthly totals: %w", err)
	}

	out := make([]*domain.MonthlyTotal, 0, len(rows))
	for _, row := range rows {
		income, parseErr := stringFromNumeric(row.IncomeTotal)
		if parseErr != nil {
			return nil, fmt.Errorf("parse income_total: %w", parseErr)
		}
		expense, parseErr := stringFromNumeric(row.ExpenseTotal)
		if parseErr != nil {
			return nil, fmt.Errorf("parse expense_total: %w", parseErr)
		}
		net, parseErr := stringFromNumeric(row.NetTotal)
		if parseErr != nil {
			return nil, fmt.Errorf("parse net_total: %w", parseErr)
		}

		out = append(out, &domain.MonthlyTotal{
			Currency:     row.Currency,
			IncomeTotal:  income,
			ExpenseTotal: expense,
			NetTotal:     net,
		})
	}
	return out, nil
}

func (r *AnalyticsRepository) GetCategoryBreakdown(
	ctx context.Context,
	userID uuid.UUID,
	month, year int32,
) ([]*domain.CategoryBreakdown, error) {
	dbUserID, err := pgUUIDFromUUID(userID)
	if err != nil {
		return nil, fmt.Errorf("parse user id: %w", err)
	}

	rows, err := r.queries.GetCategoryBreakdown(ctx, sqlc.GetCategoryBreakdownParams{
		UserID: dbUserID,
		Month:  month,
		Year:   year,
	})
	if err != nil {
		return nil, fmt.Errorf("get category breakdown: %w", err)
	}

	out := make([]*domain.CategoryBreakdown, 0, len(rows))
	for _, row := range rows {
		total, parseErr := stringFromNumeric(row.TotalAmount)
		if parseErr != nil {
			return nil, fmt.Errorf("parse total_amount: %w", parseErr)
		}
		categoryID, parseErr := ptrFromUUID(row.CategoryID)
		if parseErr != nil {
			return nil, fmt.Errorf("parse category_id: %w", parseErr)
		}

		out = append(out, &domain.CategoryBreakdown{
			CategoryID:       categoryID,
			CategoryName:     ptrFromText(row.CategoryName),
			CategoryIcon:     ptrFromText(row.CategoryIcon),
			CategoryColorHex: ptrFromText(row.CategoryColorHex),
			Currency:         row.Currency,
			TotalAmount:      total,
		})
	}
	return out, nil
}

func (r *AnalyticsRepository) GetMonthlyTrend(
	ctx context.Context,
	userID uuid.UUID,
	month, year, months int32,
) ([]*domain.MonthlyTrendPoint, error) {
	dbUserID, err := pgUUIDFromUUID(userID)
	if err != nil {
		return nil, fmt.Errorf("parse user id: %w", err)
	}

	rows, err := r.queries.GetMonthlyTrend(ctx, sqlc.GetMonthlyTrendParams{
		UserID: dbUserID,
		Year:   year,
		Month:  month,
		Months: months,
	})
	if err != nil {
		return nil, fmt.Errorf("get monthly trend: %w", err)
	}

	out := make([]*domain.MonthlyTrendPoint, 0, len(rows))
	for _, row := range rows {
		income, parseErr := stringFromNumeric(row.IncomeTotal)
		if parseErr != nil {
			return nil, fmt.Errorf("parse income_total: %w", parseErr)
		}
		expense, parseErr := stringFromNumeric(row.ExpenseTotal)
		if parseErr != nil {
			return nil, fmt.Errorf("parse expense_total: %w", parseErr)
		}
		net, parseErr := stringFromNumeric(row.NetTotal)
		if parseErr != nil {
			return nil, fmt.Errorf("parse net_total: %w", parseErr)
		}

		out = append(out, &domain.MonthlyTrendPoint{
			Year:         row.Year,
			Month:        row.Month,
			Currency:     row.Currency,
			IncomeTotal:  income,
			ExpenseTotal: expense,
			NetTotal:     net,
		})
	}
	return out, nil
}

