CREATE MATERIALIZED VIEW mv_monthly_summary AS
SELECT
  t.user_id,
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
  )::numeric AS net_total,
  COUNT(*)::bigint AS transaction_count
FROM transactions t
WHERE t.is_deleted = FALSE
GROUP BY
  t.user_id,
  EXTRACT(YEAR FROM date_trunc('month', t.transacted_at)),
  EXTRACT(MONTH FROM date_trunc('month', t.transacted_at)),
  t.currency;

CREATE UNIQUE INDEX idx_mv_monthly_summary_unique
ON mv_monthly_summary(user_id, year, month, currency);

