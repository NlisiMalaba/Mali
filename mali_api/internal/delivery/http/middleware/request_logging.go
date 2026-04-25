package middleware

import (
	"context"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/rs/zerolog"
)

const requestIDHeader = "X-Request-ID"

type contextKey string

const requestIDContextKey contextKey = "request_id"

func RequestID() fiber.Handler {
	return func(c *fiber.Ctx) error {
		requestID := c.Get(requestIDHeader)
		if requestID == "" {
			requestID = uuid.NewString()
		}

		c.Set(requestIDHeader, requestID)
		c.Locals("request_id", requestID)
		c.SetUserContext(context.WithValue(c.UserContext(), requestIDContextKey, requestID))

		return c.Next()
	}
}

func RequestLogger(logger zerolog.Logger) fiber.Handler {
	return func(c *fiber.Ctx) error {
		start := time.Now()
		err := c.Next()
		latency := time.Since(start)

		requestID, _ := c.Locals("request_id").(string)

		event := logger.Info()
		if err != nil {
			event = logger.Error().Err(err)
		}

		event.
			Str("request_id", requestID).
			Str("method", c.Method()).
			Str("path", c.Path()).
			Int("status_code", c.Response().StatusCode()).
			Dur("latency", latency).
			Msg("http_request")

		return err
	}
}

