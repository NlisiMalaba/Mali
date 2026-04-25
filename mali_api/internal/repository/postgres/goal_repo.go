package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mali-app/mali_api/internal/domain"
)

type GoalRepository struct {
	db *pgxpool.Pool
}

func NewGoalRepository(db *pgxpool.Pool) *GoalRepository {
	return &GoalRepository{db: db}
}

var _ domain.IGoalRepository = (*GoalRepository)(nil)

func (r *GoalRepository) Create(ctx context.Context, goal *domain.Goal) (*domain.Goal, error) {
	const query = `
INSERT INTO savings_goals (
  user_id,
  name,
  emoji,
  goal_type,
  target_amount,
  currency,
  saved_amount,
  required_monthly,
  deadline,
  priority,
  is_completed
)
VALUES ($1, $2, $3, $4, $5::numeric, $6, $7::numeric, $8::numeric, $9::date, $10, $11)
RETURNING
  id,
  user_id,
  name,
  emoji,
  goal_type,
  target_amount,
  currency,
  saved_amount,
  required_monthly,
  deadline,
  priority,
  is_completed,
  created_at
`

	row := r.db.QueryRow(
		ctx,
		query,
		goal.UserID,
		goal.Name,
		stringOrNil(goal.Emoji),
		stringOrNil(goal.GoalType),
		goal.TargetAmount,
		goal.Currency,
		goal.SavedAmount,
		goal.RequiredMonthly,
		timeOrNil(goal.Deadline),
		goal.Priority,
		goal.IsCompleted,
	)
	return scanGoal(row)
}

func (r *GoalRepository) ListByUser(ctx context.Context, userID uuid.UUID) ([]*domain.Goal, error) {
	const query = `
SELECT
  id,
  user_id,
  name,
  emoji,
  goal_type,
  target_amount,
  currency,
  saved_amount,
  required_monthly,
  deadline,
  priority,
  is_completed,
  created_at
FROM savings_goals
WHERE user_id = $1
ORDER BY priority ASC, created_at DESC
`
	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("list goals by user: %w", err)
	}
	defer rows.Close()

	out := make([]*domain.Goal, 0)
	for rows.Next() {
		record, scanErr := scanGoal(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		out = append(out, record)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate goals: %w", err)
	}
	return out, nil
}

func (r *GoalRepository) FindByID(ctx context.Context, userID, goalID uuid.UUID) (*domain.Goal, error) {
	const query = `
SELECT
  id,
  user_id,
  name,
  emoji,
  goal_type,
  target_amount,
  currency,
  saved_amount,
  required_monthly,
  deadline,
  priority,
  is_completed,
  created_at
FROM savings_goals
WHERE id = $1
  AND user_id = $2
LIMIT 1
`
	row := r.db.QueryRow(ctx, query, goalID, userID)
	record, err := scanGoal(row)
	if err != nil {
		return nil, err
	}
	return record, nil
}

