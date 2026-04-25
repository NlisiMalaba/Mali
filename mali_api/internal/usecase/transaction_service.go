package usecase

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/mali-app/mali_api/internal/domain"
)

const (
	transactionTypeExpense  = "expense"
	transactionTypeIncome   = "income"
	transactionTypeTransfer = "transfer"
)

type LogTransactionInput struct {
	UserID             uuid.UUID
	WalletID           uuid.UUID
	CategoryID         *uuid.UUID
	Type               string
	Amount             string
	Currency           string
	Notes              string
	Source             string
	TransactedAt       time.Time
	SyncID             *uuid.UUID
	TransferToWalletID *uuid.UUID
	ExchangeRate       string
}

type TransactionListCursor struct {
	TransactedAt time.Time
	ID           uuid.UUID
}

type ListTransactionsInput struct {
	UserID     uuid.UUID
	WalletID   *uuid.UUID
	CategoryID *uuid.UUID
	DateFrom   *time.Time
	DateTo     *time.Time
	Type       string
	Limit      int
	Sort       string
	Cursor     *TransactionListCursor
}

type ListTransactionsOutput struct {
	Transactions []*domain.Transaction
	NextCursor   *TransactionListCursor
}

type GetTransactionInput struct {
	UserID        uuid.UUID
	TransactionID uuid.UUID
}

type DeleteTransactionInput struct {
	UserID        uuid.UUID
	TransactionID uuid.UUID
}

type TransactionService struct {
	transactionRepository domain.ITransactionRepository
	walletRepository      domain.IWalletRepository
}

func NewTransactionService(
	transactionRepository domain.ITransactionRepository,
	walletRepository domain.IWalletRepository,
) (*TransactionService, error) {
	if transactionRepository == nil {
		return nil, fmt.Errorf("%w: transaction repository is required", ErrValidation)
	}
	if walletRepository == nil {
		return nil, fmt.Errorf("%w: wallet repository is required", ErrValidation)
	}

	return &TransactionService{
		transactionRepository: transactionRepository,
		walletRepository:      walletRepository,
	}, nil
}

