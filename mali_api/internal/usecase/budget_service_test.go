package usecase

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
)

type mockBudgetRepository struct {
	budgetsByMonth  []*domain.Budget
	spentByCategory map[uuid.UUID]string
}

func (m *mockBudgetRepository) Upsert(_ context.Context, budget *domain.Budget) (*domain.Budget, error) {
	copied := *budget
	if copied.ID == uuid.Nil {
		copied.ID = uuid.New()
	}
	return &copied, nil
}

func (m *mockBudgetRepository) ListByUserMonth(_ context.Context, _ uuid.UUID, _, _ int32) ([]*domain.Budget, error) {
	out := make([]*domain.Budget, 0, len(m.budgetsByMonth))
	for _, budget := range m.budgetsByMonth {
		copied := *budget
		out = append(out, &copied)
	}
	return out, nil
}

func (m *mockBudgetRepository) GetSpentByCategory(_ context.Context, _ uuid.UUID, categoryID uuid.UUID, _, _ int32) (string, error) {
	if m.spentByCategory == nil {
		return "0", nil
	}
	if value, ok := m.spentByCategory[categoryID]; ok {
		return value, nil
	}
	return "0", nil
}

type budgetExceededSpy struct {
	events []BudgetExceededEvent
}

func (s *budgetExceededSpy) EmitBudgetExceeded(_ context.Context, event BudgetExceededEvent) error {
	s.events = append(s.events, event)
	return nil
}

func TestBudgetService_GetBudgetStatus_ValidatesInput(t *testing.T) {
	t.Parallel()

	repo := &mockBudgetRepository{}
	service, err := NewBudgetService(repo)
	if err != nil {
		t.Fatalf("create budget service: %v", err)
	}

	_, err = service.GetBudgetStatus(context.Background(), GetBudgetStatusInput{
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

	_, err = service.GetBudgetStatus(context.Background(), GetBudgetStatusInput{
		UserID: uuid.New(),
		Month:  13,
		Year:   2026,
	})
	if err == nil {
		t.Fatal("expected validation error for invalid month")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestBudgetService_GetBudgetStatus_ReturnsComputedValues(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	categoryID := uuid.New()
	budgetID := uuid.New()

	repo := &mockBudgetRepository{
		budgetsByMonth: []*domain.Budget{
			{
				ID:         budgetID,
				UserID:     userID,
				CategoryID: categoryID,
				Currency:   "USD",
				Amount:     "1000",
				Month:      4,
				Year:       2026,
			},
		},
		spentByCategory: map[uuid.UUID]string{
			categoryID: "125.5",
		},
	}
	service, err := NewBudgetService(repo)
	if err != nil {
		t.Fatalf("create budget service: %v", err)
	}

	statuses, err := service.GetBudgetStatus(context.Background(), GetBudgetStatusInput{
		UserID: userID,
		Month:  4,
		Year:   2026,
	})
	if err != nil {
		t.Fatalf("get budget status: %v", err)
	}

	if len(statuses) != 1 {
		t.Fatalf("expected 1 status, got %d", len(statuses))
	}
	status := statuses[0]
	if status.Spent != "125.5000" {
		t.Fatalf("expected spent=125.5000, got=%s", status.Spent)
	}
	if status.Remaining != "874.5000" {
		t.Fatalf("expected remaining=874.5000, got=%s", status.Remaining)
	}
	if status.PercentUsed != "12.5500" {
		t.Fatalf("expected percent_used=12.5500, got=%s", status.PercentUsed)
	}
}

func TestBudgetService_GetBudgetStatus_EmitsThresholdsOnCrossing(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	categoryID := uuid.New()
	budgetID := uuid.New()

	repo := &mockBudgetRepository{
		budgetsByMonth: []*domain.Budget{
			{
				ID:         budgetID,
				UserID:     userID,
				CategoryID: categoryID,
				Currency:   "USD",
				Amount:     "1000",
				Month:      4,
				Year:       2026,
			},
		},
		spentByCategory: map[uuid.UUID]string{
			categoryID: "700",
		},
	}
	service, err := NewBudgetService(repo)
	if err != nil {
		t.Fatalf("create budget service: %v", err)
	}
	service.now = func() time.Time {
		return time.Date(2026, time.April, 25, 20, 0, 0, 0, time.UTC)
	}
	spy := &budgetExceededSpy{}
	service.SetBudgetExceededEmitter(spy)

	_, err = service.GetBudgetStatus(context.Background(), GetBudgetStatusInput{
		UserID: userID,
		Month:  4,
		Year:   2026,
	})
	if err != nil {
		t.Fatalf("get budget status (70%%): %v", err)
	}
	if len(spy.events) != 0 {
		t.Fatalf("expected 0 events at 70%%, got %d", len(spy.events))
	}

	repo.spentByCategory[categoryID] = "810"
	_, err = service.GetBudgetStatus(context.Background(), GetBudgetStatusInput{
		UserID: userID,
		Month:  4,
		Year:   2026,
	})
	if err != nil {
		t.Fatalf("get budget status (81%%): %v", err)
	}
	if len(spy.events) != 1 {
		t.Fatalf("expected 1 event at 81%% crossing, got %d", len(spy.events))
	}
	if spy.events[0].Threshold != 80 {
		t.Fatalf("expected 80%% threshold event, got %d", spy.events[0].Threshold)
	}

	repo.spentByCategory[categoryID] = "1100"
	_, err = service.GetBudgetStatus(context.Background(), GetBudgetStatusInput{
		UserID: userID,
		Month:  4,
		Year:   2026,
	})
	if err != nil {
		t.Fatalf("get budget status (110%%): %v", err)
	}
	if len(spy.events) != 2 {
		t.Fatalf("expected 2 total events after 100%% crossing, got %d", len(spy.events))
	}
	if spy.events[1].Threshold != 100 {
		t.Fatalf("expected 100%% threshold event, got %d", spy.events[1].Threshold)
	}
}

