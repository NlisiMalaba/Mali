package router

import "github.com/gofiber/fiber/v2"

func registerRateRoutes(v1 fiber.Router, deps Dependencies) {
	if deps.RateHandler == nil || deps.JWTAuthMiddleware == nil {
		return
	}

	rateRoutes := v1.Group("/rates")
	rateRoutes.Use(deps.JWTAuthMiddleware)

	rateRoutes.Get("/", deps.RateHandler.ListRates)
	rateRoutes.Post("/", deps.RateHandler.SetManualRate)
	rateRoutes.Get("/latest", deps.RateHandler.GetLatestRate)
}

