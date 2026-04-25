package handler

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/usecase"
)

type GoalUseCaser interface {
	CreateGoal(ctx context.Context, input usecase.CreateGoalInput) (*domain.Goal, error)
	ListGoals(ctx context.Context, userID uuid.UUID) ([]*domain.Goal, error)
	GetGoalByID(ctx context.Context, userID, goalID uuid.UUID) (*domain.Goal, error)
	UpdateGoal(ctx context.Context, input usecase.UpdateGoalInput) error
	DeleteGoal(ctx context.Context, userID, goalID uuid.UUID) error
	Contribute(ctx context.Context, input usecase.ContributeGoalInput) (*domain.Goal, error)
}

type GoalHandler struct {
	goalService GoalUseCaser
	validator   *validator.Validate
}

type CreateGoalRequestDTO struct {
	Name         string `json:"name" validate:"required"`
	Emoji        string `json:"emoji"`
	GoalType     string `json:"goal_type"`
	TargetAmount string `json:"target_amount" validate:"required"`
	Currency     string `json:"currency" validate:"required,len=3"`
	SavedAmount  string `json:"saved_amount"`
	Deadline     string `json:"deadline" validate:"required"`
	Priority     int32  `json:"priority"`
}

type UpdateGoalRequestDTO struct {
	Name         string `json:"name" validate:"required"`
	Emoji        string `json:"emoji"`
	GoalType     string `json:"goal_type"`
	TargetAmount string `json:"target_amount" validate:"required"`
	Currency     string `json:"currency" validate:"required,len=3"`
	Deadline     string `json:"deadline" validate:"required"`
	Priority     int32  `json:"priority"`
	IsCompleted  bool   `json:"is_completed"`
}

type ContributeGoalRequestDTO struct {
	Amount        string `json:"amount" validate:"required"`
	Currency      string `json:"currency" validate:"omitempty,len=3"`
	Notes         string `json:"notes"`
	ContributedAt string `json:"contributed_at"`
}

type GoalResponseDTO struct {
	ID              string  `json:"id"`
	UserID          string  `json:"user_id"`
	Name            string  `json:"name"`
	Emoji           *string `json:"emoji,omitempty"`
	GoalType        *string `json:"goal_type,omitempty"`
	TargetAmount    string  `json:"target_amount"`
	Currency        string  `json:"currency"`
	SavedAmount     string  `json:"saved_amount"`
	RequiredMonthly string  `json:"required_monthly"`
	Deadline        *string `json:"deadline,omitempty"`
	Priority        int32   `json:"priority"`
	IsCompleted     bool    `json:"is_completed"`
	CreatedAt       string  `json:"created_at"`
}

func NewGoalHandler(goalService GoalUseCaser, validate *validator.Validate) *GoalHandler {
	if validate == nil {
		validate = validator.New()
	}
	return &GoalHandler{
		goalService: goalService,
		validator:   validate,
	}
}

func (h *GoalHandler) ListGoals(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	goals, err := h.goalService.ListGoals(c.UserContext(), userID)
	if err != nil {
		status, code := mapGoalError(err)
		return respondError(c, status, code, err.Error())
	}

	items := make([]GoalResponseDTO, 0, len(goals))
	for _, goal := range goals {
		items = append(items, toGoalResponse(goal))
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"goals": items})
}

func (h *GoalHandler) CreateGoal(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	var req CreateGoalRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}
	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	deadline, err := time.Parse(time.RFC3339, strings.TrimSpace(req.Deadline))
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid deadline")
	}

	created, err := h.goalService.CreateGoal(c.UserContext(), usecase.CreateGoalInput{
		UserID:       userID,
		Name:         strings.TrimSpace(req.Name),
		Emoji:        strings.TrimSpace(req.Emoji),
		GoalType:     strings.TrimSpace(req.GoalType),
		TargetAmount: strings.TrimSpace(req.TargetAmount),
		Currency:     strings.TrimSpace(req.Currency),
		SavedAmount:  strings.TrimSpace(req.SavedAmount),
		Deadline:     deadline,
		Priority:     req.Priority,
	})
	if err != nil {
		status, code := mapGoalError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"goal": toGoalResponse(created)})
}

