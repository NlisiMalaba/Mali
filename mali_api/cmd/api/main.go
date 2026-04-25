package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mali-app/mali_api/config"
	httpHandler "github.com/mali-app/mali_api/internal/delivery/http/handler"
	httpmiddleware "github.com/mali-app/mali_api/internal/delivery/http/middleware"
	httpRepo "github.com/mali-app/mali_api/internal/repository/postgres"
	"github.com/mali-app/mali_api/internal/repository/sqlc"
	httpRouter "github.com/mali-app/mali_api/internal/delivery/http/router"
	"github.com/mali-app/mali_api/internal/usecase"
	"github.com/gofiber/fiber/v2"
	"github.com/redis/go-redis/v9"
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

	dbPool, err := pgxpool.New(context.Background(), cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("failed to connect to postgres: %v", err)
	}
	if err := dbPool.Ping(context.Background()); err != nil {
		log.Fatalf("failed to ping postgres: %v", err)
	}

	queries := sqlc.New(dbPool)
	userRepo := httpRepo.NewUserRepository(queries)
	refreshRepo := httpRepo.NewRefreshTokenRepository(queries)

	authService, err := usecase.NewAuthService(userRepo, refreshRepo, cfg.JWTSecret, cfg.JWTRefreshSecret)
	if err != nil {
		log.Fatalf("failed to initialize auth service: %v", err)
	}
	authHandler := httpHandler.NewAuthHandler(authService, validator.New())
	redisOptions, err := redis.ParseURL(cfg.RedisURL)
	if err != nil {
		log.Fatalf("failed to parse redis url: %v", err)
	}
	redisClient := redis.NewClient(redisOptions)
	httpRouter.Register(app, httpRouter.Dependencies{
		AuthHandler:     authHandler,
		AuthRateLimiter: httpmiddleware.AuthRateLimit(redisClient, 10, time.Minute),
	})

	if err := app.Listen(":" + cfg.Port); err != nil {
		log.Fatalf("failed to start api: %v", err)
	}
}

