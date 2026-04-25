package domain

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type Transaction struct {
	ID                 uuid.UUID
	UserID             uuid.UUID
	WalletID           uuid.UUID
	CategoryID         *uuid.UUID
	Type               string
	Amount             string
	Currency           string
	Notes              *string
	Source             string
	TransactedAt       time.Time
	CreatedAt          time.Time
	IsDeleted          bool
	SyncID             *uuid.UUID
	TransferToWalletID *uuid.UUID
	ExchangeRate       *string
}

type CreateTransactionInput struct {
	UserID             uuid.UUID
	WalletID           uuid.UUID
	CategoryID         *uuid.UUID
	Type               string
	Amount             string
	Currency           string
	Notes              *string
	Source             string
	TransactedAt       time.Time
	SyncID             *uuid.UUID
	TransferToWalletID *uuid.UUID
	ExchangeRate       *string
}

type ITransactionRepository interface {
	CreateAndApply(ctx context.Context, input CreateTransactionInput) (*Transaction, error)
	ListByUser(ctx context.Context, input ListTransactionsInput) ([]*Transaction, error)
	FindByID(ctx context.Context, id uuid.UUID) (*Transaction, error)
	FindBySyncID(ctx context.Context, syncID uuid.UUID) (*Transaction, error)
	SoftDelete(ctx context.Context, userID, id uuid.UUID) error
}

type TransactionSortOrder string

const (
	TransactionSortDesc TransactionSortOrder = "desc"
	TransactionSortAsc  TransactionSortOrder = "asc"
)

type TransactionCursor struct {
	TransactedAt time.Time
	ID           uuid.UUID
}

type ListTransactionsInput struct {
	UserID     uuid.UUID
	WalletID   *uuid.UUID
	CategoryID *uuid.UUID
	DateFrom   *time.Time
	DateTo     *time.Time
	Type       *string
	Limit      int
	SortOrder  TransactionSortOrder
	Cursor     *TransactionCursor
}