func (h *GoalHandler) GetGoal(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}
	goalID, err := goalIDParam(c)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	goal, err := h.goalService.GetGoalByID(c.UserContext(), userID, goalID)
	if err != nil {
		status, code := mapGoalError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"goal": toGoalResponse(goal)})
}

func (h *GoalHandler) UpdateGoal(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}
	goalID, err := goalIDParam(c)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	var req UpdateGoalRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}
	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}
	deadline, err := time.Parse(time.RFC3339, strings.TrimSpace(req.Deadline))
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid deadline")
	}

	if err := h.goalService.UpdateGoal(c.UserContext(), usecase.UpdateGoalInput{
		UserID:       userID,
		GoalID:       goalID,
		Name:         strings.TrimSpace(req.Name),
		Emoji:        strings.TrimSpace(req.Emoji),
		GoalType:     strings.TrimSpace(req.GoalType),
		TargetAmount: strings.TrimSpace(req.TargetAmount),
		Currency:     strings.TrimSpace(req.Currency),
		Deadline:     deadline,
		Priority:     req.Priority,
		IsCompleted:  req.IsCompleted,
	}); err != nil {
		status, code := mapGoalError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "goal updated successfully"})
}

func (h *GoalHandler) DeleteGoal(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}
	goalID, err := goalIDParam(c)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	if err := h.goalService.DeleteGoal(c.UserContext(), userID, goalID); err != nil {
		status, code := mapGoalError(err)
		return respondError(c, status, code, err.Error())
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "goal deleted successfully"})
}

func (h *GoalHandler) ContributeToGoal(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}
	goalID, err := goalIDParam(c)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	var req ContributeGoalRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}
	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	var contributedAt time.Time
	if value := strings.TrimSpace(req.ContributedAt); value != "" {
		parsed, parseErr := time.Parse(time.RFC3339, value)
		if parseErr != nil {
			return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid contributed_at")
		}
		contributedAt = parsed
	}

	goal, err := h.goalService.Contribute(c.UserContext(), usecase.ContributeGoalInput{
		UserID:        userID,
		GoalID:        goalID,
		Amount:        strings.TrimSpace(req.Amount),
		Currency:      strings.TrimSpace(req.Currency),
		Notes:         strings.TrimSpace(req.Notes),
		ContributedAt: contributedAt,
	})
	if err != nil {
		status, code := mapGoalError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"goal": toGoalResponse(goal)})
}

func (h *GoalHandler) ensureConfigured(c *fiber.Ctx) error {
	if h.goalService != nil {
		return nil
	}
	return respondError(c, fiber.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "goal service is not configured")
}

func goalIDParam(c *fiber.Ctx) (uuid.UUID, error) {
	raw := strings.TrimSpace(c.Params("id"))
	if raw == "" {
		return uuid.Nil, errors.New("goal id is required")
	}
	parsed, err := uuid.Parse(raw)
	if err != nil {
		return uuid.Nil, errors.New("invalid goal id")
	}
	return parsed, nil
}

func mapGoalError(err error) (int, string) {
	switch {
	case errors.Is(err, usecase.ErrValidation):
		return fiber.StatusBadRequest, "VALIDATION_ERROR"
	default:
		return fiber.StatusInternalServerError, "INTERNAL_ERROR"
	}
}

func toGoalResponse(goal *domain.Goal) GoalResponseDTO {
	if goal == nil {
		return GoalResponseDTO{}
	}

	var deadline *string
	if goal.Deadline != nil {
		value := goal.Deadline.UTC().Format(time.RFC3339)
		deadline = &value
	}

	return GoalResponseDTO{
		ID:              goal.ID.String(),
		UserID:          goal.UserID.String(),
		Name:            goal.Name,
		Emoji:           goal.Emoji,
		GoalType:        goal.GoalType,
		TargetAmount:    goal.TargetAmount,
		Currency:        goal.Currency,
		SavedAmount:     goal.SavedAmount,
		RequiredMonthly: goal.RequiredMonthly,
		Deadline:        deadline,
		Priority:        goal.Priority,
		IsCompleted:     goal.IsCompleted,
		CreatedAt:       goal.CreatedAt.UTC().Format(time.RFC3339),
	}
}