func (s *TransactionService) LogTransaction(ctx context.Context, input LogTransactionInput) (*domain.Transaction, error) {
	if s.transactionRepository == nil || s.walletRepository == nil {
		return nil, fmt.Errorf("transaction service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	if input.SyncID != nil && *input.SyncID != uuid.Nil {
		existing, err := s.transactionRepository.FindBySyncID(ctx, *input.SyncID)
		if err == nil {
			if existing.UserID != input.UserID {
				return nil, fmt.Errorf("%w: sync_id already exists", ErrValidation)
			}
			return existing, nil
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("find transaction by sync_id: %w", err)
		}
	}

	if input.WalletID == uuid.Nil {
		return nil, fmt.Errorf("%w: wallet_id is required", ErrValidation)
	}

	txType := strings.ToLower(strings.TrimSpace(input.Type))
	if txType != transactionTypeExpense && txType != transactionTypeIncome && txType != transactionTypeTransfer {
		return nil, fmt.Errorf("%w: type must be income, expense, or transfer", ErrValidation)
	}

	amount := normalizeAmount(input.Amount)
	amountValue, err := parseAmount(amount)
	if err != nil {
		return nil, fmt.Errorf("%w: invalid transaction amount", ErrValidation)
	}
	if amountValue.Sign() <= 0 {
		return nil, fmt.Errorf("%w: amount must be greater than 0", ErrValidation)
	}

	currency := normalizeCurrencyCode(input.Currency)
	if currency == "" {
		return nil, fmt.Errorf("%w: currency is required", ErrValidation)
	}

	source := strings.TrimSpace(input.Source)
	if source == "" {
		return nil, fmt.Errorf("%w: source is required", ErrValidation)
	}

	if input.TransactedAt.IsZero() {
		return nil, fmt.Errorf("%w: transacted_at is required", ErrValidation)
	}

	notes := strings.TrimSpace(input.Notes)
	var normalizedNotes *string
	if notes != "" {
		normalizedNotes = &notes
	}

	if _, err := s.getOwnedWallet(ctx, input.UserID, input.WalletID); err != nil {
		return nil, err
	}

	var normalizedExchangeRate *string
	transferToWalletID := input.TransferToWalletID
	if txType == transactionTypeTransfer {
		if transferToWalletID == nil || *transferToWalletID == uuid.Nil {
			return nil, fmt.Errorf("%w: transfer_to_wallet_id is required for transfer", ErrValidation)
		}
		if *transferToWalletID == input.WalletID {
			return nil, fmt.Errorf("%w: transfer wallets must be different", ErrValidation)
		}
		if _, err := s.getOwnedWallet(ctx, input.UserID, *transferToWalletID); err != nil {
			return nil, err
		}

		rate := normalizeAmount(input.ExchangeRate)
		rateValue, err := parseAmount(rate)
		if err != nil {
			return nil, fmt.Errorf("%w: invalid exchange_rate", ErrValidation)
		}
		if rateValue.Sign() <= 0 {
			return nil, fmt.Errorf("%w: exchange_rate must be greater than 0", ErrValidation)
		}
		normalizedExchangeRate = &rate
	} else {
		transferToWalletID = nil
	}

	created, err := s.transactionRepository.CreateAndApply(ctx, domain.CreateTransactionInput{
		UserID:             input.UserID,
		WalletID:           input.WalletID,
		CategoryID:         input.CategoryID,
		Type:               txType,
		Amount:             amount,
		Currency:           currency,
		Notes:              normalizedNotes,
		Source:             source,
		TransactedAt:       input.TransactedAt,
		SyncID:             input.SyncID,
		TransferToWalletID: transferToWalletID,
		ExchangeRate:       normalizedExchangeRate,
	})
	if err != nil {
		return nil, fmt.Errorf("log transaction: %w", err)
	}

	return created, nil
}

func (s *TransactionService) ListTransactions(ctx context.Context, input ListTransactionsInput) (*ListTransactionsOutput, error) {
	if s.transactionRepository == nil || s.walletRepository == nil {
		return nil, fmt.Errorf("transaction service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	if input.WalletID != nil {
		if *input.WalletID == uuid.Nil {
			return nil, fmt.Errorf("%w: wallet_id is invalid", ErrValidation)
		}
		if _, err := s.getOwnedWallet(ctx, input.UserID, *input.WalletID); err != nil {
			return nil, err
		}
	}

	if input.DateFrom != nil && input.DateTo != nil && input.DateFrom.After(*input.DateTo) {
		return nil, fmt.Errorf("%w: date_from cannot be after date_to", ErrValidation)
	}

	limit := input.Limit
	if limit <= 0 {
		limit = 50
	}
	if limit > 200 {
		limit = 200
	}

	sortOrder := domain.TransactionSortDesc
	switch strings.ToLower(strings.TrimSpace(input.Sort)) {
	case "", string(domain.TransactionSortDesc):
		sortOrder = domain.TransactionSortDesc
	case string(domain.TransactionSortAsc):
		sortOrder = domain.TransactionSortAsc
	default:
		return nil, fmt.Errorf("%w: sort must be asc or desc", ErrValidation)
	}

	var txType *string
	normalizedType := strings.ToLower(strings.TrimSpace(input.Type))
	if normalizedType != "" {
		if normalizedType != transactionTypeExpense && normalizedType != transactionTypeIncome && normalizedType != transactionTypeTransfer {
			return nil, fmt.Errorf("%w: type must be income, expense, or transfer", ErrValidation)
		}
		txType = &normalizedType
	}

	var cursor *domain.TransactionCursor
	if input.Cursor != nil {
		if input.Cursor.ID == uuid.Nil || input.Cursor.TransactedAt.IsZero() {
			return nil, fmt.Errorf("%w: invalid cursor", ErrValidation)
		}
		cursor = &domain.TransactionCursor{
			TransactedAt: input.Cursor.TransactedAt,
			ID:           input.Cursor.ID,
		}
	}

	rows, err := s.transactionRepository.ListByUser(ctx, domain.ListTransactionsInput{
		UserID:     input.UserID,
		WalletID:   input.WalletID,
		CategoryID: input.CategoryID,
		DateFrom:   input.DateFrom,
		DateTo:     input.DateTo,
		Type:       txType,
		Limit:      limit + 1, // fetch one extra row to determine next cursor
		SortOrder:  sortOrder,
		Cursor:     cursor,
	})
	if err != nil {
		return nil, fmt.Errorf("list transactions: %w", err)
	}

	output := &ListTransactionsOutput{
		Transactions: rows,
	}
	if len(rows) > limit {
		next := rows[limit-1]
		output.NextCursor = &TransactionListCursor{
			TransactedAt: next.TransactedAt,
			ID:           next.ID,
		}
		output.Transactions = rows[:limit]
	}

	return output, nil
}

func (s *TransactionService) CreateTransaction(ctx context.Context, input LogTransactionInput) (*domain.Transaction, bool, error) {
	var existing *domain.Transaction
	if input.SyncID != nil && *input.SyncID != uuid.Nil {
		record, err := s.transactionRepository.FindBySyncID(ctx, *input.SyncID)
		if err == nil {
			existing = record
		} else if !errors.Is(err, pgx.ErrNoRows) {
			return nil, false, fmt.Errorf("find transaction by sync_id: %w", err)
		}
	}

	if existing != nil {
		if existing.UserID != input.UserID {
			return nil, false, fmt.Errorf("%w: sync_id already exists", ErrValidation)
		}
		return existing, true, nil
	}

	created, err := s.LogTransaction(ctx, input)
	if err != nil {
		return nil, false, err
	}
	return created, false, nil
}

func (s *TransactionService) GetTransaction(ctx context.Context, input GetTransactionInput) (*domain.Transaction, error) {
	if s.transactionRepository == nil {
		return nil, fmt.Errorf("transaction service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if input.TransactionID == uuid.Nil {
		return nil, fmt.Errorf("%w: transaction_id is required", ErrValidation)
	}

	tx, err := s.transactionRepository.FindByID(ctx, input.TransactionID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("%w: transaction not found", ErrValidation)
		}
		return nil, fmt.Errorf("find transaction by id: %w", err)
	}
	if tx.UserID != input.UserID || tx.IsDeleted {
		return nil, fmt.Errorf("%w: transaction not found", ErrValidation)
	}
	return tx, nil
}

func (s *TransactionService) DeleteTransaction(ctx context.Context, input DeleteTransactionInput) error {
	if s.transactionRepository == nil {
		return fmt.Errorf("transaction service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if input.TransactionID == uuid.Nil {
		return fmt.Errorf("%w: transaction_id is required", ErrValidation)
	}

	if err := s.transactionRepository.SoftDelete(ctx, input.UserID, input.TransactionID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return fmt.Errorf("%w: transaction not found", ErrValidation)
		}
		return fmt.Errorf("delete transaction: %w", err)
	}
	return nil
}

func (s *TransactionService) getOwnedWallet(ctx context.Context, userID, walletID uuid.UUID) (*domain.Wallet, error) {
	wallet, err := s.walletRepository.FindByID(ctx, walletID)
	if err != nil {
		if isNotFound(err) {
			return nil, fmt.Errorf("%w: wallet not found", ErrValidation)
		}
		return nil, fmt.Errorf("find wallet by id: %w", err)
	}
	if wallet.UserID != userID {
		return nil, fmt.Errorf("%w: wallet not found", ErrValidation)
	}
	return wallet, nil
}

