package postgres

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mali-app/mali_api/internal/usecase"
)

type SyncLogRepository struct {
	db *pgxpool.Pool
}

func NewSyncLogRepository(db *pgxpool.Pool) *SyncLogRepository {
	return &SyncLogRepository{db: db}
}

func (r *SyncLogRepository) Create(
	ctx context.Context,
	userID uuid.UUID,
	entityType string,
	entityID uuid.UUID,
	operation string,
	payload json.RawMessage,
) error {
	const query = `
INSERT INTO sync_log (user_id, entity_type, entity_id, operation, payload)
VALUES ($1, $2, $3, $4, $5::jsonb)
`
	if len(payload) == 0 {
		payload = json.RawMessage(`{}`)
	}

	if _, err := r.db.Exec(ctx, query, userID, entityType, entityID, operation, []byte(payload)); err != nil {
		return fmt.Errorf("insert sync log: %w", err)
	}
	return nil
}

func (r *SyncLogRepository) ListByUserSince(ctx context.Context, input usecase.SyncLogListInput) ([]usecase.SyncLogEntry, error) {
	args := make([]interface{}, 0, 4)
	args = append(args, input.UserID, input.Since.UTC())
	argIndex := 3

	conditions := []string{
		"user_id = $1",
		"synced_at > $2",
	}
	if input.Cursor != nil {
		conditions = append(
			conditions,
			fmt.Sprintf("(synced_at > $%d OR (synced_at = $%d AND id > $%d))", argIndex, argIndex, argIndex+1),
		)
		args = append(args, input.Cursor.SyncedAt.UTC(), input.Cursor.ID)
		argIndex += 2
	}

	query := `
SELECT
  id,
  entity_type,
  entity_id,
  operation,
  payload,
  synced_at
FROM sync_log
WHERE ` + strings.Join(conditions, " AND ") + `
ORDER BY synced_at ASC, id ASC
LIMIT $` + fmt.Sprintf("%d", argIndex)
	args = append(args, input.Limit)

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("query sync log by user since: %w", err)
	}
	defer rows.Close()

	out := make([]usecase.SyncLogEntry, 0, input.Limit)
	for rows.Next() {
		record, scanErr := scanSyncLogEntry(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		out = append(out, record)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate sync log rows: %w", err)
	}

	return out, nil
}

func scanSyncLogEntry(row pgx.Row) (usecase.SyncLogEntry, error) {
	var (
		id         pgtype.UUID
		entityType string
		entityID   pgtype.UUID
		operation  string
		payload    []byte
		syncedAt   pgtype.Timestamptz
	)

	if err := row.Scan(&id, &entityType, &entityID, &operation, &payload, &syncedAt); err != nil {
		return usecase.SyncLogEntry{}, fmt.Errorf("scan sync log entry: %w", err)
	}

	parsedID, err := uuidFromPG(id)
	if err != nil {
		return usecase.SyncLogEntry{}, fmt.Errorf("parse sync log id: %w", err)
	}
	parsedEntityID, err := uuidFromPG(entityID)
	if err != nil {
		return usecase.SyncLogEntry{}, fmt.Errorf("parse sync log entity_id: %w", err)
	}
	parsedSyncedAt, err := timeFromPG(syncedAt)
	if err != nil {
		return usecase.SyncLogEntry{}, fmt.Errorf("parse sync log synced_at: %w", err)
	}

	return usecase.SyncLogEntry{
		ID:         parsedID,
		EntityType: entityType,
		EntityID:   parsedEntityID,
		Operation:  operation,
		Payload:    payload,
		SyncedAt:   parsedSyncedAt,
	}, nil
}

