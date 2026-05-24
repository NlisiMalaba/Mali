package middleware

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
)

// CORS returns Fiber CORS middleware. In production, cross-origin access is disabled
// unless CORSAllowedOrigins is set (comma-separated list). In non-production, defaults
// to AllowOrigins "*" when unset.
func CORS(env, corsAllowedOrigins string) fiber.Handler {
	origins := strings.TrimSpace(corsAllowedOrigins)
	if origins == "" {
		if strings.EqualFold(env, "production") {
			return func(c *fiber.Ctx) error {
				return c.Next()
			}
		}
		origins = "*"
	}

	return cors.New(cors.Config{
		AllowOrigins: origins,
		AllowMethods: strings.Join([]string{
			fiber.MethodGet,
			fiber.MethodPost,
			fiber.MethodPut,
			fiber.MethodPatch,
			fiber.MethodDelete,
			fiber.MethodOptions,
		}, ","),
		AllowHeaders: strings.Join([]string{
			"Origin",
			"Content-Type",
			"Accept",
			"Authorization",
			requestIDHeader,
		}, ","),
	})
}
