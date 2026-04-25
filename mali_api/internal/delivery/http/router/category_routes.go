package router

import "github.com/gofiber/fiber/v2"

func registerCategoryRoutes(v1 fiber.Router, deps Dependencies) {
	if deps.CategoryHandler == nil || deps.JWTAuthMiddleware == nil {
		return
	}

	categoryRoutes := v1.Group("/categories")
	categoryRoutes.Use(deps.JWTAuthMiddleware)

	categoryRoutes.Get("/", deps.CategoryHandler.ListCategories)
	categoryRoutes.Post("/", deps.CategoryHandler.CreateCategory)
}

