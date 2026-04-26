package router

import "github.com/gofiber/fiber/v2"

func registerGoalRoutes(v1 fiber.Router, deps Dependencies) {
	if deps.GoalHandler == nil || deps.JWTAuthMiddleware == nil {
		return
	}

	goalRoutes := v1.Group("/goals")
	goalRoutes.Use(deps.JWTAuthMiddleware)
	if deps.SyncLogMiddleware != nil {
		goalRoutes.Use(deps.SyncLogMiddleware)
	}

	goalRoutes.Get("/", deps.GoalHandler.ListGoals)
	goalRoutes.Post("/", deps.GoalHandler.CreateGoal)
	goalRoutes.Get("/:id", deps.GoalHandler.GetGoal)
	goalRoutes.Patch("/:id", deps.GoalHandler.UpdateGoal)
	goalRoutes.Delete("/:id", deps.GoalHandler.DeleteGoal)
	goalRoutes.Post("/:id/contribute", deps.GoalHandler.ContributeToGoal)
}
