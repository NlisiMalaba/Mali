package router

import "github.com/gofiber/fiber/v2"

func registerWalletRoutes(v1 fiber.Router, deps Dependencies) {
	if deps.WalletHandler == nil || deps.JWTAuthMiddleware == nil {
		return
	}

	walletRoutes := v1.Group("/wallets")
	walletRoutes.Use(deps.JWTAuthMiddleware)

	walletRoutes.Get("/", deps.WalletHandler.ListWallets)
	walletRoutes.Post("/", deps.WalletHandler.CreateWallet)
	walletRoutes.Patch("/:id", deps.WalletHandler.UpdateWallet)
	walletRoutes.Delete("/:id", deps.WalletHandler.DeleteWallet)
}

