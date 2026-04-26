package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
)

const maxSyncPushChanges = 100

type SyncPushInput struct {
	UserID  uuid.UUID
	Changes []SyncChange
}

type SyncPullInput struct {
	UserID  uuid.UUID
	Since   time.Time
	Limit   int
	Cursor  *SyncPullCursor
}

type SyncPullCursor struct {
	SyncedAt time.Time
	ID       uuid.UUID
}

type SyncChange struct {
	SyncID    string
	Entity    string
	Operation string
	Payload   json.RawMessage
}

type SyncPushResult struct {
	AcceptedIDs []string
	Conflicts   []SyncConflict
}

type SyncPullResult struct {
	Changes    []SyncDelta
	NextCursor *SyncPullCursor
}

type SyncDelta struct {
	ID         uuid.UUID
	EntityType string
	EntityID   uuid.UUID
	Operation  string
	Payload    json.RawMessage
	SyncedAt   time.Time
}

type SyncConflict struct {
	SyncID    string `json:"sync_id"`
	Entity    string `json:"entity"`
	Operation string `json:"operation"`
	Reason    string `json:"reason"`
}

type SyncService struct {
	transactionService syncTransactionService
	goalService        syncGoalService
	budgetService      syncBudgetService
	walletService      syncWalletService
	syncLogRepository  syncLogRepository
}

type syncTransactionService interface {
	CreateTransaction(ctx context.Context, input LogTransactionInput) (*domain.Transaction, bool, error)
	DeleteTransaction(ctx context.Context, input DeleteTransactionInput) error
}

type syncGoalService interface {
	CreateGoal(ctx context.Context, input CreateGoalInput) (*domain.Goal, error)
	UpdateGoal(ctx context.Context, input UpdateGoalInput) error
	Contribute(ctx context.Context, input ContributeGoalInput) (*domain.Goal, error)
	DeleteGoal(ctx context.Context, userID, goalID uuid.UUID) error
}

type syncBudgetService interface {
	UpsertBudget(ctx context.Context, input UpsertBudgetInput) (*domain.Budget, error)
}

type syncWalletService interface {
	CreateWallet(ctx context.Context, input CreateWalletInput) (*domain.Wallet, error)
	UpdateName(ctx context.Context, input UpdateWalletNameInput) error
	Delete(ctx context.Context, input DeleteWalletInput) error
}

type syncLogRepository interface {
	ListByUserSince(ctx context.Context, input SyncLogListInput) ([]SyncLogEntry, error)
}

type SyncLogListInput struct {
	UserID uuid.UUID
	Since  time.Time
	Limit  int
	Cursor *SyncPullCursor
}

type SyncLogEntry struct {
	ID         uuid.UUID
	EntityType string
	EntityID   uuid.UUID
	Operation  string
	Payload    []byte
	SyncedAt   time.Time
}

func NewSyncService(
	transactionService syncTransactionService,
	goalService syncGoalService,
	budgetService syncBudgetService,
	walletService syncWalletService,
	syncLogRepository syncLogRepository,
) (*SyncService, error) {
	if transactionService == nil {
		return nil, fmt.Errorf("%w: transaction service is required", ErrValidation)
	}
	if goalService == nil {
		return nil, fmt.Errorf("%w: goal service is required", ErrValidation)
	}
	if budgetService == nil {
		return nil, fmt.Errorf("%w: budget service is required", ErrValidation)
	}
	if walletService == nil {
		return nil, fmt.Errorf("%w: wallet service is required", ErrValidation)
	}
	if syncLogRepository == nil {
		return nil, fmt.Errorf("%w: sync log repository is required", ErrValidation)
	}

	return &SyncService{
		transactionService: transactionService,
		goalService:        goalService,
		budgetService:      budgetService,
		walletService:      walletService,
		syncLogRepository:  syncLogRepository,
	}, nil
}

