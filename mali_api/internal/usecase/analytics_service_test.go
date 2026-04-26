package usecase

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
)

type mockAnalyticsRepository struct {
	monthlyTotals     []*domain.MonthlyTotal
	categoryBreakdown []*domain.CategoryBreakdown
	monthlyTrend      []*domain.MonthlyTrendPoint
}

func (m *mockAnalyticsRepository) GetMonthlyTotals(_ context.Context, _ uuid.UUID, _, _ int32) ([]*domain.MonthlyTotal, error) {
	return m.monthlyTotals, nil
}

func (m *mockAnalyticsRepository) GetCategoryBreakdown(_ context.Context, _ uuid.UUID, _, _ int32) ([]*domain.CategoryBreakdown, error) {
	return m.categoryBreakdown, nil
}

func (m *mockAnalyticsRepository) GetMonthlyTrend(_ context.Context, _ uuid.UUID, _, _, _ int32) ([]*domain.MonthlyTrendPoint, error) {
	return m.monthlyTrend, nil
}

func TestAnalyticsService_GetMonthlyReport_ValidatesInput(t *testing.T) {
	t.Parallel()

	service, err := NewAnalyticsService(&mockAnalyticsRepository{})
	if err != nil {
		t.Fatalf("create analytics service: %v", err)
	}

	_, err = service.GetMonthlyReport(context.Background(), GetMonthlyReportInput{
		UserID: uuid.Nil,
		Month:  4,
		Year:   2026,
	})
	if err == nil {
		t.Fatal("expected validation error for missing user_id")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestAnalyticsService_GetMonthlyReport_BuildsReportWithSurplusDeficit(t *testing.T) {
	t.Parallel()

	categoryName := "Food"
	repo := &mockAnalyticsRepository{
		monthlyTotals: []*domain.MonthlyTotal{
			{Currency: "USD", IncomeTotal: "1000.0000", ExpenseTotal: "700.0000", NetTotal: "300.0000"},
			{Currency: "ZAR", IncomeTotal: "200.0000", ExpenseTotal: "500.0000", NetTotal: "-300.0000"},
		},
		categoryBreakdown: []*domain.CategoryBreakdown{
			{CategoryName: &categoryName, Currency: "USD", TotalAmount: "250.0000"},
		},
		monthlyTrend: []*domain.MonthlyTrendPoint{
			{Year: 2026, Month: 3, Currency: "USD", IncomeTotal: "900.0000", ExpenseTotal: "650.0000", NetTotal: "250.0000"},
			{Year: 2026, Month: 4, Currency: "USD", IncomeTotal: "1000.0000", ExpenseTotal: "700.0000", NetTotal: "300.0000"},
		},
	}
	service, err := NewAnalyticsService(repo)
	if err != nil {
		t.Fatalf("create analytics service: %v", err)
	}

	report, err := service.GetMonthlyReport(context.Background(), GetMonthlyReportInput{
		UserID: uuid.New(),
		Month:  4,
		Year:   2026,
	})
	if err != nil {
		t.Fatalf("get monthly report: %v", err)
	}

	if len(report.Totals) != 2 {
		t.Fatalf("expected 2 totals, got %d", len(report.Totals))
	}
	if len(report.TopCategories) != 1 {
		t.Fatalf("expected 1 top category, got %d", len(report.TopCategories))
	}
	if len(report.MonthlyTrend) != 2 {
		t.Fatalf("expected 2 trend points, got %d", len(report.MonthlyTrend))
	}
	if len(report.SurplusDeficitByCurrency) != 2 {
		t.Fatalf("expected 2 surplus/deficit entries, got %d", len(report.SurplusDeficitByCurrency))
	}

	if report.SurplusDeficitByCurrency[0].Currency != "USD" || report.SurplusDeficitByCurrency[0].Status != "surplus" {
		t.Fatalf("expected USD surplus, got %+v", report.SurplusDeficitByCurrency[0])
	}
	if report.SurplusDeficitByCurrency[1].Currency != "ZAR" || report.SurplusDeficitByCurrency[1].Status != "deficit" {
		t.Fatalf("expected ZAR deficit, got %+v", report.SurplusDeficitByCurrency[1])
	}
}

func TestAnalyticsService_GetMonthlyReport_MultiCurrencyNetWorthStyleTotals(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	repo := &mockAnalyticsRepository{
		monthlyTotals: []*domain.MonthlyTotal{
			{Currency: "USD", IncomeTotal: "1200.0000", ExpenseTotal: "200.0000", NetTotal: "1000.0000"},
			{Currency: "ZAR", IncomeTotal: "500.0000", ExpenseTotal: "550.0000", NetTotal: "-50.0000"},
			{Currency: "BWP", IncomeTotal: "100.0000", ExpenseTotal: "100.0000", NetTotal: "0.0000"},
		},
	}
	service, err := NewAnalyticsService(repo)
	if err != nil {
		t.Fatalf("create analytics service: %v", err)
	}

	report, err := service.GetMonthlyReport(context.Background(), GetMonthlyReportInput{
		UserID: userID,
		Month:  4,
		Year:   2026,
	})
	if err != nil {
		t.Fatalf("get monthly report: %v", err)
	}

	if len(report.Totals) != 3 {
		t.Fatalf("expected 3 currency totals, got %d", len(report.Totals))
	}

	assertSurplusDeficit(t, report.SurplusDeficitByCurrency, "USD", "surplus", "1000.0000")
	assertSurplusDeficit(t, report.SurplusDeficitByCurrency, "ZAR", "deficit", "50.0000")
	assertSurplusDeficit(t, report.SurplusDeficitByCurrency, "BWP", "balanced", "0.0000")
}

func TestAnalyticsService_GetCategoryBreakdown_RanksByAmountDescending(t *testing.T) {
	t.Parallel()

	catA := "Transport"
	catB := "Food"
	catC := "Utilities"
	repo := &mockAnalyticsRepository{
		categoryBreakdown: []*domain.CategoryBreakdown{
			{CategoryName: &catA, Currency: "USD", TotalAmount: "120.0000"},
			{CategoryName: &catB, Currency: "USD", TotalAmount: "400.0000"},
			{CategoryName: &catC, Currency: "USD", TotalAmount: "250.0000"},
		},
	}
	service, err := NewAnalyticsService(repo)
	if err != nil {
		t.Fatalf("create analytics service: %v", err)
	}

	top, err := service.GetCategoryBreakdown(context.Background(), GetCategoryBreakdownInput{
		UserID: uuid.New(),
		Month:  4,
		Year:   2026,
		Limit:  2,
	})
	if err != nil {
		t.Fatalf("get category breakdown: %v", err)
	}

	if len(top) != 2 {
		t.Fatalf("expected 2 categories due to limit, got %d", len(top))
	}
	if top[0].CategoryName == nil || *top[0].CategoryName != "Food" {
		t.Fatalf("expected top category Food, got %+v", top[0].CategoryName)
	}
	if top[1].CategoryName == nil || *top[1].CategoryName != "Utilities" {
		t.Fatalf("expected second category Utilities, got %+v", top[1].CategoryName)
	}
}

func assertSurplusDeficit(t *testing.T, items []SurplusDeficitSummary, currency, status, amount string) {
	t.Helper()
	for _, item := range items {
		if item.Currency == currency {
			if item.Status != status || item.Amount != amount {
				t.Fatalf("unexpected %s summary: %+v", currency, item)
			}
			return
		}
	}
	t.Fatalf("currency %s not found in surplus/deficit summaries", currency)
}

