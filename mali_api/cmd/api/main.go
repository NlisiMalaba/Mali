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

var supportedWalletCurrencies = []string{
	"USD",
	"EUR",
	"GBP",
	"KES",
	"UGX",
	"TZS",
	"NGN",
	"ZAR",
}

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
	walletRepo := httpRepo.NewWalletRepository(queries)
	categoryRepo := httpRepo.NewCategoryRepository(queries)
	transactionRepo := httpRepo.NewTransactionRepository(dbPool)
	goalRepo := httpRepo.NewGoalRepository(dbPool)
	budgetRepo := httpRepo.NewBudgetRepository(queries)

	authService, err := usecase.NewAuthService(userRepo, refreshRepo, cfg.JWTSecret, cfg.JWTRefreshSecret)
	if err != nil {
		log.Fatalf("failed to initialize auth service: %v", err)
	}
	authHandler := httpHandler.NewAuthHandler(authService, validator.New())
	walletService, err := usecase.NewWalletService(walletRepo, supportedWalletCurrencies)
	if err != nil {
		log.Fatalf("failed to initialize wallet service: %v", err)
	}
	walletHandler := httpHandler.NewWalletHandler(walletService, validator.New())
	categoryService, err := usecase.NewCategoryService(categoryRepo)
	if err != nil {
		log.Fatalf("failed to initialize category service: %v", err)
	}
	categoryHandler := httpHandler.NewCategoryHandler(categoryService, validator.New())
	transactionService, err := usecase.NewTransactionService(transactionRepo, walletRepo)
	if err != nil {
		log.Fatalf("failed to initialize transaction service: %v", err)
	}
	transactionHandler := httpHandler.NewTransactionHandler(transactionService, validator.New())
	goalService, err := usecase.NewGoalService(goalRepo)
	if err != nil {
		log.Fatalf("failed to initialize goal service: %v", err)
	}
	goalHandler := httpHandler.NewGoalHandler(goalService, validator.New())
	budgetService, err := usecase.NewBudgetService(budgetRepo)
	if err != nil {
		log.Fatalf("failed to initialize budget service: %v", err)
	}
	budgetHandler := httpHandler.NewBudgetHandler(budgetService, validator.New())
	redisOptions, err := redis.ParseURL(cfg.RedisURL)
	if err != nil {
		log.Fatalf("failed to parse redis url: %v", err)
	}
	redisClient := redis.NewClient(redisOptions)
	httpRouter.Register(app, httpRouter.Dependencies{
		AuthHandler:        authHandler,
		WalletHandler:      walletHandler,
		CategoryHandler:    categoryHandler,
		TransactionHandler: transactionHandler,
		GoalHandler:        goalHandler,
		BudgetHandler:      budgetHandler,
		AuthRateLimiter:    httpmiddleware.AuthRateLimit(redisClient, 10, time.Minute),
		JWTAuthMiddleware:  httpmiddleware.JWTAuth(cfg.JWTSecret),
	})

	if err := app.Listen(":" + cfg.Port); err != nil {
		log.Fatalf("failed to start api: %v", err)
	}
}