func (s *SyncService) Push(ctx context.Context, input SyncPushInput) (*SyncPushResult, error) {
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if len(input.Changes) == 0 {
		return nil, fmt.Errorf("%w: at least one change is required", ErrValidation)
	}
	if len(input.Changes) > maxSyncPushChanges {
		return nil, fmt.Errorf("%w: changes cannot exceed %d", ErrValidation, maxSyncPushChanges)
	}

	result := &SyncPushResult{
		AcceptedIDs: make([]string, 0, len(input.Changes)),
		Conflicts:   make([]SyncConflict, 0),
	}
	seenSyncIDs := make(map[string]struct{}, len(input.Changes))

	for _, change := range input.Changes {
		syncID := strings.TrimSpace(change.SyncID)
		entity := strings.ToLower(strings.TrimSpace(change.Entity))
		operation := strings.ToLower(strings.TrimSpace(change.Operation))

		if syncID == "" {
			result.Conflicts = append(result.Conflicts, SyncConflict{
				SyncID:    "",
				Entity:    entity,
				Operation: operation,
				Reason:    "sync_id is required",
			})
			continue
		}
		if _, err := uuid.Parse(syncID); err != nil {
			result.Conflicts = append(result.Conflicts, SyncConflict{
				SyncID:    syncID,
				Entity:    entity,
				Operation: operation,
				Reason:    "invalid sync_id",
			})
			continue
		}

		if _, exists := seenSyncIDs[syncID]; exists {
			result.Conflicts = append(result.Conflicts, SyncConflict{
				SyncID:    syncID,
				Entity:    entity,
				Operation: operation,
				Reason:    "duplicate sync_id in request",
			})
			continue
		}
		seenSyncIDs[syncID] = struct{}{}

		if err := s.applyChange(ctx, input.UserID, change, syncID, entity, operation); err != nil {
			result.Conflicts = append(result.Conflicts, SyncConflict{
				SyncID:    syncID,
				Entity:    entity,
				Operation: operation,
				Reason:    err.Error(),
			})
			continue
		}
		result.AcceptedIDs = append(result.AcceptedIDs, syncID)
	}

	return result, nil
}

func (s *SyncService) Pull(ctx context.Context, input SyncPullInput) (*SyncPullResult, error) {
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if input.Since.IsZero() {
		return nil, fmt.Errorf("%w: since is required", ErrValidation)
	}

	limit := input.Limit
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	if input.Cursor != nil {
		if input.Cursor.ID == uuid.Nil || input.Cursor.SyncedAt.IsZero() {
			return nil, fmt.Errorf("%w: invalid cursor", ErrValidation)
		}
	}

	rows, err := s.syncLogRepository.ListByUserSince(ctx, SyncLogListInput{
		UserID: input.UserID,
		Since:  input.Since,
		Limit:  limit + 1,
		Cursor: input.Cursor,
	})
	if err != nil {
		return nil, fmt.Errorf("list sync changes: %w", err)
	}

	result := &SyncPullResult{
		Changes: make([]SyncDelta, 0, len(rows)),
	}

	for _, row := range rows {
		result.Changes = append(result.Changes, SyncDelta{
			ID:         row.ID,
			EntityType: row.EntityType,
			EntityID:   row.EntityID,
			Operation:  row.Operation,
			Payload:    json.RawMessage(row.Payload),
			SyncedAt:   row.SyncedAt,
		})
	}

	if len(result.Changes) > limit {
		last := result.Changes[limit-1]
		result.NextCursor = &SyncPullCursor{
			SyncedAt: last.SyncedAt,
			ID:       last.ID,
		}
		result.Changes = result.Changes[:limit]
	}

	return result, nil
}

func (s *SyncService) applyChange(
	ctx context.Context,
	userID uuid.UUID,
	change SyncChange,
	syncID string,
	entity string,
	operation string,
) error {
	switch entity {
	case "transaction":
		return s.applyTransactionChange(ctx, userID, change.Payload, syncID, operation)
	case "goal":
		return s.applyGoalChange(ctx, userID, change.Payload, operation)
	case "budget":
		return s.applyBudgetChange(ctx, userID, change.Payload, operation)
	case "wallet":
		return s.applyWalletChange(ctx, userID, change.Payload, operation)
	default:
		return fmt.Errorf("unsupported entity")
	}
}

