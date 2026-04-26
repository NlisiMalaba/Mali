package worker

import (
	"context"
	"fmt"

	"github.com/hibiken/asynq"
)

const TaskRefreshMonthlySummary = "analytics:refresh_monthly_summary"

type MaterializedViewRefresher interface {
	RefreshMonthlySummary(ctx context.Context) error
}

type AnalyticsWorker struct {
	refresher MaterializedViewRefresher
}

func NewAnalyticsWorker(refresher MaterializedViewRefresher) *AnalyticsWorker {
	return &AnalyticsWorker{refresher: refresher}
}

func NewRefreshMonthlySummaryTask() *asynq.Task {
	return asynq.NewTask(TaskRefreshMonthlySummary, nil)
}

func (w *AnalyticsWorker) HandleRefreshMonthlySummaryTask(ctx context.Context, _ *asynq.Task) error {
	if w.refresher == nil {
		return fmt.Errorf("analytics worker dependencies are not configured")
	}
	if err := w.refresher.RefreshMonthlySummary(ctx); err != nil {
		return fmt.Errorf("refresh monthly summary: %w", err)
	}
	return nil
}

