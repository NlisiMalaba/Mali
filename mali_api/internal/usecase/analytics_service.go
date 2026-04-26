package usecase

import (
	"context"
	"fmt"
	"math/big"
	"sort"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
)

const defaultTrendMonths int32 = 6
const defaultTopCategoriesLimit = 5

type GetMonthlyReportInput struct {
	UserID      uuid.UUID
	Month       int32
	Year        int32
	TrendMonths int32
}

type GetMonthlyTrendInput struct {
	UserID uuid.UUID
	Month  int32
	Year   int32
	Months int32
}

type GetCategoryBreakdownInput struct {
	UserID uuid.UUID
	Month  int32
	Year   int32
	Limit  int
}

type CurrencySummary struct {
	Currency    string
	IncomeTotal string
	ExpenseTotal string
	NetTotal    string
}

type CategorySummary struct {
	CategoryID       *uuid.UUID
	CategoryName     *string
	CategoryIcon     *string
	CategoryColorHex *string
	Currency         string
	TotalAmount      string
}

type MonthlyTrendSummary struct {
	Year         int32
	Month        int32
	Currency     string
	IncomeTotal  string
	ExpenseTotal string
	NetTotal     string
}

type SurplusDeficitSummary struct {
	Currency string
	NetTotal string
	Status   string
	Amount   string
}

type MonthlyReport struct {
	Month                    int32
	Year                     int32
	Totals                   []CurrencySummary
	TopCategories            []CategorySummary
	MonthlyTrend             []MonthlyTrendSummary
	SurplusDeficitByCurrency []SurplusDeficitSummary
}

type AnalyticsService struct {
	analyticsRepository domain.IAnalyticsRepository
	topCategoriesLimit  int
}

func NewAnalyticsService(analyticsRepository domain.IAnalyticsRepository) (*AnalyticsService, error) {
	if analyticsRepository == nil {
		return nil, fmt.Errorf("%w: analytics repository is required", ErrValidation)
	}

	return &AnalyticsService{
		analyticsRepository: analyticsRepository,
		topCategoriesLimit:  defaultTopCategoriesLimit,
	}, nil
}

func (s *AnalyticsService) GetMonthlyReport(ctx context.Context, input GetMonthlyReportInput) (*MonthlyReport, error) {
	if err := s.validateMonthlyInput(input.UserID, input.Month, input.Year); err != nil {
		return nil, err
	}

	trendMonths := input.TrendMonths
	if trendMonths <= 0 {
		trendMonths = defaultTrendMonths
	}

	totals, err := s.analyticsRepository.GetMonthlyTotals(ctx, input.UserID, input.Month, input.Year)
	if err != nil {
		return nil, fmt.Errorf("get monthly totals: %w", err)
	}
	breakdown, err := s.analyticsRepository.GetCategoryBreakdown(ctx, input.UserID, input.Month, input.Year)
	if err != nil {
		return nil, fmt.Errorf("get category breakdown: %w", err)
	}
	trend, err := s.analyticsRepository.GetMonthlyTrend(ctx, input.UserID, input.Month, input.Year, trendMonths)
	if err != nil {
		return nil, fmt.Errorf("get monthly trend: %w", err)
	}

	report := &MonthlyReport{
		Month:                     input.Month,
		Year:                      input.Year,
		Totals:                    make([]CurrencySummary, 0, len(totals)),
		TopCategories:             mapTopCategories(breakdown, s.topCategoriesLimit),
		MonthlyTrend:              make([]MonthlyTrendSummary, 0, len(trend)),
		SurplusDeficitByCurrency:  make([]SurplusDeficitSummary, 0, len(totals)),
	}

	for _, total := range totals {
		report.Totals = append(report.Totals, CurrencySummary{
			Currency:     total.Currency,
			IncomeTotal:  total.IncomeTotal,
			ExpenseTotal: total.ExpenseTotal,
			NetTotal:     total.NetTotal,
		})

		sd, mapErr := mapSurplusDeficit(total.Currency, total.NetTotal)
		if mapErr != nil {
			return nil, mapErr
		}
		report.SurplusDeficitByCurrency = append(report.SurplusDeficitByCurrency, sd)
	}

	for _, point := range trend {
		report.MonthlyTrend = append(report.MonthlyTrend, MonthlyTrendSummary{
			Year:         point.Year,
			Month:        point.Month,
			Currency:     point.Currency,
			IncomeTotal:  point.IncomeTotal,
			ExpenseTotal: point.ExpenseTotal,
			NetTotal:     point.NetTotal,
		})
	}

	return report, nil
}

