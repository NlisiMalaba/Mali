-- name: GetSystemCategories :many
SELECT id, user_id, name, icon, color_hex, type
FROM categories
WHERE user_id IS NULL
ORDER BY name ASC;

-- name: GetUserCategories :many
SELECT id, user_id, name, icon, color_hex, type
FROM categories
WHERE user_id = $1
ORDER BY name ASC;

-- name: CreateUserCategory :one
INSERT INTO categories (user_id, name, icon, color_hex, type)
VALUES ($1, $2, $3, $4, $5)
RETURNING id, user_id, name, icon, color_hex, type;

-- name: UpdateUserCategory :exec
UPDATE categories
SET name = $3,
    icon = $4,
    color_hex = $5,
    type = $6
WHERE id = $1
  AND user_id = $2;

-- name: DeleteUserCategory :exec
DELETE FROM categories
WHERE id = $1
  AND user_id = $2;