func (s *SyncService) applyTransactionChange(
	ctx context.Context,
	userID uuid.UUID,
	payload json.RawMessage,
	syncID string,
	operation string,
) error {
	switch operation {
	case "create":
		var req struct {
			WalletID           string  `json:"wallet_id"`
			CategoryID         *string `json:"category_id"`
			Type               string  `json:"type"`
			Amount             string  `json:"amount"`
			Currency           string  `json:"currency"`
			Notes              string  `json:"notes"`
			Source             string  `json:"source"`
			TransactedAt       string  `json:"transacted_at"`
			TransferToWalletID *string `json:"transfer_to_wallet_id"`
			ExchangeRate       string  `json:"exchange_rate"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			return fmt.Errorf("invalid payload")
		}
		walletID, err := uuid.Parse(strings.TrimSpace(req.WalletID))
		if err != nil {
			return fmt.Errorf("invalid wallet_id")
		}
		var categoryID *uuid.UUID
		if req.CategoryID != nil && strings.TrimSpace(*req.CategoryID) != "" {
			parsed, parseErr := uuid.Parse(strings.TrimSpace(*req.CategoryID))
			if parseErr != nil {
				return fmt.Errorf("invalid category_id")
			}
			categoryID = &parsed
		}
		transactedAt, err := time.Parse(time.RFC3339, strings.TrimSpace(req.TransactedAt))
		if err != nil {
			return fmt.Errorf("invalid transacted_at")
		}
		var transferToWalletID *uuid.UUID
		if req.TransferToWalletID != nil && strings.TrimSpace(*req.TransferToWalletID) != "" {
			parsed, parseErr := uuid.Parse(strings.TrimSpace(*req.TransferToWalletID))
			if parseErr != nil {
				return fmt.Errorf("invalid transfer_to_wallet_id")
			}
			transferToWalletID = &parsed
		}
		syncUUID, _ := uuid.Parse(syncID)
		_, _, err = s.transactionService.CreateTransaction(ctx, LogTransactionInput{
			UserID:             userID,
			WalletID:           walletID,
			CategoryID:         categoryID,
			Type:               strings.TrimSpace(req.Type),
			Amount:             strings.TrimSpace(req.Amount),
			Currency:           strings.TrimSpace(req.Currency),
			Notes:              strings.TrimSpace(req.Notes),
			Source:             strings.TrimSpace(req.Source),
			TransactedAt:       transactedAt,
			SyncID:             &syncUUID,
			TransferToWalletID: transferToWalletID,
			ExchangeRate:       strings.TrimSpace(req.ExchangeRate),
		})
		if err != nil {
			return err
		}
		return nil
	case "delete":
		var req struct {
			TransactionID string `json:"transaction_id"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			return fmt.Errorf("invalid payload")
		}
		transactionID, err := uuid.Parse(strings.TrimSpace(req.TransactionID))
		if err != nil {
			return fmt.Errorf("invalid transaction_id")
		}
		return s.transactionService.DeleteTransaction(ctx, DeleteTransactionInput{
			UserID:        userID,
			TransactionID: transactionID,
		})
	default:
		return fmt.Errorf("unsupported operation")
	}
}

func (s *SyncService) applyGoalChange(ctx context.Context, userID uuid.UUID, payload json.RawMessage, operation string) error {
	switch operation {
	case "create":
		var req struct {
			Name         string `json:"name"`
			Emoji        string `json:"emoji"`
			GoalType     string `json:"goal_type"`
			TargetAmount string `json:"target_amount"`
			Currency     string `json:"currency"`
			SavedAmount  string `json:"saved_amount"`
			Deadline     string `json:"deadline"`
			Priority     int32  `json:"priority"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			return fmt.Errorf("invalid payload")
		}
		deadline, err := time.Parse(time.RFC3339, strings.TrimSpace(req.Deadline))
		if err != nil {
			return fmt.Errorf("invalid deadline")
		}
		_, err = s.goalService.CreateGoal(ctx, CreateGoalInput{
			UserID:       userID,
			Name:         strings.TrimSpace(req.Name),
			Emoji:        strings.TrimSpace(req.Emoji),
			GoalType:     strings.TrimSpace(req.GoalType),
			TargetAmount: strings.TrimSpace(req.TargetAmount),
			Currency:     strings.TrimSpace(req.Currency),
			SavedAmount:  strings.TrimSpace(req.SavedAmount),
			Deadline:     deadline,
			Priority:     req.Priority,
		})
		return err
	case "update":
		var req struct {
			GoalID       string `json:"goal_id"`
			Name         string `json:"name"`
			Emoji        string `json:"emoji"`
			GoalType     string `json:"goal_type"`
			TargetAmount string `json:"target_amount"`
			Currency     string `json:"currency"`
			Deadline     string `json:"deadline"`
			Priority     int32  `json:"priority"`
			IsCompleted  bool   `json:"is_completed"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			return fmt.Errorf("invalid payload")
		}
		goalID, err := uuid.Parse(strings.TrimSpace(req.GoalID))
		if err != nil {
			return fmt.Errorf("invalid goal_id")
		}
		deadline, err := time.Parse(time.RFC3339, strings.TrimSpace(req.Deadline))
		if err != nil {
			return fmt.Errorf("invalid deadline")
		}
		return s.goalService.UpdateGoal(ctx, UpdateGoalInput{
			UserID:       userID,
			GoalID:       goalID,
			Name:         strings.TrimSpace(req.Name),
			Emoji:        strings.TrimSpace(req.Emoji),
			GoalType:     strings.TrimSpace(req.GoalType),
			TargetAmount: strings.TrimSpace(req.TargetAmount),
			Currency:     strings.TrimSpace(req.Currency),
			Deadline:     deadline,
			Priority:     req.Priority,
			IsCompleted:  req.IsCompleted,
		})
	case "contribute":
		var req struct {
			GoalID        string `json:"goal_id"`
			Amount        string `json:"amount"`
			Currency      string `json:"currency"`
			Notes         string `json:"notes"`
			ContributedAt string `json:"contributed_at"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			return fmt.Errorf("invalid payload")
		}
		goalID, err := uuid.Parse(strings.TrimSpace(req.GoalID))
		if err != nil {
			return fmt.Errorf("invalid goal_id")
		}
		var contributedAt time.Time
		if value := strings.TrimSpace(req.ContributedAt); value != "" {
			parsed, parseErr := time.Parse(time.RFC3339, value)
			if parseErr != nil {
				return fmt.Errorf("invalid contributed_at")
			}
			contributedAt = parsed
		}
		_, err = s.goalService.Contribute(ctx, ContributeGoalInput{
			UserID:        userID,
			GoalID:        goalID,
			Amount:        strings.TrimSpace(req.Amount),
			Currency:      strings.TrimSpace(req.Currency),
			Notes:         strings.TrimSpace(req.Notes),
			ContributedAt: contributedAt,
		})
		return err
	case "delete":
		var req struct {
			GoalID string `json:"goal_id"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			return fmt.Errorf("invalid payload")
		}
		goalID, err := uuid.Parse(strings.TrimSpace(req.GoalID))
		if err != nil {
			return fmt.Errorf("invalid goal_id")
		}
		return s.goalService.DeleteGoal(ctx, userID, goalID)
	default:
		return fmt.Errorf("unsupported operation")
	}
}

