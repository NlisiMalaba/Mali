-- name: CreateWallet :one
INSERT INTO wallets (user_id, name, currency, wallet_type, balance, is_active)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING id, user_id, name, currency, wallet_type, balance, is_active, created_at;

-- name: GetWalletsByUser :many
SELECT id, user_id, name, currency, wallet_type, balance, is_active, created_at
FROM wallets
WHERE user_id = $1
  AND is_active = TRUE
ORDER BY created_at DESC;

-- name: GetWalletByID :one
SELECT id, user_id, name, currency, wallet_type, balance, is_active, created_at
FROM wallets
WHERE id = $1
LIMIT 1;

-- name: UpdateWalletBalance :exec
UPDATE wallets
SET balance = $2
WHERE id = $1;

-- name: UpdateWalletName :exec
UPDATE wallets
SET name = $2
WHERE id = $1;

-- name: SoftDeleteWallet :exec
UPDATE wallets
SET is_active = FALSE
WHERE id = $1;
