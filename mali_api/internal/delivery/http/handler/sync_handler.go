package handler

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"strings"
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/usecase"
)

type SyncUseCaser interface {
	Push(ctx context.Context, input usecase.SyncPushInput) (*usecase.SyncPushResult, error)
	Pull(ctx context.Context, input usecase.SyncPullInput) (*usecase.SyncPullResult, error)
}

type SyncHandler struct {
	syncService SyncUseCaser
	validator   *validator.Validate
}

type SyncPushRequestDTO struct {
	Changes []SyncChangeDTO `json:"changes" validate:"required,min=1,max=100,dive"`
}

type SyncChangeDTO struct {
	SyncID    string          `json:"sync_id" validate:"required,uuid4"`
	Entity    string          `json:"entity" validate:"required,oneof=transaction goal budget wallet"`
	Operation string          `json:"operation" validate:"required"`
	Payload   json.RawMessage `json:"payload" validate:"required"`
}

func NewSyncHandler(syncService SyncUseCaser, validate *validator.Validate) *SyncHandler {
	if validate == nil {
		validate = validator.New()
	}
	return &SyncHandler{
		syncService: syncService,
		validator:   validate,
	}
}

func (h *SyncHandler) Push(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	var req SyncPushRequestDTO
	if err := c.BodyParser(&req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "INVALID_REQUEST", "invalid request payload")
	}
	for index := range req.Changes {
		req.Changes[index].SyncID = strings.TrimSpace(req.Changes[index].SyncID)
		req.Changes[index].Entity = strings.TrimSpace(req.Changes[index].Entity)
		req.Changes[index].Operation = strings.TrimSpace(req.Changes[index].Operation)
	}

	if err := h.validator.Struct(req); err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error())
	}

	input := usecase.SyncPushInput{
		UserID:  userID,
		Changes: make([]usecase.SyncChange, 0, len(req.Changes)),
	}
	for _, change := range req.Changes {
		input.Changes = append(input.Changes, usecase.SyncChange{
			SyncID:    change.SyncID,
			Entity:    change.Entity,
			Operation: change.Operation,
			Payload:   change.Payload,
		})
	}

	result, err := h.syncService.Push(c.UserContext(), input)
	if err != nil {
		status, code := mapSyncError(err)
		return respondError(c, status, code, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"accepted_ids": result.AcceptedIDs,
		"conflicts":    result.Conflicts,
		"summary": fiber.Map{
			"received": len(req.Changes),
			"accepted": len(result.AcceptedIDs),
			"conflicts": len(result.Conflicts),
		},
	})
}

func (h *SyncHandler) Pull(c *fiber.Ctx) error {
	if err := h.ensureConfigured(c); err != nil {
		return err
	}
	userID, err := authenticatedUserID(c)
	if err != nil {
		return respondError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", err.Error())
	}

	sinceRaw := strings.TrimSpace(c.Query("since"))
	if sinceRaw == "" {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "since is required")
	}
	since, err := time.Parse(time.RFC3339, sinceRaw)
	if err != nil {
		return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid since")
	}

	limit := 50
	if limitRaw := strings.TrimSpace(c.Query("limit")); limitRaw != "" {
		parsed, convErr := strconv.Atoi(limitRaw)
		if convErr != nil {
			return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid limit")
		}
		limit = parsed
	}

	var cursor *usecase.SyncPullCursor
	cursorIDRaw := strings.TrimSpace(c.Query("cursor_id"))
	cursorSyncedAtRaw := strings.TrimSpace(c.Query("cursor_synced_at"))
	if cursorIDRaw != "" || cursorSyncedAtRaw != "" {
		if cursorIDRaw == "" || cursorSyncedAtRaw == "" {
			return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "cursor_id and cursor_synced_at are both required")
		}

		cursorID, parseErr := uuid.Parse(cursorIDRaw)
		if parseErr != nil {
			return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid cursor_id")
		}
		cursorSyncedAt, parseErr := time.Parse(time.RFC3339, cursorSyncedAtRaw)
		if parseErr != nil {
			return respondError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid cursor_synced_at")
		}
		cursor = &usecase.SyncPullCursor{
			ID:       cursorID,
			SyncedAt: cursorSyncedAt,
		}
	}

	result, err := h.syncService.Pull(c.UserContext(), usecase.SyncPullInput{
		UserID: userID,
		Since:  since,
		Limit:  limit,
		Cursor: cursor,
	})
	if err != nil {
		status, code := mapSyncError(err)
		return respondError(c, status, code, err.Error())
	}

	changes := make([]fiber.Map, 0, len(result.Changes))
	for _, change := range result.Changes {
		changes = append(changes, fiber.Map{
			"id":          change.ID.String(),
			"entity_type": change.EntityType,
			"entity_id":   change.EntityID.String(),
			"operation":   change.Operation,
			"payload":     change.Payload,
			"synced_at":   change.SyncedAt.UTC().Format(time.RFC3339),
		})
	}

	response := fiber.Map{
		"changes": changes,
	}
	if result.NextCursor != nil {
		response["next_cursor"] = fiber.Map{
			"id":        result.NextCursor.ID.String(),
			"synced_at": result.NextCursor.SyncedAt.UTC().Format(time.RFC3339),
		}
	}

	return c.Status(fiber.StatusOK).JSON(response)
}

func (h *SyncHandler) ensureConfigured(c *fiber.Ctx) error {
	if h.syncService != nil {
		return nil
	}
	return respondError(c, fiber.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "sync service is not configured")
}

func mapSyncError(err error) (int, string) {
	switch {
	case errors.Is(err, usecase.ErrValidation):
		return fiber.StatusBadRequest, "VALIDATION_ERROR"
	default:
		return fiber.StatusInternalServerError, "INTERNAL_ERROR"
	}
}
