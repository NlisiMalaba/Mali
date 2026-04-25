-- name: CreateGoal :one
INSERT INTO savings_goals (
  user_id,
  name,
  emoji,
  goal_type,
  target_amount,
  currency,
  saved_amount,
  required_monthly,
  deadline,
  priority,
  is_completed
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
RETURNING
  id,
  user_id,
  name,
  emoji,
  goal_type,
  target_amount,
  currency,
  saved_amount,
  required_monthly,
  deadline,
  priority,
  is_completed,
  created_at;

-- name: GetGoalsByUser :many
SELECT
  id,
  user_id,
  name,
  emoji,
  goal_type,
  target_amount,
  currency,
  saved_amount,
  required_monthly,
  deadline,
  priority,
  is_completed,
  created_at
FROM savings_goals
WHERE user_id = $1
ORDER BY priority ASC, created_at DESC;

-- name: GetGoalByID :one
SELECT
  id,
  user_id,
  name,
  emoji,
  goal_type,
  target_amount,
  currency,
  saved_amount,
  required_monthly,
  deadline,
  priority,
  is_completed,
  created_at
FROM savings_goals
WHERE id = $1
  AND user_id = $2
LIMIT 1;

-- name: UpdateGoal :exec
UPDATE savings_goals
SET
  name = $3,
  emoji = $4,
  goal_type = $5,
  target_amount = $6,
  currency = $7,
  required_monthly = $8,
  deadline = $9,
  priority = $10,
  is_completed = $11
WHERE id = $1
  AND user_id = $2;

-- name: UpdateGoalSavedAmount :exec
UPDATE savings_goals
SET saved_amount = $3
WHERE id = $1
  AND user_id = $2;

-- name: DeleteGoal :exec
DELETE FROM savings_goals
WHERE id = $1
  AND user_id = $2;

-- name: CreateGoalContribution :one
INSERT INTO goal_contributions (
  goal_id,
  amount,
  currency,
  notes,
  contributed_at
)
VALUES ($1, $2, $3, $4, $5)
RETURNING
  id,
  goal_id,
  amount,
  currency,
  notes,
  contributed_at;

-- name: GetContributionsByGoal :many
SELECT gc.id, gc.goal_id, gc.amount, gc.currency, gc.notes, gc.contributed_at
FROM goal_contributions gc
INNER JOIN savings_goals sg ON sg.id = gc.goal_id
WHERE gc.goal_id = $1
  AND sg.user_id = $2
ORDER BY gc.contributed_at DESC;
