package postgres

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/repository/sqlc"
)

type WalletRepository struct {
	queries *sqlc.Queries
}

func NewWalletRepository(queries *sqlc.Queries) *WalletRepository {
	return &WalletRepository{queries: queries}
}

var _ domain.IWalletRepository = (*WalletRepository)(nil)

func (r *WalletRepository) Create(ctx context.Context, wallet *domain.Wallet) (*domain.Wallet, error) {
	dbUserID, err := pgUUIDFromUUID(wallet.UserID)
	if err != nil {
		return nil, fmt.Errorf("parse wallet user id: %w", err)
	}
	dbBalance, err := numericFromString(wallet.Balance)
	if err != nil {
		return nil, fmt.Errorf("parse wallet balance: %w", err)
	}

	created, err := r.queries.CreateWallet(ctx, sqlc.CreateWalletParams{
		UserID:     dbUserID,
		Name:       wallet.Name,
		Currency:   wallet.Currency,
		WalletType: wallet.WalletType,
		Balance:    dbBalance,
		IsActive:   pgtype.Bool{Bool: wallet.IsActive, Valid: true},
	})
	if err != nil {
		return nil, fmt.Errorf("create wallet: %w", err)
	}

	mapped, err := mapSQLCWalletToDomain(created)
	if err != nil {
		return nil, fmt.Errorf("map created wallet: %w", err)
	}
	return mapped, nil
}

func (r *WalletRepository) ListByUser(ctx context.Context, userID uuid.UUID) ([]*domain.Wallet, error) {
	dbUserID, err := pgUUIDFromUUID(userID)
	if err != nil {
		return nil, fmt.Errorf("parse user id: %w", err)
	}

	rows, err := r.queries.GetWalletsByUser(ctx, dbUserID)
	if err != nil {
		return nil, fmt.Errorf("list wallets by user: %w", err)
	}

	out := make([]*domain.Wallet, 0, len(rows))
	for _, row := range rows {
		mapped, mapErr := mapSQLCWalletToDomain(row)
		if mapErr != nil {
			return nil, fmt.Errorf("map wallet: %w", mapErr)
		}
		out = append(out, mapped)
	}
	return out, nil
}

func (r *WalletRepository) FindByID(ctx context.Context, id uuid.UUID) (*domain.Wallet, error) {
	dbID, err := pgUUIDFromUUID(id)
	if err != nil {
		return nil, fmt.Errorf("parse wallet id: %w", err)
	}

	row, err := r.queries.GetWalletByID(ctx, dbID)
	if err != nil {
		return nil, fmt.Errorf("find wallet by id: %w", err)
	}

	mapped, err := mapSQLCWalletToDomain(row)
	if err != nil {
		return nil, fmt.Errorf("map wallet by id: %w", err)
	}
	return mapped, nil
}

func (r *WalletRepository) UpdateBalance(ctx context.Context, id uuid.UUID, balance string) error {
	dbID, err := pgUUIDFromUUID(id)
	if err != nil {
		return fmt.Errorf("parse wallet id: %w", err)
	}
	dbBalance, err := numericFromString(balance)
	if err != nil {
		return fmt.Errorf("parse wallet balance: %w", err)
	}

	if err := r.queries.UpdateWalletBalance(ctx, sqlc.UpdateWalletBalanceParams{
		ID:      dbID,
		Balance: dbBalance,
	}); err != nil {
		return fmt.Errorf("update wallet balance: %w", err)
	}
	return nil
}

func (r *WalletRepository) UpdateName(ctx context.Context, id uuid.UUID, name string) error {
	dbID, err := pgUUIDFromUUID(id)
	if err != nil {
		return fmt.Errorf("parse wallet id: %w", err)
	}

	if err := r.queries.UpdateWalletName(ctx, sqlc.UpdateWalletNameParams{
		ID:   dbID,
		Name: name,
	}); err != nil {
		return fmt.Errorf("update wallet name: %w", err)
	}
	return nil
}

func (r *WalletRepository) SoftDelete(ctx context.Context, id uuid.UUID) error {
	dbID, err := pgUUIDFromUUID(id)
	if err != nil {
		return fmt.Errorf("parse wallet id: %w", err)
	}

	if err := r.queries.SoftDeleteWallet(ctx, dbID); err != nil {
		return fmt.Errorf("soft delete wallet: %w", err)
	}
	return nil
}

func mapSQLCWalletToDomain(wallet sqlc.Wallet) (*domain.Wallet, error) {
	id, err := uuidFromPG(wallet.ID)
	if err != nil {
		return nil, fmt.Errorf("parse id: %w", err)
	}
	userID, err := uuidFromPG(wallet.UserID)
	if err != nil {
		return nil, fmt.Errorf("parse user_id: %w", err)
	}
	balance, err := stringFromNumeric(wallet.Balance)
	if err != nil {
		return nil, fmt.Errorf("parse balance: %w", err)
	}
	createdAt, err := timeFromPG(wallet.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("parse created_at: %w", err)
	}

	return &domain.Wallet{
		ID:         id,
		UserID:     userID,
		Name:       wallet.Name,
		Currency:   wallet.Currency,
		WalletType: wallet.WalletType,
		Balance:    balance,
		IsActive:   wallet.IsActive.Valid && wallet.IsActive.Bool,
		CreatedAt:  createdAt,
	}, nil
}

func numericFromString(value string) (pgtype.Numeric, error) {
	var out pgtype.Numeric
	if err := out.Scan(value); err != nil {
		return pgtype.Numeric{}, err
	}
	return out, nil
}

func stringFromNumeric(value pgtype.Numeric) (string, error) {
	raw, err := value.Value()
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%v", raw), nil
}

