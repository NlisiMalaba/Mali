package router

import "github.com/gofiber/fiber/v2"

func registerBudgetRoutes(v1 fiber.Router, deps Dependencies) {
	if deps.BudgetHandler == nil || deps.JWTAuthMiddleware == nil {
		return
	}

	budgetRoutes := v1.Group("/budgets")
	budgetRoutes.Use(deps.JWTAuthMiddleware)
	if deps.SyncLogMiddleware != nil {
		budgetRoutes.Use(deps.SyncLogMiddleware)
	}

	budgetRoutes.Post("/", deps.BudgetHandler.UpsertBudget)
	budgetRoutes.Get("/", deps.BudgetHandler.ListBudgetStatus)
}

