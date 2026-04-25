package usecase

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/mali-app/mali_api/internal/domain"
)

type mockGoalRepository struct {
	lastCreated          *domain.Goal
	goalsByID            map[uuid.UUID]*domain.Goal
	lastUpdatedGoal      *domain.Goal
	lastUpdatedSavedGoal uuid.UUID
	lastUpdatedSaved     string
	lastContribution     *domain.GoalContribution
}

func (m *mockGoalRepository) Create(_ context.Context, goal *domain.Goal) (*domain.Goal, error) {
	copied := *goal
	if copied.ID == uuid.Nil {
		copied.ID = uuid.New()
	}
	if copied.CreatedAt.IsZero() {
		copied.CreatedAt = time.Now().UTC()
	}
	m.lastCreated = &copied
	if m.goalsByID == nil {
		m.goalsByID = make(map[uuid.UUID]*domain.Goal)
	}
	m.goalsByID[copied.ID] = &copied
	return &copied, nil
}

func (m *mockGoalRepository) ListByUser(_ context.Context, _ uuid.UUID) ([]*domain.Goal, error) {
	return nil, nil
}

func (m *mockGoalRepository) FindByID(_ context.Context, userID, goalID uuid.UUID) (*domain.Goal, error) {
	if m.goalsByID == nil {
		return nil, pgx.ErrNoRows
	}
	goal, ok := m.goalsByID[goalID]
	if !ok || goal.UserID != userID {
		return nil, pgx.ErrNoRows
	}
	copied := *goal
	return &copied, nil
}

func (m *mockGoalRepository) Update(_ context.Context, goal *domain.Goal) error {
	copied := *goal
	m.lastUpdatedGoal = &copied
	if m.goalsByID == nil {
		m.goalsByID = make(map[uuid.UUID]*domain.Goal)
	}
	m.goalsByID[copied.ID] = &copied
	return nil
}

func (m *mockGoalRepository) UpdateSavedAmount(_ context.Context, userID, goalID uuid.UUID, savedAmount string) error {
	goal, ok := m.goalsByID[goalID]
	if !ok || goal.UserID != userID {
		return pgx.ErrNoRows
	}
	goal.SavedAmount = savedAmount
	m.lastUpdatedSavedGoal = goalID
	m.lastUpdatedSaved = savedAmount
	return nil
}

func (m *mockGoalRepository) Delete(_ context.Context, _ uuid.UUID, _ uuid.UUID) error {
	return nil
}

func (m *mockGoalRepository) CreateContribution(_ context.Context, contribution *domain.GoalContribution) (*domain.GoalContribution, error) {
	copied := *contribution
	if copied.ID == uuid.Nil {
		copied.ID = uuid.New()
	}
	m.lastContribution = &copied
	return &copied, nil
}

func (m *mockGoalRepository) ListContributionsByGoal(_ context.Context, _ uuid.UUID, _ uuid.UUID) ([]*domain.GoalContribution, error) {
	return nil, nil
}

