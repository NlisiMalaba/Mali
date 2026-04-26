package postgres

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/repository/sqlc"
)

type UserAdminRepository struct {
	queries *sqlc.Queries
}

func NewUserAdminRepository(queries *sqlc.Queries) *UserAdminRepository {
	return &UserAdminRepository{queries: queries}
}

func (r *UserAdminRepository) ListUserIDs(ctx context.Context) ([]uuid.UUID, error) {
	rows, err := r.queries.GetAllUserIDs(ctx)
	if err != nil {
		return nil, fmt.Errorf("list user ids: %w", err)
	}

	out := make([]uuid.UUID, 0, len(rows))
	for _, row := range rows {
		id, parseErr := uuidFromPG(row)
		if parseErr != nil {
			return nil, fmt.Errorf("parse user id: %w", parseErr)
		}
		out = append(out, id)
	}
	return out, nil
}

