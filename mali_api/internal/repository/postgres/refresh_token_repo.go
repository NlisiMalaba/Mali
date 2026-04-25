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

type RefreshTokenRepository struct {
	queries *sqlc.Queries
}

func NewRefreshTokenRepository(queries *sqlc.Queries) *RefreshTokenRepository {
	return &RefreshTokenRepository{queries: queries}
}

var _ domain.IRefreshTokenRepository = (*RefreshTokenRepository)(nil)

func (r *RefreshTokenRepository) Create(ctx context.Context, token *domain.RefreshToken) error {
	dbID, err := pgUUIDFromUUID(token.ID)
	if err != nil {
		return fmt.Errorf("parse refresh token id: %w", err)
	}
	dbUserID, err := pgUUIDFromUUID(token.UserID)
	if err != nil {
		return fmt.Errorf("parse refresh token user id: %w", err)
	}

	err = r.queries.CreateRefreshToken(ctx, sqlc.CreateRefreshTokenParams{
		ID:        dbID,
		UserID:    dbUserID,
		TokenHash: token.TokenHash,
		DeviceID:  token.DeviceID,
		ExpiresAt: pgTimestamptzFromTime(token.ExpiresAt),
		RevokedAt: pgTimestamptzFromPtr(token.RevokedAt),
		CreatedAt: pgTimestamptzFromTime(token.CreatedAt),
	})
	if err != nil {
		return fmt.Errorf("create refresh token: %w", err)
	}

	return nil
}

func (r *RefreshTokenRepository) FindByTokenHash(ctx context.Context, tokenHash string) (*domain.RefreshToken, error) {
	record, err := r.queries.GetRefreshTokenByHash(ctx, tokenHash)
	if err != nil {
		return nil, fmt.Errorf("find refresh token by hash: %w", err)
	}

	mapped, err := mapSQLCRefreshTokenToDomain(record)
	if err != nil {
		return nil, fmt.Errorf("map refresh token: %w", err)
	}

	return mapped, nil
}

func (r *RefreshTokenRepository) RevokeByID(ctx context.Context, id uuid.UUID, revokedAt time.Time) error {
	dbID, err := pgUUIDFromUUID(id)
	if err != nil {
		return fmt.Errorf("parse refresh token id: %w", err)
	}

	err = r.queries.RevokeRefreshTokenByID(ctx, sqlc.RevokeRefreshTokenByIDParams{
		ID:        dbID,
		RevokedAt: pgTimestamptzFromTime(revokedAt),
	})
	if err != nil {
		return fmt.Errorf("revoke refresh token: %w", err)
	}

	return nil
}

func mapSQLCRefreshTokenToDomain(record sqlc.RefreshToken) (*domain.RefreshToken, error) {
	id, err := uuidFromPG(record.ID)
	if err != nil {
		return nil, fmt.Errorf("parse id: %w", err)
	}
	userID, err := uuidFromPG(record.UserID)
	if err != nil {
		return nil, fmt.Errorf("parse user_id: %w", err)
	}
	expiresAt, err := timeFromPG(record.ExpiresAt)
	if err != nil {
		return nil, fmt.Errorf("parse expires_at: %w", err)
	}
	createdAt, err := timeFromPG(record.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("parse created_at: %w", err)
	}
	revokedAt, err := ptrFromTimestamptz(record.RevokedAt)
	if err != nil {
		return nil, fmt.Errorf("parse revoked_at: %w", err)
	}

	return &domain.RefreshToken{
		ID:        id,
		UserID:    userID,
		TokenHash: record.TokenHash,
		DeviceID:  record.DeviceID,
		ExpiresAt: expiresAt,
		RevokedAt: revokedAt,
		CreatedAt: createdAt,
	}, nil
}

func pgUUIDFromUUID(id uuid.UUID) (pgtype.UUID, error) {
	var out pgtype.UUID
	if err := out.Scan(id.String()); err != nil {
		return pgtype.UUID{}, err
	}
	return out, nil
}

func pgTimestamptzFromTime(value time.Time) pgtype.Timestamptz {
	return pgtype.Timestamptz{
		Time:  value,
		Valid: true,
	}
}

func pgTimestamptzFromPtr(value *time.Time) pgtype.Timestamptz {
	if value == nil {
		return pgtype.Timestamptz{}
	}
	return pgTimestamptzFromTime(*value)
}

func ptrFromTimestamptz(value pgtype.Timestamptz) (*time.Time, error) {
	if !value.Valid {
		return nil, nil
	}

	t, err := timeFromPG(value)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

