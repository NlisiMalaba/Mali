package router

import (
	"github.com/gofiber/fiber/v2"
	httpHandler "github.com/mali-app/mali_api/internal/delivery/http/handler"
)

type Dependencies struct {
	AuthHandler        *httpHandler.AuthHandler
	WalletHandler      *httpHandler.WalletHandler
	CategoryHandler    *httpHandler.CategoryHandler
	TransactionHandler *httpHandler.TransactionHandler
	GoalHandler        *httpHandler.GoalHandler
	AuthRateLimiter    fiber.Handler
	JWTAuthMiddleware  fiber.Handler
}

func Register(app *fiber.App, deps Dependencies) {
	registerSystemRoutes(app)

	v1 := app.Group("/v1")
	registerAuthRoutes(v1, deps)
	registerWalletRoutes(v1, deps)
	registerCategoryRoutes(v1, deps)
	registerTransactionRoutes(v1, deps)
	registerGoalRoutes(v1, deps)
}

