package usecase

import (
	"context"
	"fmt"
	"math/big"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
)

type CreateGoalInput struct {
	UserID       uuid.UUID
	Name         string
	Emoji        string
	GoalType     string
	TargetAmount string
	Currency     string
	SavedAmount  string
	Deadline     time.Time
	Priority     int32
}

type ContributeGoalInput struct {
	UserID        uuid.UUID
	GoalID        uuid.UUID
	Amount        string
	Currency      string
	Notes         string
	ContributedAt time.Time
}

type UpdateGoalInput struct {
	UserID       uuid.UUID
	GoalID       uuid.UUID
	Name         string
	Emoji        string
	GoalType     string
	TargetAmount string
	Currency     string
	Deadline     time.Time
	Priority     int32
	IsCompleted  bool
}

type GoalMilestoneReachedEvent struct {
	UserID       uuid.UUID
	GoalID       uuid.UUID
	Milestone    int
	SavedAmount  string
	TargetAmount string
	Progress     string
	OccurredAt   time.Time
}

type GoalMilestoneEmitter interface {
	EmitGoalMilestoneReached(ctx context.Context, event GoalMilestoneReachedEvent) error
}

type GoalService struct {
	goalRepository   domain.IGoalRepository
	milestoneEmitter GoalMilestoneEmitter
	now              func() time.Time
}

func NewGoalService(goalRepository domain.IGoalRepository) (*GoalService, error) {
	if goalRepository == nil {
		return nil, fmt.Errorf("%w: goal repository is required", ErrValidation)
	}

	return &GoalService{
		goalRepository: goalRepository,
		now:            time.Now,
	}, nil
}

func (s *GoalService) SetMilestoneEmitter(emitter GoalMilestoneEmitter) {
	s.milestoneEmitter = emitter
}

