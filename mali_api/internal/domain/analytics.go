package domain

import (
	"context"

	"github.com/google/uuid"
)

type MonthlyTotal struct {
	Currency     string
	IncomeTotal  string
	ExpenseTotal string
	NetTotal     string
}

type CategoryBreakdown struct {
	CategoryID       *uuid.UUID
	CategoryName     *string
	CategoryIcon     *string
	CategoryColorHex *string
	Currency         string
	TotalAmount      string
}

type MonthlyTrendPoint struct {
	Year         int32
	Month        int32
	Currency     string
	IncomeTotal  string
	ExpenseTotal string
	NetTotal     string
}

type IAnalyticsRepository interface {
	GetMonthlyTotals(ctx context.Context, userID uuid.UUID, month, year int32) ([]*MonthlyTotal, error)
	GetCategoryBreakdown(ctx context.Context, userID uuid.UUID, month, year int32) ([]*CategoryBreakdown, error)
	GetMonthlyTrend(ctx context.Context, userID uuid.UUID, month, year, months int32) ([]*MonthlyTrendPoint, error)
}

