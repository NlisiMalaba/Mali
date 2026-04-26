package router

import "github.com/gofiber/fiber/v2"

func registerTransactionRoutes(v1 fiber.Router, deps Dependencies) {
	if deps.TransactionHandler == nil || deps.JWTAuthMiddleware == nil {
		return
	}

	transactionRoutes := v1.Group("/transactions")
	transactionRoutes.Use(deps.JWTAuthMiddleware)
	if deps.SyncLogMiddleware != nil {
		transactionRoutes.Use(deps.SyncLogMiddleware)
	}

	transactionRoutes.Post("/", deps.TransactionHandler.CreateTransaction)
	transactionRoutes.Get("/", deps.TransactionHandler.ListTransactions)
	transactionRoutes.Get("/:id", deps.TransactionHandler.GetTransaction)
	transactionRoutes.Delete("/:id", deps.TransactionHandler.DeleteTransaction)
}

