package main

import (
	"log"
	"os"

	"github.com/mali-app/mali_api/config"
	httpmiddleware "github.com/mali-app/mali_api/internal/delivery/http/middleware"
	"github.com/gofiber/fiber/v2"
	"github.com/rs/zerolog"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	app := fiber.New()
	logger := zerolog.New(os.Stdout).With().Timestamp().Logger()

	app.Use(httpmiddleware.RequestID())
	app.Use(httpmiddleware.RequestLogger(logger))

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
		})
	})

	if err := app.Listen(":" + cfg.Port); err != nil {
		log.Fatalf("failed to start api: %v", err)
	}
}

