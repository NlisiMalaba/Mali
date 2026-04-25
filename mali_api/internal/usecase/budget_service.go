package usecase

import (
	"context"
	"fmt"
	"math/big"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
)

type GetBudgetStatusInput struct {
	UserID uuid.UUID
	Month  int32
	Year   int32
}

type UpsertBudgetInput struct {
	UserID     uuid.UUID
	CategoryID uuid.UUID
	Currency   string
	Amount     string
	Month      int32
	Year       int32
	Rollover   bool
}

type BudgetStatus struct {
	Budget      *domain.Budget
	Spent       string
	Remaining   string
	PercentUsed string
}

type BudgetExceededEvent struct {
	UserID      uuid.UUID
	BudgetID    uuid.UUID
	CategoryID  uuid.UUID
	Month       int32
	Year        int32
	Threshold   int
	BudgetAmount string
	SpentAmount  string
	PercentUsed  string
	OccurredAt   time.Time
}

type BudgetExceededEmitter interface {
	EmitBudgetExceeded(ctx context.Context, event BudgetExceededEvent) error
}

type BudgetService struct {
	budgetRepository domain.IBudgetRepository
	exceededEmitter  BudgetExceededEmitter
	now              func() time.Time

	mu                   sync.Mutex
	lastEmittedThreshold map[string]int
}

func NewBudgetService(budgetRepository domain.IBudgetRepository) (*BudgetService, error) {
	if budgetRepository == nil {
		return nil, fmt.Errorf("%w: budget repository is required", ErrValidation)
	}

	return &BudgetService{
		budgetRepository:      budgetRepository,
		now:                   time.Now,
		lastEmittedThreshold:  make(map[string]int),
	}, nil
}

func (s *BudgetService) SetBudgetExceededEmitter(emitter BudgetExceededEmitter) {
	s.exceededEmitter = emitter
}

func (s *BudgetService) UpsertBudget(ctx context.Context, input UpsertBudgetInput) (*domain.Budget, error) {
	if s.budgetRepository == nil {
		return nil, fmt.Errorf("budget service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if input.CategoryID == uuid.Nil {
		return nil, fmt.Errorf("%w: category_id is required", ErrValidation)
	}
	currency := normalizeCurrencyCode(input.Currency)
	if currency == "" {
		return nil, fmt.Errorf("%w: currency is required", ErrValidation)
	}
	if input.Month < 1 || input.Month > 12 {
		return nil, fmt.Errorf("%w: month must be between 1 and 12", ErrValidation)
	}
	if input.Year < 1 {
		return nil, fmt.Errorf("%w: year is required", ErrValidation)
	}

	amount := normalizeAmount(input.Amount)
	amountValue, err := parseAmount(amount)
	if err != nil {
		return nil, fmt.Errorf("%w: invalid amount", ErrValidation)
	}
	if amountValue.Sign() <= 0 {
		return nil, fmt.Errorf("%w: amount must be greater than 0", ErrValidation)
	}

	created, err := s.budgetRepository.Upsert(ctx, &domain.Budget{
		UserID:     input.UserID,
		CategoryID: input.CategoryID,
		Currency:   currency,
		Amount:     amount,
		Month:      input.Month,
		Year:       input.Year,
		Rollover:   input.Rollover,
	})
	if err != nil {
		return nil, fmt.Errorf("upsert budget: %w", err)
	}

	return created, nil
}

func (s *BudgetService) GetBudgetStatus(ctx context.Context, input GetBudgetStatusInput) ([]BudgetStatus, error) {
	if s.budgetRepository == nil {
		return nil, fmt.Errorf("budget service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if input.Month < 1 || input.Month > 12 {
		return nil, fmt.Errorf("%w: month must be between 1 and 12", ErrValidation)
	}
	if input.Year < 1 {
		return nil, fmt.Errorf("%w: year is required", ErrValidation)
	}

	budgets, err := s.budgetRepository.ListByUserMonth(ctx, input.UserID, input.Month, input.Year)
	if err != nil {
		return nil, fmt.Errorf("list budgets by user month: %w", err)
	}

	statuses := make([]BudgetStatus, 0, len(budgets))
	for _, budget := range budgets {
		spent, err := s.budgetRepository.GetSpentByCategory(ctx, input.UserID, budget.CategoryID, input.Month, input.Year)
		if err != nil {
			return nil, fmt.Errorf("get budget spent by category: %w", err)
		}

		status, threshold, err := computeBudgetStatus(budget, spent)
		if err != nil {
			return nil, err
		}
		statuses = append(statuses, status)

		if err := s.emitBudgetExceededIfCrossed(ctx, input, status, threshold); err != nil {
			return nil, err
		}
	}

	return statuses, nil
}

func computeBudgetStatus(budget *domain.Budget, spentAmount string) (BudgetStatus, int, error) {
	budgetValue, err := parseAmount(normalizeAmount(budget.Amount))
	if err != nil {
		return BudgetStatus{}, 0, fmt.Errorf("%w: invalid budget amount", ErrValidation)
	}
	if budgetValue.Sign() <= 0 {
		return BudgetStatus{}, 0, fmt.Errorf("%w: budget amount must be greater than 0", ErrValidation)
	}

	spentValue, err := parseAmount(normalizeAmount(spentAmount))
	if err != nil {
		return BudgetStatus{}, 0, fmt.Errorf("%w: invalid spent amount", ErrValidation)
	}

	remaining := new(big.Rat).Sub(new(big.Rat).Set(budgetValue), spentValue)
	percentUsed := new(big.Rat).Mul(spentValue, big.NewRat(100, 1))
	percentUsed = percentUsed.Quo(percentUsed, budgetValue)

	threshold := 0
	if percentUsed.Cmp(big.NewRat(100, 1)) >= 0 {
		threshold = 100
	} else if percentUsed.Cmp(big.NewRat(80, 1)) >= 0 {
		threshold = 80
	}

	return BudgetStatus{
		Budget:      budget,
		Spent:       spentValue.FloatString(4),
		Remaining:   remaining.FloatString(4),
		PercentUsed: percentUsed.FloatString(4),
	}, threshold, nil
}

func (s *BudgetService) emitBudgetExceededIfCrossed(
	ctx context.Context,
	input GetBudgetStatusInput,
	status BudgetStatus,
	currentThreshold int,
) error {
	if s.exceededEmitter == nil || currentThreshold == 0 {
		return nil
	}

	key := budgetThresholdKey(status.Budget.ID, input.Month, input.Year)

	s.mu.Lock()
	previousThreshold := s.lastEmittedThreshold[key]
	s.mu.Unlock()

	thresholds := []int{80, 100}
	for _, threshold := range thresholds {
		if previousThreshold < threshold && currentThreshold >= threshold {
			if err := s.exceededEmitter.EmitBudgetExceeded(ctx, BudgetExceededEvent{
				UserID:       input.UserID,
				BudgetID:     status.Budget.ID,
				CategoryID:   status.Budget.CategoryID,
				Month:        input.Month,
				Year:         input.Year,
				Threshold:    threshold,
				BudgetAmount: status.Budget.Amount,
				SpentAmount:  status.Spent,
				PercentUsed:  status.PercentUsed,
				OccurredAt:   s.now().UTC(),
			}); err != nil {
				return fmt.Errorf("emit budget exceeded: %w", err)
			}
		}
	}

	s.mu.Lock()
	s.lastEmittedThreshold[key] = currentThreshold
	s.mu.Unlock()
	return nil
}

func budgetThresholdKey(budgetID uuid.UUID, month, year int32) string {
	return fmt.Sprintf("%s:%d:%d", budgetID.String(), month, year)
}

