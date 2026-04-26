package router

import "github.com/gofiber/fiber/v2"

func registerAnalyticsRoutes(v1 fiber.Router, deps Dependencies) {
	if deps.AnalyticsHandler == nil || deps.JWTAuthMiddleware == nil {
		return
	}

	analyticsRoutes := v1.Group("/analytics")
	analyticsRoutes.Use(deps.JWTAuthMiddleware)

	analyticsRoutes.Get("/monthly", deps.AnalyticsHandler.GetMonthlyReport)
	analyticsRoutes.Get("/trends", deps.AnalyticsHandler.GetMonthlyTrends)
	analyticsRoutes.Get("/categories", deps.AnalyticsHandler.GetCategoryBreakdown)
}

