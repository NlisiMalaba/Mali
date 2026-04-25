package usecase

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/mali-app/mali_api/internal/domain"
)

type mockWalletRepository struct {
	wallets               map[uuid.UUID]*domain.Wallet
	lastListUserID        uuid.UUID
	lastUpdatedBalanceID  uuid.UUID
	lastUpdatedBalance    string
	lastDeletedWalletID   uuid.UUID
}

func (m *mockWalletRepository) Create(_ context.Context, wallet *domain.Wallet) (*domain.Wallet, error) {
	if m.wallets == nil {
		m.wallets = make(map[uuid.UUID]*domain.Wallet)
	}

	created := *wallet
	if created.ID == uuid.Nil {
		created.ID = uuid.New()
	}
	m.wallets[created.ID] = &created
	return &created, nil
}

func (m *mockWalletRepository) ListByUser(_ context.Context, userID uuid.UUID) ([]*domain.Wallet, error) {
	m.lastListUserID = userID

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

func (m *mockWalletRepository) FindByID(_ context.Context, id uuid.UUID) (*domain.Wallet, error) {
	wallet, ok := m.wallets[id]
	if !ok {
		return nil, pgx.ErrNoRows
	}
	copied := *wallet
	return &copied, nil
}

func (m *mockWalletRepository) UpdateBalance(_ context.Context, id uuid.UUID, balance string) error {
	wallet, ok := m.wallets[id]
	if !ok {
		return pgx.ErrNoRows
	}
	wallet.Balance = balance
	m.lastUpdatedBalanceID = id
	m.lastUpdatedBalance = balance
	return nil
}

func (m *mockWalletRepository) UpdateName(_ context.Context, id uuid.UUID, name string) error {
	wallet, ok := m.wallets[id]
	if !ok {
		return pgx.ErrNoRows
	}
	wallet.Name = name
	return nil
}

func (m *mockWalletRepository) SoftDelete(_ context.Context, id uuid.UUID) error {
	wallet, ok := m.wallets[id]
	if !ok {
		return pgx.ErrNoRows
	}
	wallet.IsActive = false
	m.lastDeletedWalletID = id
	return nil
}

func TestWalletService_CreateWallet_Success(t *testing.T) {
	t.Parallel()

	repo := &mockWalletRepository{}
	service, err := NewWalletService(repo, []string{"USD", "KES"})
	if err != nil {
		t.Fatalf("create wallet service: %v", err)
	}

	userID := uuid.New()
	created, err := service.CreateWallet(context.Background(), CreateWalletInput{
		UserID:     userID,
		Name:       "Main Wallet",
		Currency:   "usd",
		WalletType: "cash",
		Balance:    "10.50",
	})
	if err != nil {
		t.Fatalf("create wallet: %v", err)
	}

	if created.UserID != userID {
		t.Fatalf("unexpected user id, got=%s want=%s", created.UserID, userID)
	}
	if created.Currency != "USD" {
		t.Fatalf("expected normalized currency USD, got=%s", created.Currency)
	}
	if created.Balance != "10.50" {
		t.Fatalf("unexpected balance, got=%s", created.Balance)
	}
	if !created.IsActive {
		t.Fatal("expected new wallet to be active")
	}
}

func TestWalletService_ListWallets_ReturnsOnlyCurrentUserWallets(t *testing.T) {
	t.Parallel()

	userA := uuid.New()
	userB := uuid.New()
	repo := &mockWalletRepository{
		wallets: map[uuid.UUID]*domain.Wallet{
			uuid.New(): {ID: uuid.New(), UserID: userA, Name: "A1", Currency: "USD", WalletType: "cash", Balance: "10", IsActive: true},
			uuid.New(): {ID: uuid.New(), UserID: userA, Name: "A2", Currency: "USD", WalletType: "bank", Balance: "20", IsActive: true},
			uuid.New(): {ID: uuid.New(), UserID: userB, Name: "B1", Currency: "KES", WalletType: "cash", Balance: "30", IsActive: true},
		},
	}
	service, err := NewWalletService(repo, []string{"USD", "KES"})
	if err != nil {
		t.Fatalf("create wallet service: %v", err)
	}

	out, err := service.ListWallets(context.Background(), userA)
	if err != nil {
		t.Fatalf("list wallets: %v", err)
	}

	if repo.lastListUserID != userA {
		t.Fatalf("expected list filter by userA, got=%s", repo.lastListUserID)
	}
	if len(out) != 2 {
		t.Fatalf("expected 2 wallets for userA, got=%d", len(out))
	}
	for _, wallet := range out {
		if wallet.UserID != userA {
			t.Fatalf("expected only userA wallets, got wallet for %s", wallet.UserID)
		}
	}
}

func TestWalletService_Delete_NonZeroBalanceReturnsValidationError(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	walletID := uuid.New()
	repo := &mockWalletRepository{
		wallets: map[uuid.UUID]*domain.Wallet{
			walletID: {ID: walletID, UserID: userID, Name: "Main", Currency: "USD", WalletType: "cash", Balance: "1.00", IsActive: true},
		},
	}
	service, err := NewWalletService(repo, []string{"USD"})
	if err != nil {
		t.Fatalf("create wallet service: %v", err)
	}

	err = service.Delete(context.Background(), DeleteWalletInput{
		UserID:   userID,
		WalletID: walletID,
	})
	if err == nil {
		t.Fatal("expected validation error")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got: %v", err)
	}
	if repo.lastDeletedWalletID != uuid.Nil {
		t.Fatal("wallet should not be deleted when balance is non-zero")
	}
}

func TestWalletService_UpdateBalance_UpdatesCorrectly(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	walletID := uuid.New()
	repo := &mockWalletRepository{
		wallets: map[uuid.UUID]*domain.Wallet{
			walletID: {ID: walletID, UserID: userID, Name: "Main", Currency: "USD", WalletType: "cash", Balance: "1.00", IsActive: true},
		},
	}
	service, err := NewWalletService(repo, []string{"USD"})
	if err != nil {
		t.Fatalf("create wallet service: %v", err)
	}

	err = service.UpdateBalance(context.Background(), UpdateBalanceInput{
		UserID:   userID,
		WalletID: walletID,
		Balance:  "42.25",
	})
	if err != nil {
		t.Fatalf("update balance: %v", err)
	}

	if repo.lastUpdatedBalanceID != walletID {
		t.Fatalf("unexpected updated wallet id, got=%s want=%s", repo.lastUpdatedBalanceID, walletID)
	}
	if repo.lastUpdatedBalance != "42.25" {
		t.Fatalf("unexpected updated balance, got=%s", repo.lastUpdatedBalance)
	}
	if repo.wallets[walletID].Balance != "42.25" {
		t.Fatalf("expected persisted balance 42.25, got=%s", repo.wallets[walletID].Balance)
	}
}

func TestWalletService_UpdateBalance_OtherUsersWalletReturnsValidationError(t *testing.T) {
	t.Parallel()

	ownerID := uuid.New()
	otherUserID := uuid.New()
	walletID := uuid.New()
	repo := &mockWalletRepository{
		wallets: map[uuid.UUID]*domain.Wallet{
			walletID: {ID: walletID, UserID: ownerID, Name: "Owner Wallet", Currency: "USD", WalletType: "cash", Balance: "9.00", IsActive: true},
		},
	}
	service, err := NewWalletService(repo, []string{"USD"})
	if err != nil {
		t.Fatalf("create wallet service: %v", err)
	}

	err = service.UpdateBalance(context.Background(), UpdateBalanceInput{
		UserID:   otherUserID,
		WalletID: walletID,
		Balance:  "11.00",
	})
	if err == nil {
		t.Fatal("expected validation error for cross-user wallet access")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got: %v", err)
	}
	if repo.wallets[walletID].Balance != "9.00" {
		t.Fatalf("balance should remain unchanged for unauthorized update, got=%s", repo.wallets[walletID].Balance)
	}
}

