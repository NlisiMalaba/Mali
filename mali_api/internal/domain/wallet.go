package domain

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type Wallet struct {
	ID         uuid.UUID
	UserID     uuid.UUID
	Name       string
	Currency   string
	WalletType string
	Balance    string
	IsActive   bool
	CreatedAt  time.Time
}

type IWalletRepository interface {
	Create(ctx context.Context, wallet *Wallet) (*Wallet, error)
	ListByUser(ctx context.Context, userID uuid.UUID) ([]*Wallet, error)
	FindByID(ctx context.Context, id uuid.UUID) (*Wallet, error)
	UpdateBalance(ctx context.Context, id uuid.UUID, balance string) error
	UpdateName(ctx context.Context, id uuid.UUID, name string) error
	SoftDelete(ctx context.Context, id uuid.UUID) error
}

