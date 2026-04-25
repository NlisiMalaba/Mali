package usecase

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/mali-app/mali_api/internal/domain"
)

type transactionTestWalletRepository struct {
	wallets map[uuid.UUID]*domain.Wallet
}

func (m *transactionTestWalletRepository) Create(_ context.Context, wallet *domain.Wallet) (*domain.Wallet, error) {
	if m.wallets == nil {
		m.wallets = make(map[uuid.UUID]*domain.Wallet)
	}
	copied := *wallet
	if copied.ID == uuid.Nil {
		copied.ID = uuid.New()
	}
	m.wallets[copied.ID] = &copied
	return &copied, nil
}

func (m *transactionTestWalletRepository) ListByUser(_ context.Context, userID uuid.UUID) ([]*domain.Wallet, error) {
	out := make([]*domain.Wallet, 0)
	for _, wallet := range m.wallets {
		if wallet.UserID != userID {
			continue
		}
		copied := *wallet
		out = append(out, &copied)
	}
	return out, nil
}

func (m *transactionTestWalletRepository) FindByID(_ context.Context, id uuid.UUID) (*domain.Wallet, error) {
	wallet, ok := m.wallets[id]
	if !ok {
		return nil, pgx.ErrNoRows
	}
	copied := *wallet
	return &copied, nil
}

func (m *transactionTestWalletRepository) UpdateBalance(_ context.Context, id uuid.UUID, balance string) error {
	wallet, ok := m.wallets[id]
	if !ok {
		return pgx.ErrNoRows
	}
	wallet.Balance = balance
	return nil
}

func (m *transactionTestWalletRepository) UpdateName(_ context.Context, id uuid.UUID, name string) error {
	wallet, ok := m.wallets[id]
	if !ok {
		return pgx.ErrNoRows
	}
	wallet.Name = name
	return nil
}

func (m *transactionTestWalletRepository) SoftDelete(_ context.Context, id uuid.UUID) error {
	wallet, ok := m.wallets[id]
	if !ok {
		return pgx.ErrNoRows
	}
	wallet.IsActive = false
	return nil
}

type transactionTestRepository struct {
	walletRepo      *transactionTestWalletRepository
	createCalls     int
	recordsBySyncID map[uuid.UUID]*domain.Transaction
}

func (m *transactionTestRepository) CreateAndApply(_ context.Context, input domain.CreateTransactionInput) (*domain.Transaction, error) {
	m.createCalls++

	amount, err := parseAmount(input.Amount)
	if err != nil {
		return nil, err
	}

	sourceWallet, ok := m.walletRepo.wallets[input.WalletID]
	if !ok {
		return nil, pgx.ErrNoRows
	}

	sourceBalance, err := parseAmount(sourceWallet.Balance)
	if err != nil {
		return nil, err
	}
	switch input.Type {
	case transactionTypeExpense, transactionTypeTransfer:
		sourceBalance.Sub(sourceBalance, amount)
	case transactionTypeIncome:
		sourceBalance.Add(sourceBalance, amount)
	}
	sourceWallet.Balance = sourceBalance.FloatString(12)

	if input.Type == transactionTypeTransfer {
		if input.TransferToWalletID == nil || input.ExchangeRate == nil {
			return nil, errors.New("transfer fields are required")
		}
		destWallet, ok := m.walletRepo.wallets[*input.TransferToWalletID]
		if !ok {
			return nil, pgx.ErrNoRows
		}
		destBalance, err := parseAmount(destWallet.Balance)
		if err != nil {
			return nil, err
		}
		rate, err := parseAmount(*input.ExchangeRate)
		if err != nil {
			return nil, err
		}
		credit := destBalance.Add(destBalance, amount.Mul(amount, rate))
		destWallet.Balance = credit.FloatString(12)
	}

	record := &domain.Transaction{
		ID:                 uuid.New(),
		UserID:             input.UserID,
		WalletID:           input.WalletID,
		CategoryID:         input.CategoryID,
		Type:               input.Type,
		Amount:             input.Amount,
		Currency:           input.Currency,
		Notes:              input.Notes,
		Source:             input.Source,
		TransactedAt:       input.TransactedAt,
		CreatedAt:          time.Now().UTC(),
		SyncID:             input.SyncID,
		TransferToWalletID: input.TransferToWalletID,
		ExchangeRate:       input.ExchangeRate,
	}

	if input.SyncID != nil && *input.SyncID != uuid.Nil {
		if m.recordsBySyncID == nil {
			m.recordsBySyncID = make(map[uuid.UUID]*domain.Transaction)
		}
		m.recordsBySyncID[*input.SyncID] = record
	}
	return record, nil
}

