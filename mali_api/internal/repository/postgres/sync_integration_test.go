package postgres

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/repository/sqlc"
	"github.com/mali-app/mali_api/internal/usecase"
)

func TestSyncServicePush_IdempotentWhenSameBatchPushedTwice(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	pg := startPostgresContainer(t, ctx)

	connString, err := pg.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		t.Fatalf("get postgres connection string: %v", err)
	}

	pool, err := pgxpool.New(ctx, connString)
	if err != nil {
		t.Fatalf("connect pgx pool: %v", err)
	}
	defer pool.Close()

	if err := applyMigrations(ctx, pool); err != nil {
		t.Fatalf("apply migrations: %v", err)
	}

	queries := sqlc.New(pool)
	userRepo := NewUserRepository(queries)
	walletRepo := NewWalletRepository(queries)
	transactionRepo := NewTransactionRepository(pool)
	goalRepo := NewGoalRepository(pool)
	budgetRepo := NewBudgetRepository(queries)
	syncLogRepo := NewSyncLogRepository(pool)

	transactionService, err := usecase.NewTransactionService(transactionRepo, walletRepo)
	if err != nil {
		t.Fatalf("new transaction service: %v", err)
	}
	goalService, err := usecase.NewGoalService(goalRepo)
	if err != nil {
		t.Fatalf("new goal service: %v", err)
	}
	budgetService, err := usecase.NewBudgetService(budgetRepo)
	if err != nil {
		t.Fatalf("new budget service: %v", err)
	}
	walletService, err := usecase.NewWalletService(walletRepo, []string{"USD"})
	if err != nil {
		t.Fatalf("new wallet service: %v", err)
	}
	syncService, err := usecase.NewSyncService(transactionService, goalService, budgetService, walletService, syncLogRepo)
	if err != nil {
		t.Fatalf("new sync service: %v", err)
	}

	email := "sync-idempotency@example.com"
	passwordHash := "hash"
	user, err := userRepo.Create(ctx, &domain.User{
		Email:        &email,
		Name:         "Sync Idempotency User",
		PasswordHash: &passwordHash,
	})
	if err != nil {
		t.Fatalf("create user: %v", err)
	}

	wallet, err := walletRepo.Create(ctx, &domain.Wallet{
		UserID:     user.ID,
		Name:       "Main Wallet",
		Currency:   "USD",
		WalletType: "cash",
		Balance:    "100",
		IsActive:   true,
	})
	if err != nil {
		t.Fatalf("create wallet: %v", err)
	}

	changeSyncID := uuid.NewString()
	payload := `{
		"wallet_id":"` + wallet.ID.String() + `",
		"type":"expense",
		"amount":"10.0000",
		"currency":"USD",
		"source":"mobile",
		"transacted_at":"` + time.Now().UTC().Format(time.RFC3339) + `"
	}`

	batch := usecase.SyncPushInput{
		UserID: user.ID,
		Changes: []usecase.SyncChange{
			{
				SyncID:    changeSyncID,
				Entity:    "transaction",
				Operation: "create",
				Payload:   []byte(payload),
			},
		},
	}

	firstPush, err := syncService.Push(ctx, batch)
	if err != nil {
		t.Fatalf("first push: %v", err)
	}
	if got, want := len(firstPush.AcceptedIDs), 1; got != want {
		t.Fatalf("first push accepted=%d want=%d", got, want)
	}
	if got := len(firstPush.Conflicts); got != 0 {
		t.Fatalf("first push conflicts=%d want=0", got)
	}

	secondPush, err := syncService.Push(ctx, batch)
	if err != nil {
		t.Fatalf("second push: %v", err)
	}
	if got, want := len(secondPush.AcceptedIDs), 1; got != want {
		t.Fatalf("second push accepted=%d want=%d", got, want)
	}
	if got := len(secondPush.Conflicts); got != 0 {
		t.Fatalf("second push conflicts=%d want=0", got)
	}

	var txCount int
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM transactions WHERE sync_id = $1`, changeSyncID).Scan(&txCount); err != nil {
		t.Fatalf("count transactions by sync_id: %v", err)
	}
	if txCount != 1 {
		t.Fatalf("expected exactly one transaction for sync_id, got=%d", txCount)
	}
}