func (r *GoalRepository) Update(ctx context.Context, goal *domain.Goal) error {
	const query = `
UPDATE savings_goals
SET
  name = $3,
  emoji = $4,
  goal_type = $5,
  target_amount = $6::numeric,
  currency = $7,
  required_monthly = $8::numeric,
  deadline = $9::date,
  priority = $10,
  is_completed = $11
WHERE id = $1
  AND user_id = $2
`
	tag, err := r.db.Exec(
		ctx,
		query,
		goal.ID,
		goal.UserID,
		goal.Name,
		stringOrNil(goal.Emoji),
		stringOrNil(goal.GoalType),
		goal.TargetAmount,
		goal.Currency,
		goal.RequiredMonthly,
		timeOrNil(goal.Deadline),
		goal.Priority,
		goal.IsCompleted,
	)
	if err != nil {
		return fmt.Errorf("update goal: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func (r *GoalRepository) UpdateSavedAmount(ctx context.Context, userID, goalID uuid.UUID, savedAmount string) error {
	const query = `
UPDATE savings_goals
SET saved_amount = $3::numeric
WHERE id = $1
  AND user_id = $2
`
	tag, err := r.db.Exec(ctx, query, goalID, userID, savedAmount)
	if err != nil {
		return fmt.Errorf("update goal saved amount: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func (r *GoalRepository) Delete(ctx context.Context, userID, goalID uuid.UUID) error {
	const query = `
DELETE FROM savings_goals
WHERE id = $1
  AND user_id = $2
`
	tag, err := r.db.Exec(ctx, query, goalID, userID)
	if err != nil {
		return fmt.Errorf("delete goal: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func (r *GoalRepository) CreateContribution(ctx context.Context, contribution *domain.GoalContribution) (*domain.GoalContribution, error) {
	const query = `
INSERT INTO goal_contributions (goal_id, amount, currency, notes, contributed_at)
VALUES ($1, $2::numeric, $3, $4, $5)
RETURNING id, goal_id, amount, currency, notes, contributed_at
`
	row := r.db.QueryRow(
		ctx,
		query,
		contribution.GoalID,
		contribution.Amount,
		contribution.Currency,
		stringOrNil(contribution.Notes),
		contribution.ContributedAt,
	)
	return scanGoalContribution(row)
}

func (r *GoalRepository) ListContributionsByGoal(ctx context.Context, userID, goalID uuid.UUID) ([]*domain.GoalContribution, error) {
	const query = `
SELECT gc.id, gc.goal_id, gc.amount, gc.currency, gc.notes, gc.contributed_at
FROM goal_contributions gc
INNER JOIN savings_goals sg ON sg.id = gc.goal_id
WHERE gc.goal_id = $1
  AND sg.user_id = $2
ORDER BY gc.contributed_at DESC
`
	rows, err := r.db.Query(ctx, query, goalID, userID)
	if err != nil {
		return nil, fmt.Errorf("list contributions by goal: %w", err)
	}
	defer rows.Close()

	out := make([]*domain.GoalContribution, 0)
	for rows.Next() {
		record, scanErr := scanGoalContribution(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		out = append(out, record)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate contributions: %w", err)
	}
	return out, nil
}

func scanGoal(row pgx.Row) (*domain.Goal, error) {
	var (
		id              pgtype.UUID
		userID          pgtype.UUID
		name            string
		emoji           pgtype.Text
		goalType        pgtype.Text
		targetAmount    pgtype.Numeric
		currency        string
		savedAmount     pgtype.Numeric
		requiredMonthly pgtype.Numeric
		deadline        pgtype.Date
		priority        int32
		isCompleted     bool
		createdAt       pgtype.Timestamptz
	)

	if err := row.Scan(
		&id,
		&userID,
		&name,
		&emoji,
		&goalType,
		&targetAmount,
		&currency,
		&savedAmount,
		&requiredMonthly,
		&deadline,
		&priority,
		&isCompleted,
		&createdAt,
	); err != nil {
		if err == pgx.ErrNoRows {
			return nil, pgx.ErrNoRows
		}
		return nil, fmt.Errorf("scan goal: %w", err)
	}

	parsedID, err := uuidFromPG(id)
	if err != nil {
		return nil, fmt.Errorf("parse id: %w", err)
	}
	parsedUserID, err := uuidFromPG(userID)
	if err != nil {
		return nil, fmt.Errorf("parse user_id: %w", err)
	}
	parsedTargetAmount, err := stringFromNumeric(targetAmount)
	if err != nil {
		return nil, fmt.Errorf("parse target_amount: %w", err)
	}
	parsedSavedAmount, err := stringFromNumeric(savedAmount)
	if err != nil {
		return nil, fmt.Errorf("parse saved_amount: %w", err)
	}
	parsedRequiredMonthly, err := stringFromNumeric(requiredMonthly)
	if err != nil {
		return nil, fmt.Errorf("parse required_monthly: %w", err)
	}
	parsedCreatedAt, err := timeFromPG(createdAt)
	if err != nil {
		return nil, fmt.Errorf("parse created_at: %w", err)
	}
	parsedDeadline, err := ptrFromDate(deadline)
	if err != nil {
		return nil, fmt.Errorf("parse deadline: %w", err)
	}

	return &domain.Goal{
		ID:              parsedID,
		UserID:          parsedUserID,
		Name:            name,
		Emoji:           ptrFromText(emoji),
		GoalType:        ptrFromText(goalType),
		TargetAmount:    parsedTargetAmount,
		Currency:        currency,
		SavedAmount:     parsedSavedAmount,
		RequiredMonthly: parsedRequiredMonthly,
		Deadline:        parsedDeadline,
		Priority:        priority,
		IsCompleted:     isCompleted,
		CreatedAt:       parsedCreatedAt,
	}, nil
}

func scanGoalContribution(row pgx.Row) (*domain.GoalContribution, error) {
	var (
		id            pgtype.UUID
		goalID        pgtype.UUID
		amount        pgtype.Numeric
		currency      string
		notes         pgtype.Text
		contributedAt pgtype.Timestamptz
	)

	if err := row.Scan(&id, &goalID, &amount, &currency, &notes, &contributedAt); err != nil {
		return nil, fmt.Errorf("scan goal contribution: %w", err)
	}

	parsedID, err := uuidFromPG(id)
	if err != nil {
		return nil, fmt.Errorf("parse contribution id: %w", err)
	}
	parsedGoalID, err := uuidFromPG(goalID)
	if err != nil {
		return nil, fmt.Errorf("parse contribution goal_id: %w", err)
	}
	parsedAmount, err := stringFromNumeric(amount)
	if err != nil {
		return nil, fmt.Errorf("parse contribution amount: %w", err)
	}
	parsedContributedAt, err := timeFromPG(contributedAt)
	if err != nil {
		return nil, fmt.Errorf("parse contribution contributed_at: %w", err)
	}

	return &domain.GoalContribution{
		ID:            parsedID,
		GoalID:        parsedGoalID,
		Amount:        parsedAmount,
		Currency:      currency,
		Notes:         ptrFromText(notes),
		ContributedAt: parsedContributedAt,
	}, nil
}

func timeOrNil(value *time.Time) interface{} {
	if value == nil {
		return nil
	}
	return *value
}

func ptrFromDate(value pgtype.Date) (*time.Time, error) {
	if !value.Valid {
		return nil, nil
	}
	raw, err := value.Value()
	if err != nil {
		return nil, err
	}
	dateValue, ok := raw.(time.Time)
	if !ok {
		return nil, fmt.Errorf("invalid date value")
	}
	parsed := dateValue.UTC()
	return &parsed, nil
}