func (m *transactionTestRepository) ListByUser(_ context.Context, _ domain.ListTransactionsInput) ([]*domain.Transaction, error) {
	return nil, nil
}

func (m *transactionTestRepository) FindByID(_ context.Context, _ uuid.UUID) (*domain.Transaction, error) {
	return nil, pgx.ErrNoRows
}

func (m *transactionTestRepository) FindBySyncID(_ context.Context, syncID uuid.UUID) (*domain.Transaction, error) {
	if m.recordsBySyncID == nil {
		return nil, pgx.ErrNoRows
	}
	record, ok := m.recordsBySyncID[syncID]
	if !ok {
		return nil, pgx.ErrNoRows
	}
	return record, nil
}

func (m *transactionTestRepository) SoftDelete(_ context.Context, _ uuid.UUID, _ uuid.UUID) error {
	return nil
}

func TestTransactionService_LogTransaction_ExpenseUpdatesWalletBalance(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	walletID := uuid.New()
	walletRepo := &transactionTestWalletRepository{
		wallets: map[uuid.UUID]*domain.Wallet{
			walletID: {ID: walletID, UserID: userID, Balance: "100"},
		},
	}
	txRepo := &transactionTestRepository{walletRepo: walletRepo}
	service, err := NewTransactionService(txRepo, walletRepo)
	if err != nil {
		t.Fatalf("new transaction service: %v", err)
	}

	_, err = service.LogTransaction(context.Background(), LogTransactionInput{
		UserID:       userID,
		WalletID:     walletID,
		Type:         transactionTypeExpense,
		Amount:       "25",
		Currency:     "usd",
		Source:       "manual",
		TransactedAt: time.Now().UTC(),
	})
	if err != nil {
		t.Fatalf("log expense transaction: %v", err)
	}

	assertAmountEquals(t, walletRepo.wallets[walletID].Balance, "75")
}

func TestTransactionService_LogTransaction_IncomeUpdatesWalletBalance(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	walletID := uuid.New()
	walletRepo := &transactionTestWalletRepository{
		wallets: map[uuid.UUID]*domain.Wallet{
			walletID: {ID: walletID, UserID: userID, Balance: "100"},
		},
	}
	txRepo := &transactionTestRepository{walletRepo: walletRepo}
	service, err := NewTransactionService(txRepo, walletRepo)
	if err != nil {
		t.Fatalf("new transaction service: %v", err)
	}

	_, err = service.LogTransaction(context.Background(), LogTransactionInput{
		UserID:       userID,
		WalletID:     walletID,
		Type:         transactionTypeIncome,
		Amount:       "25",
		Currency:     "USD",
		Source:       "manual",
		TransactedAt: time.Now().UTC(),
	})
	if err != nil {
		t.Fatalf("log income transaction: %v", err)
	}

	assertAmountEquals(t, walletRepo.wallets[walletID].Balance, "125")
}

