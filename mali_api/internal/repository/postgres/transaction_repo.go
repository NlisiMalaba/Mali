package postgres

import (
	"context"
	"errors"
	"fmt"
	"math/big"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mali-app/mali_api/internal/domain"
)

type TransactionRepository struct {
	db *pgxpool.Pool
}

func NewTransactionRepository(db *pgxpool.Pool) *TransactionRepository {
	return &TransactionRepository{
		db: db,
	}
}

var _ domain.ITransactionRepository = (*TransactionRepository)(nil)

func (r *TransactionRepository) CreateAndApply(ctx context.Context, input domain.CreateTransactionInput) (*domain.Transaction, error) {
	tx, err := r.db.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return nil, fmt.Errorf("begin transaction: %w", err)
	}

	committed := false
	defer func() {
		if !committed {
			_ = tx.Rollback(ctx)
		}
	}()

	amount, err := parseDecimal(input.Amount)
	if err != nil {
		return nil, fmt.Errorf("parse transaction amount: %w", err)
	}

	if err := r.lockWalletForUpdate(ctx, tx, input.UserID, input.WalletID); err != nil {
		return nil, err
	}

	sourceDelta := new(big.Rat).Set(amount)
	switch input.Type {
	case "expense", "transfer":
		sourceDelta.Neg(sourceDelta)
	case "income":
		// Positive delta.
	default:
		return nil, fmt.Errorf("unsupported transaction type: %s", input.Type)
	}

	if err := r.applyWalletBalanceDeltaTx(ctx, tx, input.WalletID, ratToDecimalString(sourceDelta)); err != nil {
		return nil, err
	}

	if input.Type == "transfer" {
		if input.TransferToWalletID == nil {
			return nil, fmt.Errorf("transfer_to_wallet_id is required")
		}
		if input.ExchangeRate == nil {
			return nil, fmt.Errorf("exchange_rate is required")
		}

		if err := r.lockWalletForUpdate(ctx, tx, input.UserID, *input.TransferToWalletID); err != nil {
			return nil, err
		}
		rate, err := parseDecimal(*input.ExchangeRate)
		if err != nil {
			return nil, fmt.Errorf("parse exchange rate: %w", err)
		}

		creditedAmount := new(big.Rat).Mul(amount, rate)
		if err := r.applyWalletBalanceDeltaTx(ctx, tx, *input.TransferToWalletID, ratToDecimalString(creditedAmount)); err != nil {
			return nil, err
		}
	}

	inserted, err := r.insertTransactionTx(ctx, tx, input)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit transaction: %w", err)
	}
	committed = true

	return inserted, nil
}

func (r *TransactionRepository) ListByUser(ctx context.Context, input domain.ListTransactionsInput) ([]*domain.Transaction, error) {
	query, args := buildListTransactionsQuery(input)
	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query transactions: %w", err)
	}
	defer rows.Close()

	out := make([]*domain.Transaction, 0, input.Limit)
	for rows.Next() {
		record, scanErr := scanTransaction(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		out = append(out, record)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate transactions: %w", err)
	}
	return out, nil
}

func (r *TransactionRepository) FindByID(ctx context.Context, id uuid.UUID) (*domain.Transaction, error) {
	const query = `
SELECT
  id,
  user_id,
  wallet_id,
  category_id,
  type,
  amount,
  currency,
  notes,
  source,
  transacted_at,
  created_at,
  is_deleted,
  sync_id,
  transfer_to_wallet_id,
  exchange_rate
FROM transactions
WHERE id = $1
LIMIT 1
`
	row := r.db.QueryRow(ctx, query, id)
	record, err := scanTransaction(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, pgx.ErrNoRows
		}
		return nil, fmt.Errorf("find transaction by id: %w", err)
	}
	return record, nil
}

func (r *TransactionRepository) FindBySyncID(ctx context.Context, syncID uuid.UUID) (*domain.Transaction, error) {
	const query = `
SELECT
  id,
  user_id,
  wallet_id,
  category_id,
  type,
  amount,
  currency,
  notes,
  source,
  transacted_at,
  created_at,
  is_deleted,
  sync_id,
  transfer_to_wallet_id,
  exchange_rate
FROM transactions
WHERE sync_id = $1
LIMIT 1
`
	row := r.db.QueryRow(ctx, query, syncID)
	record, err := scanTransaction(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, pgx.ErrNoRows
		}
		return nil, fmt.Errorf("find transaction by sync_id: %w", err)
	}
	return record, nil
}