func TestGoalService_CreateGoal_ValidatesTargetGreaterThanZero(t *testing.T) {
	t.Parallel()

	repo := &mockGoalRepository{}
	service, err := NewGoalService(repo)
	if err != nil {
		t.Fatalf("create goal service: %v", err)
	}
	service.now = func() time.Time {
		return time.Date(2026, time.April, 1, 0, 0, 0, 0, time.UTC)
	}

	_, err = service.CreateGoal(context.Background(), CreateGoalInput{
		UserID:       uuid.New(),
		Name:         "Emergency Fund",
		TargetAmount: "0",
		SavedAmount:  "0",
		Currency:     "usd",
		Deadline:     time.Date(2026, time.July, 15, 0, 0, 0, 0, time.UTC),
	})
	if err == nil {
		t.Fatal("expected validation error for zero target amount")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestGoalService_CreateGoal_ValidatesDeadlineIsFutureDate(t *testing.T) {
	t.Parallel()

	repo := &mockGoalRepository{}
	service, err := NewGoalService(repo)
	if err != nil {
		t.Fatalf("create goal service: %v", err)
	}
	service.now = func() time.Time {
		return time.Date(2026, time.April, 10, 0, 0, 0, 0, time.UTC)
	}

	_, err = service.CreateGoal(context.Background(), CreateGoalInput{
		UserID:       uuid.New(),
		Name:         "School Fees",
		TargetAmount: "500",
		SavedAmount:  "100",
		Currency:     "USD",
		Deadline:     time.Date(2026, time.April, 10, 12, 0, 0, 0, time.UTC),
	})
	if err == nil {
		t.Fatal("expected validation error for non-future deadline")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestGoalService_CreateGoal_CalculatesAndStoresRequiredMonthly(t *testing.T) {
	t.Parallel()

	repo := &mockGoalRepository{}
	service, err := NewGoalService(repo)
	if err != nil {
		t.Fatalf("create goal service: %v", err)
	}
	service.now = func() time.Time {
		return time.Date(2026, time.April, 10, 8, 0, 0, 0, time.UTC)
	}

	created, err := service.CreateGoal(context.Background(), CreateGoalInput{
		UserID:       uuid.New(),
		Name:         "Emergency Fund",
		TargetAmount: "1000",
		SavedAmount:  "100",
		Currency:     "usd",
		Deadline:     time.Date(2026, time.June, 30, 18, 0, 0, 0, time.UTC),
		Priority:     2,
	})
	if err != nil {
		t.Fatalf("create goal: %v", err)
	}

	if created.RequiredMonthly != "300.0000" {
		t.Fatalf("expected required_monthly=300.0000, got=%s", created.RequiredMonthly)
	}
	if repo.lastCreated == nil {
		t.Fatal("expected repository create to be called")
	}
	if repo.lastCreated.RequiredMonthly != "300.0000" {
		t.Fatalf("expected repository required_monthly=300.0000, got=%s", repo.lastCreated.RequiredMonthly)
	}
	if created.Currency != "USD" {
		t.Fatalf("expected normalized currency USD, got=%s", created.Currency)
	}
}

type milestoneSpy struct {
	events []GoalMilestoneReachedEvent
}

func (s *milestoneSpy) EmitGoalMilestoneReached(_ context.Context, event GoalMilestoneReachedEvent) error {
	s.events = append(s.events, event)
	return nil
}

func TestGoalService_Contribute_UpdatesSavedAmountAndReturnsGoal(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	goalID := uuid.New()
	repo := &mockGoalRepository{
		goalsByID: map[uuid.UUID]*domain.Goal{
			goalID: {
				ID:           goalID,
				UserID:       userID,
				Name:         "Emergency Fund",
				TargetAmount: "1000",
				SavedAmount:  "100",
				Currency:     "USD",
				Deadline:     ptrTime(time.Date(2026, time.July, 1, 0, 0, 0, 0, time.UTC)),
			},
		},
	}
	service, err := NewGoalService(repo)
	if err != nil {
		t.Fatalf("create goal service: %v", err)
	}
	service.now = func() time.Time {
		return time.Date(2026, time.April, 1, 0, 0, 0, 0, time.UTC)
	}

	updated, err := service.Contribute(context.Background(), ContributeGoalInput{
		UserID:   userID,
		GoalID:   goalID,
		Amount:   "150",
		Currency: "usd",
		Notes:    "Monthly allocation",
	})
	if err != nil {
		t.Fatalf("contribute to goal: %v", err)
	}

	if updated.SavedAmount != "250.0000" {
		t.Fatalf("expected saved_amount=250.0000, got=%s", updated.SavedAmount)
	}
	if repo.lastUpdatedSavedGoal != goalID {
		t.Fatalf("expected saved_amount update for goal %s, got %s", goalID, repo.lastUpdatedSavedGoal)
	}
	if repo.lastUpdatedSaved != "250.0000" {
		t.Fatalf("expected updated saved amount 250.0000, got=%s", repo.lastUpdatedSaved)
	}
	if repo.lastContribution == nil {
		t.Fatal("expected contribution to be stored")
	}
	if repo.lastContribution.Amount != "150" {
		t.Fatalf("expected contribution amount 150, got=%s", repo.lastContribution.Amount)
	}
	if repo.lastContribution.Currency != "USD" {
		t.Fatalf("expected normalized contribution currency USD, got=%s", repo.lastContribution.Currency)
	}
	if repo.lastUpdatedGoal == nil {
		t.Fatal("expected goal update for required_monthly recalculation")
	}
	if repo.lastUpdatedGoal.RequiredMonthly != "250.0000" {
		t.Fatalf("expected required_monthly=250.0000 after contribution, got=%s", repo.lastUpdatedGoal.RequiredMonthly)
	}
}

func TestGoalService_Contribute_EmitsMilestoneWhenThresholdCrossed(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	goalID := uuid.New()
	repo := &mockGoalRepository{
		goalsByID: map[uuid.UUID]*domain.Goal{
			goalID: {
				ID:           goalID,
				UserID:       userID,
				Name:         "School Fees",
				TargetAmount: "1000",
				SavedAmount:  "200",
				Currency:     "USD",
			},
		},
	}
	emitter := &milestoneSpy{}
	service, err := NewGoalService(repo)
	if err != nil {
		t.Fatalf("create goal service: %v", err)
	}
	service.SetMilestoneEmitter(emitter)

	_, err = service.Contribute(context.Background(), ContributeGoalInput{
		UserID: userID,
		GoalID: goalID,
		Amount: "60",
	})
	if err != nil {
		t.Fatalf("contribute to goal: %v", err)
	}

	if len(emitter.events) != 1 {
		t.Fatalf("expected 1 milestone event, got=%d", len(emitter.events))
	}
	if emitter.events[0].Milestone != 25 {
		t.Fatalf("expected 25%% milestone event, got=%d", emitter.events[0].Milestone)
	}
}

func TestGoalService_Contribute_EmitsMultipleMilestonesWhenCrossingRanges(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	goalID := uuid.New()
	repo := &mockGoalRepository{
		goalsByID: map[uuid.UUID]*domain.Goal{
			goalID: {
				ID:           goalID,
				UserID:       userID,
				Name:         "Expansion",
				TargetAmount: "1000",
				SavedAmount:  "200",
				Currency:     "USD",
			},
		},
	}
	emitter := &milestoneSpy{}
	service, err := NewGoalService(repo)
	if err != nil {
		t.Fatalf("create goal service: %v", err)
	}
	service.SetMilestoneEmitter(emitter)

	_, err = service.Contribute(context.Background(), ContributeGoalInput{
		UserID: userID,
		GoalID: goalID,
		Amount: "350",
	})
	if err != nil {
		t.Fatalf("contribute to goal: %v", err)
	}

	if len(emitter.events) != 2 {
		t.Fatalf("expected 2 milestone events (25,50), got=%d", len(emitter.events))
	}
	if emitter.events[0].Milestone != 25 || emitter.events[1].Milestone != 50 {
		t.Fatalf("expected milestones [25 50], got [%d %d]", emitter.events[0].Milestone, emitter.events[1].Milestone)
	}
}

func TestGoalService_UpdateGoal_RecalculatesRequiredMonthlyWhenDeadlineChanges(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	goalID := uuid.New()
	repo := &mockGoalRepository{
		goalsByID: map[uuid.UUID]*domain.Goal{
			goalID: {
				ID:              goalID,
				UserID:          userID,
				Name:            "School Fees",
				TargetAmount:    "1200",
				SavedAmount:     "300",
				RequiredMonthly: "300.0000",
				Currency:        "USD",
				Deadline:        ptrTime(time.Date(2026, time.July, 1, 0, 0, 0, 0, time.UTC)),
			},
		},
	}
	service, err := NewGoalService(repo)
	if err != nil {
		t.Fatalf("create goal service: %v", err)
	}
	service.now = func() time.Time {
		return time.Date(2026, time.April, 1, 0, 0, 0, 0, time.UTC)
	}

	err = service.UpdateGoal(context.Background(), UpdateGoalInput{
		UserID:       userID,
		GoalID:       goalID,
		Name:         "School Fees",
		TargetAmount: "1200",
		Currency:     "USD",
		Deadline:     time.Date(2026, time.September, 1, 0, 0, 0, 0, time.UTC),
		Priority:     1,
	})
	if err != nil {
		t.Fatalf("update goal: %v", err)
	}

	if repo.lastUpdatedGoal == nil {
		t.Fatal("expected goal update call")
	}
	if repo.lastUpdatedGoal.RequiredMonthly != "180.0000" {
		t.Fatalf("expected required_monthly=180.0000 after deadline change, got=%s", repo.lastUpdatedGoal.RequiredMonthly)
	}
}

func TestGoalService_Contribute_RejectsNegativeAmount(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	goalID := uuid.New()
	repo := &mockGoalRepository{
		goalsByID: map[uuid.UUID]*domain.Goal{
			goalID: {
				ID:           goalID,
				UserID:       userID,
				Name:         "Emergency Fund",
				TargetAmount: "1000",
				SavedAmount:  "100",
				Currency:     "USD",
			},
		},
	}
	service, err := NewGoalService(repo)
	if err != nil {
		t.Fatalf("create goal service: %v", err)
	}

	_, err = service.Contribute(context.Background(), ContributeGoalInput{
		UserID: userID,
		GoalID: goalID,
		Amount: "-1",
	})
	if err == nil {
		t.Fatal("expected validation error for negative contribution")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func ptrTime(value time.Time) *time.Time {
	v := value
	return &v
}