func TestTransactionService_LogTransaction_TransferDebitsAndCreditsWallets(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	sourceWalletID := uuid.New()
	destWalletID := uuid.New()
	walletRepo := &transactionTestWalletRepository{
		wallets: map[uuid.UUID]*domain.Wallet{
			sourceWalletID: {ID: sourceWalletID, UserID: userID, Balance: "100"},
			destWalletID:   {ID: destWalletID, UserID: userID, Balance: "10"},
		},
	}
	txRepo := &transactionTestRepository{walletRepo: walletRepo}
	service, err := NewTransactionService(txRepo, walletRepo)
	if err != nil {
		t.Fatalf("new transaction service: %v", err)
	}

	_, err = service.LogTransaction(context.Background(), LogTransactionInput{
		UserID:             userID,
		WalletID:           sourceWalletID,
		Type:               transactionTypeTransfer,
		Amount:             "20",
		Currency:           "USD",
		Source:             "manual",
		TransactedAt:       time.Now().UTC(),
		TransferToWalletID: &destWalletID,
		ExchangeRate:       "1.5",
	})
	if err != nil {
		t.Fatalf("log transfer transaction: %v", err)
	}

	assertAmountEquals(t, walletRepo.wallets[sourceWalletID].Balance, "80")
	assertAmountEquals(t, walletRepo.wallets[destWalletID].Balance, "40")
}

func TestTransactionService_LogTransaction_DuplicateSyncIDReturnsExisting(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	walletID := uuid.New()
	syncID := uuid.New()
	existingID := uuid.New()

	walletRepo := &transactionTestWalletRepository{
		wallets: map[uuid.UUID]*domain.Wallet{
			walletID: {ID: walletID, UserID: userID, Balance: "100"},
		},
	}
	txRepo := &transactionTestRepository{
		walletRepo: walletRepo,
		recordsBySyncID: map[uuid.UUID]*domain.Transaction{
			syncID: {
				ID:           existingID,
				UserID:       userID,
				WalletID:     walletID,
				Type:         transactionTypeExpense,
				Amount:       "5",
				Currency:     "USD",
				Source:       "manual",
				TransactedAt: time.Now().UTC(),
			},
		},
	}
	service, err := NewTransactionService(txRepo, walletRepo)
	if err != nil {
		t.Fatalf("new transaction service: %v", err)
	}

	record, err := service.LogTransaction(context.Background(), LogTransactionInput{
		UserID:       userID,
		WalletID:     walletID,
		Type:         transactionTypeExpense,
		Amount:       "25",
		Currency:     "USD",
		Source:       "manual",
		TransactedAt: time.Now().UTC(),
		SyncID:       &syncID,
	})
	if err != nil {
		t.Fatalf("log transaction with duplicate sync_id: %v", err)
	}
	if record.ID != existingID {
		t.Fatalf("expected existing transaction id %s, got %s", existingID, record.ID)
	}
	if txRepo.createCalls != 0 {
		t.Fatalf("expected no new transaction creation, got %d calls", txRepo.createCalls)
	}
}

func TestTransactionService_LogTransaction_NegativeAmountRejected(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	walletID := uuid.New()
	walletRepo := &transactionTestWalletRepository{
		wallets: map[uuid.UUID]*domain.Wallet{
			walletID: {ID: walletID, UserID: userID, Balance: "100"},
		},
	}
	txRepo := &transactionTestRepository{walletRepo: walletRepo}
	service, err := NewTransactionService(txRepo, walletRepo)
	if err != nil {
		t.Fatalf("new transaction service: %v", err)
	}

	_, err = service.LogTransaction(context.Background(), LogTransactionInput{
		UserID:       userID,
		WalletID:     walletID,
		Type:         transactionTypeExpense,
		Amount:       "-25",
		Currency:     "USD",
		Source:       "manual",
		TransactedAt: time.Now().UTC(),
	})
	if err == nil {
		t.Fatal("expected validation error for negative amount")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
	if txRepo.createCalls != 0 {
		t.Fatalf("expected no transaction creation, got %d calls", txRepo.createCalls)
	}
}

func assertAmountEquals(t *testing.T, actual, expected string) {
	t.Helper()

	actualAmount, err := parseAmount(actual)
	if err != nil {
		t.Fatalf("parse actual amount: %v", err)
	}
	expectedAmount, err := parseAmount(expected)
	if err != nil {
		t.Fatalf("parse expected amount: %v", err)
	}
	if actualAmount.Cmp(expectedAmount) != 0 {
		t.Fatalf("unexpected amount, got=%s want=%s", actual, expected)
	}
}