func (r *TransactionRepository) SoftDelete(ctx context.Context, userID, id uuid.UUID) error {
	const query = `
UPDATE transactions
SET is_deleted = TRUE
WHERE id = $1
  AND user_id = $2
  AND is_deleted = FALSE
`
	tag, err := r.db.Exec(ctx, query, id, userID)
	if err != nil {
		return fmt.Errorf("soft delete transaction: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func buildListTransactionsQuery(input domain.ListTransactionsInput) (string, []interface{}) {
	args := make([]interface{}, 0, 9)
	args = append(args, input.UserID)
	argIndex := 2

	var conditions []string
	conditions = append(conditions, "user_id = $1")
	conditions = append(conditions, "is_deleted = FALSE")

	if input.WalletID != nil {
		conditions = append(conditions, fmt.Sprintf("wallet_id = $%d", argIndex))
		args = append(args, *input.WalletID)
		argIndex++
	}
	if input.CategoryID != nil {
		conditions = append(conditions, fmt.Sprintf("category_id = $%d", argIndex))
		args = append(args, *input.CategoryID)
		argIndex++
	}
	if input.DateFrom != nil {
		conditions = append(conditions, fmt.Sprintf("transacted_at >= $%d", argIndex))
		args = append(args, *input.DateFrom)
		argIndex++
	}
	if input.DateTo != nil {
		conditions = append(conditions, fmt.Sprintf("transacted_at <= $%d", argIndex))
		args = append(args, *input.DateTo)
		argIndex++
	}
	if input.Type != nil {
		conditions = append(conditions, fmt.Sprintf("type = $%d", argIndex))
		args = append(args, *input.Type)
		argIndex++
	}

	if input.Cursor != nil {
		if input.SortOrder == domain.TransactionSortAsc {
			conditions = append(
				conditions,
				fmt.Sprintf("(transacted_at > $%d OR (transacted_at = $%d AND id > $%d))", argIndex, argIndex, argIndex+1),
			)
		} else {
			conditions = append(
				conditions,
				fmt.Sprintf("(transacted_at < $%d OR (transacted_at = $%d AND id < $%d))", argIndex, argIndex, argIndex+1),
			)
		}
		args = append(args, input.Cursor.TransactedAt, input.Cursor.ID)
		argIndex += 2
	}

	orderDirection := "DESC"
	if input.SortOrder == domain.TransactionSortAsc {
		orderDirection = "ASC"
	}

	query := `
SELECT
  id,
  user_id,
  wallet_id,
  category_id,
  type,
  amount,
  currency,
  notes,
  source,
  transacted_at,
  created_at,
  is_deleted,
  sync_id,
  transfer_to_wallet_id,
  exchange_rate
FROM transactions
WHERE ` + strings.Join(conditions, " AND ") + `
ORDER BY transacted_at ` + orderDirection + `, id ` + orderDirection + `
LIMIT $` + fmt.Sprintf("%d", argIndex)

	args = append(args, input.Limit)
	return query, args
}

func (r *TransactionRepository) lockWalletForUpdate(ctx context.Context, tx pgx.Tx, userID, walletID uuid.UUID) error {
	const query = `
SELECT id
FROM wallets
WHERE id = $1
  AND user_id = $2
  AND is_active = TRUE
FOR UPDATE
`

	var lockedWalletID uuid.UUID
	if err := tx.QueryRow(ctx, query, walletID, userID).Scan(&lockedWalletID); err != nil {
		if err == pgx.ErrNoRows {
			return fmt.Errorf("wallet not found")
		}
		return fmt.Errorf("lock wallet: %w", err)
	}
	return nil
}

func (r *TransactionRepository) applyWalletBalanceDeltaTx(ctx context.Context, tx pgx.Tx, walletID uuid.UUID, delta string) error {
	const query = `
UPDATE wallets
SET balance = balance + $2::numeric
WHERE id = $1
`
	tag, err := tx.Exec(ctx, query, walletID, delta)
	if err != nil {
		return fmt.Errorf("apply wallet balance delta: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return fmt.Errorf("wallet not found")
	}
	return nil
}

func (r *TransactionRepository) insertTransactionTx(ctx context.Context, tx pgx.Tx, input domain.CreateTransactionInput) (*domain.Transaction, error) {
	const query = `
INSERT INTO transactions (
  user_id,
  wallet_id,
  category_id,
  type,
  amount,
  currency,
  notes,
  source,
  transacted_at,
  sync_id,
  transfer_to_wallet_id,
  exchange_rate
)
VALUES ($1, $2, $3, $4, $5::numeric, $6, $7, $8, $9, $10, $11, $12::numeric)
RETURNING
  id,
  user_id,
  wallet_id,
  category_id,
  type,
  amount,
  currency,
  notes,
  source,
  transacted_at,
  created_at,
  is_deleted,
  sync_id,
  transfer_to_wallet_id,
  exchange_rate
`

	row := tx.QueryRow(
		ctx,
		query,
		input.UserID,
		input.WalletID,
		uuidOrNil(input.CategoryID),
		input.Type,
		input.Amount,
		input.Currency,
		stringOrNil(input.Notes),
		input.Source,
		input.TransactedAt,
		uuidOrNil(input.SyncID),
		uuidOrNil(input.TransferToWalletID),
		stringOrNil(input.ExchangeRate),
	)

	return scanTransaction(row)
}

func scanTransaction(row pgx.Row) (*domain.Transaction, error) {
	var (
		id                 pgtype.UUID
		userID             pgtype.UUID
		walletID           pgtype.UUID
		categoryID         pgtype.UUID
		txType             string
		amount             pgtype.Numeric
		currency           string
		notes              pgtype.Text
		source             string
		transactedAt       pgtype.Timestamptz
		createdAt          pgtype.Timestamptz
		isDeleted          pgtype.Bool
		syncID             pgtype.UUID
		transferToWalletID pgtype.UUID
		exchangeRate       pgtype.Numeric
	)

	if err := row.Scan(
		&id,
		&userID,
		&walletID,
		&categoryID,
		&txType,
		&amount,
		&currency,
		&notes,
		&source,
		&transactedAt,
		&createdAt,
		&isDeleted,
		&syncID,
		&transferToWalletID,
		&exchangeRate,
	); err != nil {
		return nil, fmt.Errorf("scan transaction: %w", err)
	}

	parsedID, err := uuidFromPG(id)
	if err != nil {
		return nil, fmt.Errorf("parse id: %w", err)
	}
	parsedUserID, err := uuidFromPG(userID)
	if err != nil {
		return nil, fmt.Errorf("parse user_id: %w", err)
	}
	parsedWalletID, err := uuidFromPG(walletID)
	if err != nil {
		return nil, fmt.Errorf("parse wallet_id: %w", err)
	}
	parsedAmount, err := stringFromNumeric(amount)
	if err != nil {
		return nil, fmt.Errorf("parse amount: %w", err)
	}
	parsedTransactedAt, err := timeFromPG(transactedAt)
	if err != nil {
		return nil, fmt.Errorf("parse transacted_at: %w", err)
	}
	parsedCreatedAt, err := timeFromPG(createdAt)
	if err != nil {
		return nil, fmt.Errorf("parse created_at: %w", err)
	}

	parsedCategoryID, err := ptrFromUUID(categoryID)
	if err != nil {
		return nil, fmt.Errorf("parse category_id: %w", err)
	}
	parsedSyncID, err := ptrFromUUID(syncID)
	if err != nil {
		return nil, fmt.Errorf("parse sync_id: %w", err)
	}
	parsedTransferToWalletID, err := ptrFromUUID(transferToWalletID)
	if err != nil {
		return nil, fmt.Errorf("parse transfer_to_wallet_id: %w", err)
	}
	parsedExchangeRate, err := ptrFromNumeric(exchangeRate)
	if err != nil {
		return nil, fmt.Errorf("parse exchange_rate: %w", err)
	}

	return &domain.Transaction{
		ID:                 parsedID,
		UserID:             parsedUserID,
		WalletID:           parsedWalletID,
		CategoryID:         parsedCategoryID,
		Type:               txType,
		Amount:             parsedAmount,
		Currency:           currency,
		Notes:              ptrFromText(notes),
		Source:             source,
		TransactedAt:       parsedTransactedAt,
		CreatedAt:          parsedCreatedAt,
		IsDeleted:          isDeleted.Valid && isDeleted.Bool,
		SyncID:             parsedSyncID,
		TransferToWalletID: parsedTransferToWalletID,
		ExchangeRate:       parsedExchangeRate,
	}, nil
}

func uuidOrNil(value *uuid.UUID) interface{} {
	if value == nil {
		return nil
	}
	return *value
}

func stringOrNil(value *string) interface{} {
	if value == nil {
		return nil
	}
	return *value
}

func ptrFromUUID(value pgtype.UUID) (*uuid.UUID, error) {
	if !value.Valid {
		return nil, nil
	}
	parsed, err := uuidFromPG(value)
	if err != nil {
		return nil, err
	}
	return &parsed, nil
}

func ptrFromNumeric(value pgtype.Numeric) (*string, error) {
	if !value.Valid {
		return nil, nil
	}
	parsed, err := stringFromNumeric(value)
	if err != nil {
		return nil, err
	}
	return &parsed, nil
}

func parseDecimal(value string) (*big.Rat, error) {
	out := new(big.Rat)
	if _, ok := out.SetString(value); !ok {
		return nil, fmt.Errorf("invalid decimal value")
	}
	return out, nil
}

func ratToDecimalString(value *big.Rat) string {
	return value.FloatString(12)
}

