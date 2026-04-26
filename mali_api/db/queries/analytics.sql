-- name: GetMonthlyTotals :many
SELECT
  t.currency,
  COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0)::numeric AS income_total,
  COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)::numeric AS expense_total,
  COALESCE(
    SUM(
      CASE
        WHEN t.type = 'income' THEN t.amount
        WHEN t.type = 'expense' THEN -t.amount
        ELSE 0
      END
    ),
    0
  )::numeric AS net_total
FROM transactions t
WHERE t.user_id = $1
  AND t.is_deleted = FALSE
  AND EXTRACT(MONTH FROM t.transacted_at) = sqlc.arg(month)::int
  AND EXTRACT(YEAR FROM t.transacted_at) = sqlc.arg(year)::int
GROUP BY t.currency
ORDER BY t.currency ASC;

-- name: GetCategoryBreakdown :many
SELECT
  t.category_id,
  c.name AS category_name,
  c.icon AS category_icon,
  c.color_hex AS category_color_hex,
  t.currency,
  COALESCE(SUM(t.amount), 0)::numeric AS total_amount
FROM transactions t
LEFT JOIN categories c ON c.id = t.category_id
WHERE t.user_id = $1
  AND t.is_deleted = FALSE
  AND t.type = 'expense'
  AND EXTRACT(MONTH FROM t.transacted_at) = sqlc.arg(month)::int
  AND EXTRACT(YEAR FROM t.transacted_at) = sqlc.arg(year)::int
GROUP BY t.category_id, c.name, c.icon, c.color_hex, t.currency
ORDER BY total_amount DESC, category_name ASC;

-- name: GetMonthlyTrend :many
WITH bounds AS (
  SELECT
    make_date(sqlc.arg(year)::int, sqlc.arg(month)::int, 1)::date AS month_start,
    GREATEST(sqlc.arg(months)::int, 1) AS month_count
)
SELECT
  EXTRACT(YEAR FROM date_trunc('month', t.transacted_at))::int AS year,
  EXTRACT(MONTH FROM date_trunc('month', t.transacted_at))::int AS month,
  t.currency,
  COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0)::numeric AS income_total,
  COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0)::numeric AS expense_total,
  COALESCE(
    SUM(
      CASE
        WHEN t.type = 'income' THEN t.amount
        WHEN t.type = 'expense' THEN -t.amount
        ELSE 0
      END
    ),
    0
  )::numeric AS net_total
FROM transactions t
CROSS JOIN bounds b
WHERE t.user_id = sqlc.arg(user_id)::uuid
  AND t.is_deleted = FALSE
  AND t.transacted_at >= (b.month_start - ((b.month_count - 1) * INTERVAL '1 month'))
  AND t.transacted_at < (b.month_start + INTERVAL '1 month')
GROUP BY
  EXTRACT(YEAR FROM date_trunc('month', t.transacted_at)),
  EXTRACT(MONTH FROM date_trunc('month', t.transacted_at)),
  t.currency
ORDER BY year ASC, month ASC, t.currency ASC;

