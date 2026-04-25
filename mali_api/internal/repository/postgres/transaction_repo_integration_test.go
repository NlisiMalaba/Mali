package postgres

import (
	"context"
	"math/big"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/repository/sqlc"
	"github.com/mali-app/mali_api/internal/usecase"
)

func TestTransactionService_LogTransaction_ConcurrentExpensesSameWallet(t *testing.T) {
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

	txService, err := usecase.NewTransactionService(transactionRepo, walletRepo)
	if err != nil {
		t.Fatalf("new transaction service: %v", err)
	}

	email := "concurrency@example.com"
	passwordHash := "hash"
	user, err := userRepo.Create(ctx, &domain.User{
		Email:        &email,
		Name:         "Concurrency User",
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

	start := make(chan struct{})
	errs := make(chan error, 2)
	var wg sync.WaitGroup

	runExpense := func(syncID uuid.UUID) {
		defer wg.Done()
		<-start
		_, runErr := txService.LogTransaction(ctx, usecase.LogTransactionInput{
			UserID:       user.ID,
			WalletID:     wallet.ID,
			Type:         "expense",
			Amount:       "10",
			Currency:     "USD",
			Source:       "manual",
			TransactedAt: time.Now().UTC(),
			SyncID:       &syncID,
		})
		errs <- runErr
	}

	wg.Add(2)
	go runExpense(uuid.New())
	go runExpense(uuid.New())
	close(start)

	wg.Wait()
	close(errs)

	for runErr := range errs {
		if runErr != nil {
			t.Fatalf("concurrent expense failed: %v", runErr)
		}
	}

	updatedWallet, err := walletRepo.FindByID(ctx, wallet.ID)
	if err != nil {
		t.Fatalf("find wallet by id: %v", err)
	}

	assertBalanceEqual(t, updatedWallet.Balance, "80")
}

func assertBalanceEqual(t *testing.T, actual, expected string) {
	t.Helper()

	actualAmount := new(big.Rat)
	if _, ok := actualAmount.SetString(actual); !ok {
		t.Fatalf("invalid actual amount: %s", actual)
	}
	expectedAmount := new(big.Rat)
	if _, ok := expectedAmount.SetString(expected); !ok {
		t.Fatalf("invalid expected amount: %s", expected)
	}

	if actualAmount.Cmp(expectedAmount) != 0 {
		t.Fatalf("unexpected balance, got=%s want=%s", actual, expected)
	}
}