func (s *GoalService) CreateGoal(ctx context.Context, input CreateGoalInput) (*domain.Goal, error) {
	if s.goalRepository == nil {
		return nil, fmt.Errorf("goal service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	name := strings.TrimSpace(input.Name)
	if name == "" {
		return nil, fmt.Errorf("%w: goal name is required", ErrValidation)
	}

	targetAmount := normalizeAmount(input.TargetAmount)
	targetValue, err := parseAmount(targetAmount)
	if err != nil {
		return nil, fmt.Errorf("%w: invalid target amount", ErrValidation)
	}
	if targetValue.Sign() <= 0 {
		return nil, fmt.Errorf("%w: target amount must be greater than 0", ErrValidation)
	}

	savedAmount := normalizeAmount(input.SavedAmount)
	if savedAmount == "" {
		savedAmount = "0"
	}
	savedValue, err := parseAmount(savedAmount)
	if err != nil {
		return nil, fmt.Errorf("%w: invalid saved amount", ErrValidation)
	}

	currency := normalizeCurrencyCode(input.Currency)
	if currency == "" {
		return nil, fmt.Errorf("%w: currency is required", ErrValidation)
	}

	if input.Deadline.IsZero() {
		return nil, fmt.Errorf("%w: deadline is required", ErrValidation)
	}
	deadline := normalizeDate(input.Deadline)
	today := normalizeDate(s.now().UTC())
	if !deadline.After(today) {
		return nil, fmt.Errorf("%w: deadline must be a future date", ErrValidation)
	}

	requiredMonthly, isCompleted, err := computeRequiredMonthly(targetValue, savedValue, today, deadline)
	if err != nil {
		return nil, err
	}

	var emoji *string
	if trimmed := strings.TrimSpace(input.Emoji); trimmed != "" {
		emoji = &trimmed
	}
	var goalType *string
	if trimmed := strings.TrimSpace(input.GoalType); trimmed != "" {
		lower := strings.ToLower(trimmed)
		goalType = &lower
	}

	created, err := s.goalRepository.Create(ctx, &domain.Goal{
		UserID:          input.UserID,
		Name:            name,
		Emoji:           emoji,
		GoalType:        goalType,
		TargetAmount:    targetAmount,
		Currency:        currency,
		SavedAmount:     savedAmount,
		RequiredMonthly: requiredMonthly.FloatString(4),
		Deadline:        &deadline,
		Priority:        input.Priority,
		IsCompleted:     isCompleted,
	})
	if err != nil {
		return nil, fmt.Errorf("create goal: %w", err)
	}
	return created, nil
}

func (s *GoalService) ListGoals(ctx context.Context, userID uuid.UUID) ([]*domain.Goal, error) {
	if s.goalRepository == nil {
		return nil, fmt.Errorf("goal service dependencies are not configured")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	goals, err := s.goalRepository.ListByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list goals: %w", err)
	}
	return goals, nil
}

func (s *GoalService) GetGoalByID(ctx context.Context, userID, goalID uuid.UUID) (*domain.Goal, error) {
	if s.goalRepository == nil {
		return nil, fmt.Errorf("goal service dependencies are not configured")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if goalID == uuid.Nil {
		return nil, fmt.Errorf("%w: goal_id is required", ErrValidation)
	}

	goal, err := s.goalRepository.FindByID(ctx, userID, goalID)
	if err != nil {
		if isNotFound(err) {
			return nil, fmt.Errorf("%w: goal not found", ErrValidation)
		}
		return nil, fmt.Errorf("find goal by id: %w", err)
	}
	return goal, nil
}

func (s *GoalService) UpdateGoal(ctx context.Context, input UpdateGoalInput) error {
	if s.goalRepository == nil {
		return fmt.Errorf("goal service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if input.GoalID == uuid.Nil {
		return fmt.Errorf("%w: goal_id is required", ErrValidation)
	}

	existing, err := s.goalRepository.FindByID(ctx, input.UserID, input.GoalID)
	if err != nil {
		if isNotFound(err) {
			return fmt.Errorf("%w: goal not found", ErrValidation)
		}
		return fmt.Errorf("find goal by id: %w", err)
	}

	name := strings.TrimSpace(input.Name)
	if name == "" {
		return fmt.Errorf("%w: goal name is required", ErrValidation)
	}

	targetAmount := normalizeAmount(input.TargetAmount)
	targetValue, err := parseAmount(targetAmount)
	if err != nil {
		return fmt.Errorf("%w: invalid target amount", ErrValidation)
	}
	if targetValue.Sign() <= 0 {
		return fmt.Errorf("%w: target amount must be greater than 0", ErrValidation)
	}

	currency := normalizeCurrencyCode(input.Currency)
	if currency == "" {
		return fmt.Errorf("%w: currency is required", ErrValidation)
	}
	if input.Deadline.IsZero() {
		return fmt.Errorf("%w: deadline is required", ErrValidation)
	}

	deadline := normalizeDate(input.Deadline)
	today := normalizeDate(s.now().UTC())
	savedValue, err := parseAmount(existing.SavedAmount)
	if err != nil {
		return fmt.Errorf("%w: invalid goal saved amount", ErrValidation)
	}
	requiredMonthly, isCompleted, err := computeRequiredMonthly(targetValue, savedValue, today, deadline)
	if err != nil {
		return err
	}

	var emoji *string
	if trimmed := strings.TrimSpace(input.Emoji); trimmed != "" {
		emoji = &trimmed
	}
	var goalType *string
	if trimmed := strings.TrimSpace(input.GoalType); trimmed != "" {
		lower := strings.ToLower(trimmed)
		goalType = &lower
	}

	if err := s.goalRepository.Update(ctx, &domain.Goal{
		ID:              input.GoalID,
		UserID:          input.UserID,
		Name:            name,
		Emoji:           emoji,
		GoalType:        goalType,
		TargetAmount:    targetAmount,
		Currency:        currency,
		SavedAmount:     existing.SavedAmount,
		RequiredMonthly: requiredMonthly.FloatString(4),
		Deadline:        &deadline,
		Priority:        input.Priority,
		IsCompleted:     input.IsCompleted || isCompleted,
	}); err != nil {
		return fmt.Errorf("update goal: %w", err)
	}

	return nil
}

func (s *GoalService) DeleteGoal(ctx context.Context, userID, goalID uuid.UUID) error {
	if s.goalRepository == nil {
		return fmt.Errorf("goal service dependencies are not configured")
	}
	if userID == uuid.Nil {
		return fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if goalID == uuid.Nil {
		return fmt.Errorf("%w: goal_id is required", ErrValidation)
	}

	if err := s.goalRepository.Delete(ctx, userID, goalID); err != nil {
		if isNotFound(err) {
			return fmt.Errorf("%w: goal not found", ErrValidation)
		}
		return fmt.Errorf("delete goal: %w", err)
	}
	return nil
}

func (s *GoalService) Contribute(ctx context.Context, input ContributeGoalInput) (*domain.Goal, error) {
	if s.goalRepository == nil {
		return nil, fmt.Errorf("goal service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if input.GoalID == uuid.Nil {
		return nil, fmt.Errorf("%w: goal_id is required", ErrValidation)
	}

	amount := normalizeAmount(input.Amount)
	amountValue, err := parseAmount(amount)
	if err != nil {
		return nil, fmt.Errorf("%w: invalid contribution amount", ErrValidation)
	}
	if amountValue.Sign() <= 0 {
		return nil, fmt.Errorf("%w: contribution amount must be greater than 0", ErrValidation)
	}

	goal, err := s.goalRepository.FindByID(ctx, input.UserID, input.GoalID)
	if err != nil {
		if isNotFound(err) {
			return nil, fmt.Errorf("%w: goal not found", ErrValidation)
		}
		return nil, fmt.Errorf("find goal by id: %w", err)
	}

	currentSaved, err := parseAmount(goal.SavedAmount)
	if err != nil {
		return nil, fmt.Errorf("%w: invalid goal saved amount", ErrValidation)
	}
	targetAmount, err := parseAmount(goal.TargetAmount)
	if err != nil {
		return nil, fmt.Errorf("%w: invalid goal target amount", ErrValidation)
	}

	updatedSaved := currentSaved.Add(currentSaved, amountValue)
	updatedSavedStr := updatedSaved.FloatString(4)

	currency := normalizeCurrencyCode(input.Currency)
	if currency == "" {
		currency = goal.Currency
	}
	if currency == "" {
		return nil, fmt.Errorf("%w: contribution currency is required", ErrValidation)
	}

	contributedAt := input.ContributedAt
	if contributedAt.IsZero() {
		contributedAt = s.now().UTC()
	}

	var notes *string
	if trimmed := strings.TrimSpace(input.Notes); trimmed != "" {
		notes = &trimmed
	}

	if _, err := s.goalRepository.CreateContribution(ctx, &domain.GoalContribution{
		GoalID:        goal.ID,
		Amount:        amount,
		Currency:      currency,
		Notes:         notes,
		ContributedAt: contributedAt,
	}); err != nil {
		return nil, fmt.Errorf("create goal contribution: %w", err)
	}

	if err := s.goalRepository.UpdateSavedAmount(ctx, input.UserID, input.GoalID, updatedSavedStr); err != nil {
		return nil, fmt.Errorf("update goal saved amount: %w", err)
	}

	goal.SavedAmount = updatedSavedStr
	goal.IsCompleted = updatedSaved.Cmp(targetAmount) >= 0

	if goal.Deadline != nil {
		today := normalizeDate(s.now().UTC())
		deadline := normalizeDate(*goal.Deadline)
		if deadline.After(today) {
			requiredMonthly, _, computeErr := computeRequiredMonthly(targetAmount, updatedSaved, today, deadline)
			if computeErr != nil {
				return nil, computeErr
			}
			goal.RequiredMonthly = requiredMonthly.FloatString(4)
			if err := s.goalRepository.Update(ctx, goal); err != nil {
				return nil, fmt.Errorf("update goal required monthly: %w", err)
			}
		}
	}

	if err := s.emitMilestones(ctx, goal, currentSaved, updatedSaved, targetAmount, contributedAt); err != nil {
		return nil, err
	}

	return goal, nil
}

func normalizeDate(value time.Time) time.Time {
	utc := value.UTC()
	return time.Date(utc.Year(), utc.Month(), utc.Day(), 0, 0, 0, 0, time.UTC)
}

func monthsUntil(fromDate, toDate time.Time) int64 {
	months := int64((toDate.Year()-fromDate.Year())*12 + int(toDate.Month()-fromDate.Month()))
	if toDate.Day() > fromDate.Day() {
		months++
	}
	if months < 1 {
		return 1
	}
	return months
}

func parseIntToRat(value int64) *big.Rat {
	return new(big.Rat).SetInt64(value)
}

func computeRequiredMonthly(
	targetAmount *big.Rat,
	savedAmount *big.Rat,
	today time.Time,
	deadline time.Time,
) (*big.Rat, bool, error) {
	if !deadline.After(today) {
		return nil, false, fmt.Errorf("%w: deadline must be a future date", ErrValidation)
	}

	monthsRemaining := monthsUntil(today, deadline)
	if monthsRemaining <= 0 {
		return nil, false, fmt.Errorf("%w: deadline must be a future date", ErrValidation)
	}

	remaining := targetAmount.Sub(targetAmount, savedAmount)
	if remaining.Sign() < 0 {
		remaining.SetInt64(0)
	}

	requiredMonthly := remaining.Quo(remaining, parseIntToRat(monthsRemaining))
	return requiredMonthly, remaining.Sign() == 0, nil
}

func (s *GoalService) emitMilestones(
	ctx context.Context,
	goal *domain.Goal,
	beforeSaved *big.Rat,
	afterSaved *big.Rat,
	targetAmount *big.Rat,
	occurredAt time.Time,
) error {
	if s.milestoneEmitter == nil || targetAmount.Sign() <= 0 {
		return nil
	}

	milestones := []int{25, 50, 75, 100}
	hundred := new(big.Rat).SetInt64(100)
	beforeProgress := new(big.Rat).Mul(new(big.Rat).Set(beforeSaved), hundred)
	beforeProgress.Quo(beforeProgress, targetAmount)
	afterProgress := new(big.Rat).Mul(new(big.Rat).Set(afterSaved), hundred)
	afterProgress.Quo(afterProgress, targetAmount)

	for _, threshold := range milestones {
		marker := new(big.Rat).SetInt64(int64(threshold))
		if beforeProgress.Cmp(marker) < 0 && afterProgress.Cmp(marker) >= 0 {
			if err := s.milestoneEmitter.EmitGoalMilestoneReached(ctx, GoalMilestoneReachedEvent{
				UserID:       goal.UserID,
				GoalID:       goal.ID,
				Milestone:    threshold,
				SavedAmount:  goal.SavedAmount,
				TargetAmount: goal.TargetAmount,
				Progress:     afterProgress.FloatString(4),
				OccurredAt:   occurredAt,
			}); err != nil {
				return fmt.Errorf("emit goal milestone reached: %w", err)
			}
		}
	}

	return nil
}
