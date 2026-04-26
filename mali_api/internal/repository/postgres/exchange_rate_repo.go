package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/repository/sqlc"
)

type ExchangeRateRepository struct {
	queries *sqlc.Queries
}

func NewExchangeRateRepository(queries *sqlc.Queries) *ExchangeRateRepository {
	return &ExchangeRateRepository{queries: queries}
}

var _ domain.IExchangeRateRepository = (*ExchangeRateRepository)(nil)

func (r *ExchangeRateRepository) Upsert(ctx context.Context, rate *domain.ExchangeRate) (*domain.ExchangeRate, error) {
	dbUserID, err := pgUUIDFromUUID(rate.UserID)
	if err != nil {
		return nil, fmt.Errorf("parse rate user id: %w", err)
	}
	dbRate, err := numericFromString(rate.Rate)
	if err != nil {
		return nil, fmt.Errorf("parse exchange rate value: %w", err)
	}
	dbValidAt, err := timestamptzFromTime(rate.ValidAt)
	if err != nil {
		return nil, fmt.Errorf("parse exchange rate valid_at: %w", err)
	}

	row, err := r.queries.UpsertExchangeRate(ctx, sqlc.UpsertExchangeRateParams{
		Rate:         dbRate,
		UserID:       dbUserID,
		FromCurrency: rate.FromCurrency,
		ToCurrency:   rate.ToCurrency,
		Source:       rate.Source,
		ValidAt:      dbValidAt,
	})
	if err != nil {
		return nil, fmt.Errorf("upsert exchange rate: %w", err)
	}

	return mapSQLCExchangeRateToDomain(
		sqlc.ExchangeRate{
			ID:           row.ID,
			UserID:       row.UserID,
			FromCurrency: row.FromCurrency,
			ToCurrency:   row.ToCurrency,
			Rate:         row.Rate,
			Source:       row.Source,
			ValidAt:      row.ValidAt,
		},
	)
}

func (r *ExchangeRateRepository) GetLatestForPair(
	ctx context.Context,
	userID uuid.UUID,
	fromCurrency, toCurrency string,
) (*domain.ExchangeRate, error) {
	dbUserID, err := pgUUIDFromUUID(userID)
	if err != nil {
		return nil, fmt.Errorf("parse user id: %w", err)
	}

	row, err := r.queries.GetLatestRateForPair(ctx, sqlc.GetLatestRateForPairParams{
		UserID:       dbUserID,
		FromCurrency: fromCurrency,
		ToCurrency:   toCurrency,
	})
	if err != nil {
		return nil, fmt.Errorf("get latest rate for pair: %w", err)
	}

	return mapSQLCExchangeRateToDomain(row)
}

func (r *ExchangeRateRepository) ListByUser(ctx context.Context, userID uuid.UUID) ([]*domain.ExchangeRate, error) {
	dbUserID, err := pgUUIDFromUUID(userID)
	if err != nil {
		return nil, fmt.Errorf("parse user id: %w", err)
	}

	rows, err := r.queries.GetAllRatesForUser(ctx, dbUserID)
	if err != nil {
		return nil, fmt.Errorf("list rates by user: %w", err)
	}

	out := make([]*domain.ExchangeRate, 0, len(rows))
	for _, row := range rows {
		mapped, mapErr := mapSQLCExchangeRateToDomain(row)
		if mapErr != nil {
			return nil, fmt.Errorf("map exchange rate: %w", mapErr)
		}
		out = append(out, mapped)
	}
	return out, nil
}

func mapSQLCExchangeRateToDomain(rate sqlc.ExchangeRate) (*domain.ExchangeRate, error) {
	id, err := uuidFromPG(rate.ID)
	if err != nil {
		return nil, fmt.Errorf("parse id: %w", err)
	}
	userID, err := uuidFromPG(rate.UserID)
	if err != nil {
		return nil, fmt.Errorf("parse user_id: %w", err)
	}
	value, err := stringFromNumeric(rate.Rate)
	if err != nil {
		return nil, fmt.Errorf("parse rate: %w", err)
	}
	validAt, err := timeFromPG(rate.ValidAt)
	if err != nil {
		return nil, fmt.Errorf("parse valid_at: %w", err)
	}

	return &domain.ExchangeRate{
		ID:           id,
		UserID:       userID,
		FromCurrency: rate.FromCurrency,
		ToCurrency:   rate.ToCurrency,
		Rate:         value,
		Source:       rate.Source,
		ValidAt:      validAt,
	}, nil
}

func timestamptzFromTime(value time.Time) (pgtype.Timestamptz, error) {
	var out pgtype.Timestamptz
	if err := out.Scan(value.UTC()); err != nil {
		return pgtype.Timestamptz{}, err
	}
	return out, nil
}

