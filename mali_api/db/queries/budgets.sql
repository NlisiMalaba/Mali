-- name: UpsertBudget :one
INSERT INTO budgets (
  user_id,
  category_id,
  currency,
  amount,
  month,
  year,
  rollover
)
VALUES ($1, $2, $3, $4, $5, $6, $7)
ON CONFLICT (user_id, category_id, month, year)
DO UPDATE SET
  currency = EXCLUDED.currency,
  amount = EXCLUDED.amount,
  rollover = EXCLUDED.rollover
RETURNING
  id,
  user_id,
  category_id,
  currency,
  amount,
  month,
  year,
  rollover;

-- name: GetBudgetsByUserMonth :many
SELECT
  id,
  user_id,
  category_id,
  currency,
  amount,
  month,
  year,
  rollover
FROM budgets
WHERE user_id = $1
  AND month = $2
  AND year = $3
ORDER BY category_id ASC;

-- name: GetBudgetSpent :one
SELECT
  COALESCE(SUM(t.amount), 0)::numeric AS spent_amount
FROM transactions t
WHERE t.user_id = $1
  AND t.category_id = $2
  AND t.type = 'expense'
  AND t.is_deleted = FALSE
  AND t.transacted_at >= make_date(sqlc.arg(year)::int, sqlc.arg(month)::int, 1)::timestamptz
  AND t.transacted_at < (
    make_date(sqlc.arg(year)::int, sqlc.arg(month)::int, 1)::timestamptz + INTERVAL '1 month'
  );
