package router

import "github.com/gofiber/fiber/v2"

func registerAuthRoutes(v1 fiber.Router, deps Dependencies) {
	if deps.AuthHandler == nil {
		return
	}

	authRoutes := v1.Group("/auth")
	if deps.AuthRateLimiter != nil {
		authRoutes.Use(deps.AuthRateLimiter)
	}

	authRoutes.Post("/register", deps.AuthHandler.Register)
	authRoutes.Post("/login", deps.AuthHandler.Login)
	authRoutes.Post("/refresh", deps.AuthHandler.Refresh)
	authRoutes.Post("/logout", deps.AuthHandler.Logout)
}

