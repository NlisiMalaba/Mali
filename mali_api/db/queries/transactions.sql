-- name: CreateTransaction :one
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
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
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
  exchange_rate;

-- name: GetTransactionsByUser :many
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
WHERE user_id = $1
  AND is_deleted = FALSE
  AND ($2::uuid IS NULL OR wallet_id = $2::uuid)
  AND ($3::uuid IS NULL OR category_id = $3::uuid)
  AND ($4::timestamptz IS NULL OR transacted_at >= $4::timestamptz)
  AND ($5::timestamptz IS NULL OR transacted_at <= $5::timestamptz)
  AND ($6::text IS NULL OR type = $6::text)
ORDER BY transacted_at DESC, created_at DESC;

-- name: GetTransactionByID :one
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
LIMIT 1;

-- name: SoftDeleteTransaction :exec
UPDATE transactions
SET is_deleted = TRUE
WHERE id = $1
  AND user_id = $2;

-- name: GetTransactionBySyncID :one
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
LIMIT 1;
