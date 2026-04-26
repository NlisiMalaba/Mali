package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type AnalyticsMVRepository struct {
	db *pgxpool.Pool
}

func NewAnalyticsMVRepository(db *pgxpool.Pool) *AnalyticsMVRepository {
	return &AnalyticsMVRepository{db: db}
}

func (r *AnalyticsMVRepository) RefreshMonthlySummary(ctx context.Context) error {
	if r.db == nil {
		return fmt.Errorf("analytics mv repository database is not configured")
	}

	const query = `REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_summary`
	if _, err := r.db.Exec(ctx, query); err != nil {
		return fmt.Errorf("refresh materialized view mv_monthly_summary: %w", err)
	}
	return nil
}

