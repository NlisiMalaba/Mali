package domain

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type Goal struct {
	ID              uuid.UUID
	UserID          uuid.UUID
	Name            string
	Emoji           *string
	GoalType        *string
	TargetAmount    string
	Currency        string
	SavedAmount     string
	RequiredMonthly string
	Deadline        *time.Time
	Priority        int32
	IsCompleted     bool
	CreatedAt       time.Time
}

type GoalContribution struct {
	ID            uuid.UUID
	GoalID        uuid.UUID
	Amount        string
	Currency      string
	Notes         *string
	ContributedAt time.Time
}

type IGoalRepository interface {
	Create(ctx context.Context, goal *Goal) (*Goal, error)
	ListByUser(ctx context.Context, userID uuid.UUID) ([]*Goal, error)
	FindByID(ctx context.Context, userID, goalID uuid.UUID) (*Goal, error)
	Update(ctx context.Context, goal *Goal) error
	UpdateSavedAmount(ctx context.Context, userID, goalID uuid.UUID, savedAmount string) error
	Delete(ctx context.Context, userID, goalID uuid.UUID) error
	CreateContribution(ctx context.Context, contribution *GoalContribution) (*GoalContribution, error)
	ListContributionsByGoal(ctx context.Context, userID, goalID uuid.UUID) ([]*GoalContribution, error)
}