func (s *SyncService) applyBudgetChange(ctx context.Context, userID uuid.UUID, payload json.RawMessage, operation string) error {
	if operation != "upsert" {
		return fmt.Errorf("unsupported operation")
	}

	var req struct {
		CategoryID string `json:"category_id"`
		Currency   string `json:"currency"`
		Amount     string `json:"amount"`
		Month      int32  `json:"month"`
		Year       int32  `json:"year"`
		Rollover   bool   `json:"rollover"`
	}
	if err := json.Unmarshal(payload, &req); err != nil {
		return fmt.Errorf("invalid payload")
	}
	categoryID, err := uuid.Parse(strings.TrimSpace(req.CategoryID))
	if err != nil {
		return fmt.Errorf("invalid category_id")
	}
	_, err = s.budgetService.UpsertBudget(ctx, UpsertBudgetInput{
		UserID:     userID,
		CategoryID: categoryID,
		Currency:   strings.TrimSpace(req.Currency),
		Amount:     strings.TrimSpace(req.Amount),
		Month:      req.Month,
		Year:       req.Year,
		Rollover:   req.Rollover,
	})
	return err
}

func (s *SyncService) applyWalletChange(ctx context.Context, userID uuid.UUID, payload json.RawMessage, operation string) error {
	switch operation {
	case "create":
		var req struct {
			Name       string `json:"name"`
			Currency   string `json:"currency"`
			WalletType string `json:"wallet_type"`
			Balance    string `json:"balance"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			return fmt.Errorf("invalid payload")
		}
		_, err := s.walletService.CreateWallet(ctx, CreateWalletInput{
			UserID:     userID,
			Name:       strings.TrimSpace(req.Name),
			Currency:   strings.TrimSpace(req.Currency),
			WalletType: strings.TrimSpace(req.WalletType),
			Balance:    strings.TrimSpace(req.Balance),
		})
		return err
	case "update":
		var req struct {
			WalletID string `json:"wallet_id"`
			Name     string `json:"name"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			return fmt.Errorf("invalid payload")
		}
		walletID, err := uuid.Parse(strings.TrimSpace(req.WalletID))
		if err != nil {
			return fmt.Errorf("invalid wallet_id")
		}
		return s.walletService.UpdateName(ctx, UpdateWalletNameInput{
			UserID:   userID,
			WalletID: walletID,
			Name:     strings.TrimSpace(req.Name),
		})
	case "delete":
		var req struct {
			WalletID string `json:"wallet_id"`
		}
		if err := json.Unmarshal(payload, &req); err != nil {
			return fmt.Errorf("invalid payload")
		}
		walletID, err := uuid.Parse(strings.TrimSpace(req.WalletID))
		if err != nil {
			return fmt.Errorf("invalid wallet_id")
		}
		return s.walletService.Delete(ctx, DeleteWalletInput{
			UserID:   userID,
			WalletID: walletID,
		})
	default:
		return fmt.Errorf("unsupported operation")
	}
}
