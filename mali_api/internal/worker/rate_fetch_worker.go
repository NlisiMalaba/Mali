package worker

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/hibiken/asynq"
	"github.com/mali-app/mali_api/internal/domain"
)

const (
	TaskFetchExchangeRates = "rates:fetch_auto"
	frankfurterLatestURL   = "https://api.frankfurter.app/latest"
	autoFetchSource        = "auto_fetch"
	baseCurrencyUSD        = "USD"
)

var supportedAutoFetchCurrencies = []string{"ZAR", "BWP"}

type UserIDLister interface {
	ListUserIDs(ctx context.Context) ([]uuid.UUID, error)
}

type ExchangeRateUpserter interface {
	Upsert(ctx context.Context, rate *domain.ExchangeRate) (*domain.ExchangeRate, error)
}

type RateFetchWorker struct {
	userLister UserIDLister
	rateRepo   ExchangeRateUpserter
	httpClient *http.Client
	now        func() time.Time
}

func NewRateFetchWorker(userLister UserIDLister, rateRepo ExchangeRateUpserter, httpClient *http.Client) *RateFetchWorker {
	client := httpClient
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}

	return &RateFetchWorker{
		userLister: userLister,
		rateRepo:   rateRepo,
		httpClient: client,
		now:        time.Now,
	}
}

func NewFetchExchangeRatesTask() *asynq.Task {
	return asynq.NewTask(TaskFetchExchangeRates, nil)
}

func (w *RateFetchWorker) HandleFetchExchangeRatesTask(ctx context.Context, _ *asynq.Task) error {
	if w.userLister == nil || w.rateRepo == nil || w.httpClient == nil {
		return fmt.Errorf("rate fetch worker dependencies are not configured")
	}

	rates, err := w.fetchRates(ctx)
	if err != nil {
		return err
	}

	userIDs, err := w.userLister.ListUserIDs(ctx)
	if err != nil {
		return fmt.Errorf("list users for rate fetch: %w", err)
	}

	validAt := w.now().UTC()
	for _, userID := range userIDs {
		for _, currency := range supportedAutoFetchCurrencies {
			rateValue, ok := rates[currency]
			if !ok || strings.TrimSpace(rateValue) == "" {
				return fmt.Errorf("missing %s rate in provider response", currency)
			}

			if _, err := w.rateRepo.Upsert(ctx, &domain.ExchangeRate{
				UserID:       userID,
				FromCurrency: baseCurrencyUSD,
				ToCurrency:   currency,
				Rate:         strings.TrimSpace(rateValue),
				Source:       autoFetchSource,
				ValidAt:      validAt,
			}); err != nil {
				return fmt.Errorf("upsert fetched %s rate for user %s: %w", currency, userID, err)
			}
		}
	}

	return nil
}

func (w *RateFetchWorker) fetchRates(ctx context.Context) (map[string]string, error) {
	queryURL, err := url.Parse(frankfurterLatestURL)
	if err != nil {
		return nil, fmt.Errorf("parse frankfurter url: %w", err)
	}

	values := queryURL.Query()
	values.Set("from", baseCurrencyUSD)
	values.Set("to", strings.Join(supportedAutoFetchCurrencies, ","))
	queryURL.RawQuery = values.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, queryURL.String(), nil)
	if err != nil {
		return nil, fmt.Errorf("build frankfurter request: %w", err)
	}

	resp, err := w.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request frankfurter rates: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
		return nil, fmt.Errorf("frankfurter returned status %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	var payload struct {
		Rates map[string]json.Number `json:"rates"`
	}
	decoder := json.NewDecoder(resp.Body)
	decoder.UseNumber()
	if err := decoder.Decode(&payload); err != nil {
		return nil, fmt.Errorf("decode frankfurter response: %w", err)
	}

	if len(payload.Rates) == 0 {
		return nil, fmt.Errorf("frankfurter response did not contain rates")
	}

	result := make(map[string]string, len(payload.Rates))
	for k, v := range payload.Rates {
		result[strings.ToUpper(strings.TrimSpace(k))] = strings.TrimSpace(v.String())
	}
	return result, nil
}

