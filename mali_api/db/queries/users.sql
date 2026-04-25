-- name: GetUserByID :one
SELECT id, email, phone, name, password_hash, created_at, updated_at
FROM users
WHERE id = $1
LIMIT 1;

-- name: GetUserByEmail :one
SELECT id, email, phone, name, password_hash, created_at, updated_at
FROM users
WHERE email = $1
LIMIT 1;

-- name: CreateUser :one
INSERT INTO users (email, phone, name, password_hash)
VALUES ($1, $2, $3, $4)
RETURNING id, email, phone, name, password_hash, created_at, updated_at;

