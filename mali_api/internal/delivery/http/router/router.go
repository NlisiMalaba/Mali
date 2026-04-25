package router

import (
	"github.com/gofiber/fiber/v2"
	httpHandler "github.com/mali-app/mali_api/internal/delivery/http/handler"
)

type Dependencies struct {
	AuthHandler     *httpHandler.AuthHandler
	AuthRateLimiter fiber.Handler
}

func Register(app *fiber.App, deps Dependencies) {
	registerSystemRoutes(app)

	v1 := app.Group("/v1")
	registerAuthRoutes(v1, deps)
}

