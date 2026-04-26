package usecase

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
)

type mockSyncTransactionService struct {
	createCalls int
	deleteCalls int
}

func (m *mockSyncTransactionService) CreateTransaction(ctx context.Context, input LogTransactionInput) (*domain.Transaction, bool, error) {
	m.createCalls++
	return &domain.Transaction{ID: uuid.New(), UserID: input.UserID}, false, nil
}

func (m *mockSyncTransactionService) DeleteTransaction(context.Context, DeleteTransactionInput) error {
	m.deleteCalls++
	return nil
}

type mockSyncGoalService struct{}

func (m *mockSyncGoalService) CreateGoal(context.Context, CreateGoalInput) (*domain.Goal, error) {
	return &domain.Goal{ID: uuid.New()}, nil
}
func (m *mockSyncGoalService) UpdateGoal(context.Context, UpdateGoalInput) error { return nil }
func (m *mockSyncGoalService) Contribute(context.Context, ContributeGoalInput) (*domain.Goal, error) {
	return &domain.Goal{ID: uuid.New()}, nil
}
func (m *mockSyncGoalService) DeleteGoal(context.Context, uuid.UUID, uuid.UUID) error { return nil }

type mockSyncBudgetService struct{}

func (m *mockSyncBudgetService) UpsertBudget(context.Context, UpsertBudgetInput) (*domain.Budget, error) {
	return &domain.Budget{ID: uuid.New()}, nil
}

type mockSyncWalletService struct{}

func (m *mockSyncWalletService) CreateWallet(context.Context, CreateWalletInput) (*domain.Wallet, error) {
	return &domain.Wallet{ID: uuid.New()}, nil
}
func (m *mockSyncWalletService) UpdateName(context.Context, UpdateWalletNameInput) error { return nil }
func (m *mockSyncWalletService) Delete(context.Context, DeleteWalletInput) error          { return nil }

type mockSyncLogRepository struct {
	rows []SyncLogEntry
}

func (m *mockSyncLogRepository) ListByUserSince(context.Context, SyncLogListInput) ([]SyncLogEntry, error) {
	return m.rows, nil
}

func TestSyncServicePush_RejectsBatchOverLimit(t *testing.T) {
	service, err := NewSyncService(
		&mockSyncTransactionService{},
		&mockSyncGoalService{},
		&mockSyncBudgetService{},
		&mockSyncWalletService{},
		&mockSyncLogRepository{},
	)
	if err != nil {
		t.Fatalf("NewSyncService() error = %v", err)
	}

	changes := make([]SyncChange, 0, maxSyncPushChanges+1)
	for i := 0; i <= maxSyncPushChanges; i++ {
		changes = append(changes, SyncChange{
			SyncID:    uuid.NewString(),
			Entity:    "wallet",
			Operation: "create",
			Payload:   json.RawMessage(`{"name":"Cash","currency":"USD","wallet_type":"cash","balance":"0"}`),
		})
	}

	_, err = service.Push(context.Background(), SyncPushInput{
		UserID:  uuid.New(),
		Changes: changes,
	})
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestSyncServicePush_CollectsAcceptedIDsAndConflicts(t *testing.T) {
	transactionService := &mockSyncTransactionService{}
	service, err := NewSyncService(
		transactionService,
		&mockSyncGoalService{},
		&mockSyncBudgetService{},
		&mockSyncWalletService{},
		&mockSyncLogRepository{},
	)
	if err != nil {
		t.Fatalf("NewSyncService() error = %v", err)
	}

	changeID := uuid.NewString()
	walletID := uuid.NewString()
	result, err := service.Push(context.Background(), SyncPushInput{
		UserID: uuid.New(),
		Changes: []SyncChange{
			{
				SyncID:    changeID,
				Entity:    "transaction",
				Operation: "create",
				Payload: json.RawMessage(`{
					"wallet_id":"` + walletID + `",
					"type":"expense",
					"amount":"10",
					"currency":"USD",
					"source":"mobile",
					"transacted_at":"` + time.Now().UTC().Format(time.RFC3339) + `"
				}`),
			},
			{
				SyncID:    changeID,
				Entity:    "wallet",
				Operation: "create",
				Payload:   json.RawMessage(`{"name":"Cash","currency":"USD","wallet_type":"cash","balance":"0"}`),
			},
			{
				SyncID:    uuid.NewString(),
				Entity:    "unknown",
				Operation: "create",
				Payload:   json.RawMessage(`{}`),
			},
		},
	})
	if err != nil {
		t.Fatalf("Push() error = %v", err)
	}

	if got, want := len(result.AcceptedIDs), 1; got != want {
		t.Fatalf("len(AcceptedIDs) = %d, want %d", got, want)
	}
	if got, want := len(result.Conflicts), 2; got != want {
		t.Fatalf("len(Conflicts) = %d, want %d", got, want)
	}
	if transactionService.createCalls != 1 {
		t.Fatalf("transaction create calls = %d, want 1", transactionService.createCalls)
	}
}

func TestSyncServicePull_ReturnsPaginatedDelta(t *testing.T) {
	firstID := uuid.New()
	secondID := uuid.New()
	thirdID := uuid.New()
	now := time.Now().UTC()

	service, err := NewSyncService(
		&mockSyncTransactionService{},
		&mockSyncGoalService{},
		&mockSyncBudgetService{},
		&mockSyncWalletService{},
		&mockSyncLogRepository{
			rows: []SyncLogEntry{
				{ID: firstID, EntityType: "wallet", EntityID: uuid.New(), Operation: "create", Payload: []byte(`{"a":1}`), SyncedAt: now},
				{ID: secondID, EntityType: "budget", EntityID: uuid.New(), Operation: "upsert", Payload: []byte(`{"b":2}`), SyncedAt: now.Add(time.Second)},
				{ID: thirdID, EntityType: "goal", EntityID: uuid.New(), Operation: "update", Payload: []byte(`{"c":3}`), SyncedAt: now.Add(2 * time.Second)},
			},
		},
	)
	if err != nil {
		t.Fatalf("NewSyncService() error = %v", err)
	}

	result, err := service.Pull(context.Background(), SyncPullInput{
		UserID: uuid.New(),
		Since:  now.Add(-time.Hour),
		Limit:  2,
	})
	if err != nil {
		t.Fatalf("Pull() error = %v", err)
	}
	if got, want := len(result.Changes), 2; got != want {
		t.Fatalf("len(result.Changes) = %d, want %d", got, want)
	}
	if result.NextCursor == nil {
		t.Fatalf("expected next cursor")
	}
	if result.NextCursor.ID != secondID {
		t.Fatalf("next cursor id = %s, want %s", result.NextCursor.ID, secondID)
	}
}
