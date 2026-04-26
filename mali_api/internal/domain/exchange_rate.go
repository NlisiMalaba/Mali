package domain

import (
	"context"
	"time"

	"github.com/google/uuid"
)

type ExchangeRate struct {
	ID           uuid.UUID
	UserID       uuid.UUID
	FromCurrency string
	ToCurrency   string
	Rate         string
	Source       string
	ValidAt      time.Time
}

type IExchangeRateRepository interface {
	Upsert(ctx context.Context, rate *ExchangeRate) (*ExchangeRate, error)
	GetLatestForPair(ctx context.Context, userID uuid.UUID, fromCurrency, toCurrency string) (*ExchangeRate, error)
	ListByUser(ctx context.Context, userID uuid.UUID) ([]*ExchangeRate, error)
}