func (s *AnalyticsService) GetMonthlyTrend(ctx context.Context, input GetMonthlyTrendInput) ([]MonthlyTrendSummary, error) {
	if err := s.validateMonthlyInput(input.UserID, input.Month, input.Year); err != nil {
		return nil, err
	}
	months := input.Months
	if months <= 0 {
		months = defaultTrendMonths
	}

	points, err := s.analyticsRepository.GetMonthlyTrend(ctx, input.UserID, input.Month, input.Year, months)
	if err != nil {
		return nil, fmt.Errorf("get monthly trend: %w", err)
	}

	out := make([]MonthlyTrendSummary, 0, len(points))
	for _, point := range points {
		out = append(out, MonthlyTrendSummary{
			Year:         point.Year,
			Month:        point.Month,
			Currency:     point.Currency,
			IncomeTotal:  point.IncomeTotal,
			ExpenseTotal: point.ExpenseTotal,
			NetTotal:     point.NetTotal,
		})
	}
	return out, nil
}

func (s *AnalyticsService) GetCategoryBreakdown(ctx context.Context, input GetCategoryBreakdownInput) ([]CategorySummary, error) {
	if err := s.validateMonthlyInput(input.UserID, input.Month, input.Year); err != nil {
		return nil, err
	}
	rows, err := s.analyticsRepository.GetCategoryBreakdown(ctx, input.UserID, input.Month, input.Year)
	if err != nil {
		return nil, fmt.Errorf("get category breakdown: %w", err)
	}
	limit := input.Limit
	if limit <= 0 {
		limit = s.topCategoriesLimit
	}
	return mapTopCategories(rows, limit), nil
}

func (s *AnalyticsService) validateMonthlyInput(userID uuid.UUID, month, year int32) error {
	if s.analyticsRepository == nil {
		return fmt.Errorf("analytics service dependencies are not configured")
	}
	if userID == uuid.Nil {
		return fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if month < 1 || month > 12 {
		return fmt.Errorf("%w: month must be between 1 and 12", ErrValidation)
	}
	if year < 1 {
		return fmt.Errorf("%w: year is required", ErrValidation)
	}
	return nil
}

func mapTopCategories(items []*domain.CategoryBreakdown, limit int) []CategorySummary {
	if len(items) == 0 || limit <= 0 {
		return nil
	}

	copied := make([]*domain.CategoryBreakdown, 0, len(items))
	copied = append(copied, items...)
	sort.SliceStable(copied, func(i, j int) bool {
		left, leftErr := parseAmount(copied[i].TotalAmount)
		right, rightErr := parseAmount(copied[j].TotalAmount)
		if leftErr != nil || rightErr != nil {
			return copied[i].TotalAmount > copied[j].TotalAmount
		}
		return left.Cmp(right) > 0
	})

	if len(copied) > limit {
		copied = copied[:limit]
	}

	out := make([]CategorySummary, 0, len(copied))
	for _, item := range copied {
		out = append(out, CategorySummary{
			CategoryID:       item.CategoryID,
			CategoryName:     item.CategoryName,
			CategoryIcon:     item.CategoryIcon,
			CategoryColorHex: item.CategoryColorHex,
			Currency:         item.Currency,
			TotalAmount:      item.TotalAmount,
		})
	}
	return out
}

func mapSurplusDeficit(currency, netTotal string) (SurplusDeficitSummary, error) {
	value, err := parseAmount(normalizeAmount(netTotal))
	if err != nil {
		return SurplusDeficitSummary{}, fmt.Errorf("%w: invalid net total for currency %s", ErrValidation, currency)
	}

	status := "balanced"
	amount := "0.0000"

	switch value.Sign() {
	case 1:
		status = "surplus"
		amount = value.FloatString(4)
	case -1:
		status = "deficit"
		amount = new(big.Rat).Abs(value).FloatString(4)
	}

	return SurplusDeficitSummary{
		Currency: currency,
		NetTotal: value.FloatString(4),
		Status:   status,
		Amount:   amount,
	}, nil
}

