package main

import (
	"log"

	"github.com/mali-app/mali_api/config"
	"github.com/gofiber/fiber/v2"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	app := fiber.New()

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
		})
	})

	if err := app.Listen(":" + cfg.Port); err != nil {
		log.Fatalf("failed to start api: %v", err)
	}
}

