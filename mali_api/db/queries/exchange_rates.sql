-- name: UpsertExchangeRate :one
WITH updated AS (
  UPDATE exchange_rates
  SET rate = sqlc.arg(rate)::numeric
  WHERE user_id = sqlc.arg(user_id)::uuid
    AND from_currency = sqlc.arg(from_currency)::text
    AND to_currency = sqlc.arg(to_currency)::text
    AND source = sqlc.arg(source)::text
    AND valid_at = sqlc.arg(valid_at)::timestamptz
  RETURNING
    id,
    user_id,
    from_currency,
    to_currency,
    rate,
    source,
    valid_at
),
inserted AS (
  INSERT INTO exchange_rates (
    user_id,
    from_currency,
    to_currency,
    rate,
    source,
    valid_at
  )
  SELECT
    sqlc.arg(user_id)::uuid,
    sqlc.arg(from_currency)::text,
    sqlc.arg(to_currency)::text,
    sqlc.arg(rate)::numeric,
    sqlc.arg(source)::text,
    sqlc.arg(valid_at)::timestamptz
  WHERE NOT EXISTS (SELECT 1 FROM updated)
  RETURNING
    id,
    user_id,
    from_currency,
    to_currency,
    rate,
    source,
    valid_at
)
SELECT * FROM updated
UNION ALL
SELECT * FROM inserted
LIMIT 1;

-- name: GetLatestRateForPair :one
SELECT
  id,
  user_id,
  from_currency,
  to_currency,
  rate,
  source,
  valid_at
FROM exchange_rates
WHERE user_id = $1
  AND from_currency = $2
  AND to_currency = $3
ORDER BY valid_at DESC
LIMIT 1;

-- name: GetAllRatesForUser :many
SELECT
  id,
  user_id,
  from_currency,
  to_currency,
  rate,
  source,
  valid_at
FROM exchange_rates
WHERE user_id = $1
ORDER BY valid_at DESC, from_currency ASC, to_currency ASC;

