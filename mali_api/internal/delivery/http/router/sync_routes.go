package router

import "github.com/gofiber/fiber/v2"

func registerSyncRoutes(v1 fiber.Router, deps Dependencies) {
	if deps.SyncHandler == nil || deps.JWTAuthMiddleware == nil {
		return
	}

	syncRoutes := v1.Group("/sync")
	syncRoutes.Use(deps.JWTAuthMiddleware)

	syncRoutes.Post("/push", deps.SyncHandler.Push)
	syncRoutes.Get("/pull", deps.SyncHandler.Pull)
}
