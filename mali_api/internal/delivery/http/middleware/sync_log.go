package middleware

import (
	"context"
	"encoding/json"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type SyncLogWriter interface {
	Create(
		ctx context.Context,
		userID uuid.UUID,
		entityType string,
		entityID uuid.UUID,
		operation string,
		payload json.RawMessage,
	) error
}

func SyncLog(syncWriter SyncLogWriter) fiber.Handler {
	return func(c *fiber.Ctx) error {
		err := c.Next()
		if err != nil || syncWriter == nil {
			return err
		}
		if c.Response().StatusCode() >= fiber.StatusBadRequest {
			return nil
		}

		userIDRaw, ok := c.Locals("userID").(string)
		if !ok || strings.TrimSpace(userIDRaw) == "" {
			return nil
		}
		userID, parseErr := uuid.Parse(strings.TrimSpace(userIDRaw))
		if parseErr != nil {
			return nil
		}

		entityType, operation, shouldLog := extractEntityOperation(c)
		if !shouldLog {
			return nil
		}

		entityID, entityErr := extractEntityID(c, entityType)
		if entityErr != nil || entityID == uuid.Nil {
			return nil
		}

		payload := json.RawMessage(c.Body())
		if !json.Valid(payload) {
			payload = json.RawMessage(`{}`)
		}

		_ = syncWriter.Create(c.UserContext(), userID, entityType, entityID, operation, payload)
		return nil
	}
}

func extractEntityOperation(c *fiber.Ctx) (entityType string, operation string, shouldLog bool) {
	method := strings.ToUpper(strings.TrimSpace(c.Method()))
	segments := strings.Split(strings.Trim(c.Path(), "/"), "/")
	if len(segments) < 2 || segments[0] != "v1" {
		return "", "", false
	}

	switch segments[1] {
	case "transactions":
		entityType = "transaction"
	case "goals":
		entityType = "goal"
	case "budgets":
		entityType = "budget"
	case "wallets":
		entityType = "wallet"
	default:
		return "", "", false
	}

	switch method {
	case fiber.MethodPost:
		operation = "create"
		if entityType == "goal" && len(segments) >= 4 && segments[3] == "contribute" {
			operation = "contribute"
		}
		if entityType == "budget" {
			operation = "upsert"
		}
	case fiber.MethodPatch:
		operation = "update"
	case fiber.MethodDelete:
		operation = "delete"
	default:
		return "", "", false
	}

	return entityType, operation, true
}

func extractEntityID(c *fiber.Ctx, entityType string) (uuid.UUID, error) {
	if entityType == "budget" && strings.EqualFold(c.Method(), fiber.MethodPost) {
		return extractEntityIDFromResponse(c, "budget")
	}

	if id := strings.TrimSpace(c.Params("id")); id != "" {
		return uuid.Parse(id)
	}

	switch entityType {
	case "transaction":
		return extractEntityIDFromResponse(c, "transaction")
	case "goal":
		return extractEntityIDFromResponse(c, "goal")
	case "wallet":
		return extractEntityIDFromResponse(c, "wallet")
	default:
		return uuid.Nil, fiber.ErrBadRequest
	}
}

func extractEntityIDFromResponse(c *fiber.Ctx, topLevelKey string) (uuid.UUID, error) {
	var response map[string]json.RawMessage
	if err := json.Unmarshal(c.Response().Body(), &response); err != nil {
		return uuid.Nil, err
	}
	entityRaw, ok := response[topLevelKey]
	if !ok {
		return uuid.Nil, fiber.ErrBadRequest
	}

	var entity map[string]json.RawMessage
	if err := json.Unmarshal(entityRaw, &entity); err != nil {
		return uuid.Nil, err
	}
	idRaw, ok := entity["id"]
	if !ok {
		return uuid.Nil, fiber.ErrBadRequest
	}
	var idValue string
	if err := json.Unmarshal(idRaw, &idValue); err != nil {
		return uuid.Nil, err
	}
	return uuid.Parse(strings.TrimSpace(idValue))
}
