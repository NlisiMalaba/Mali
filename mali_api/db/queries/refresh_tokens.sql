-- name: CreateRefreshToken :exec
INSERT INTO refresh_tokens (id, user_id, token_hash, device_id, expires_at, revoked_at, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7);

-- name: GetRefreshTokenByHash :one
SELECT id, user_id, token_hash, device_id, expires_at, revoked_at, created_at
FROM refresh_tokens
WHERE token_hash = $1
LIMIT 1;

-- name: RevokeRefreshTokenByID :exec
UPDATE refresh_tokens
SET revoked_at = $2
WHERE id = $1;

