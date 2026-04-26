package usecase

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/mali-app/mali_api/internal/domain"
)

type mockExchangeRateRepository struct {
	lastUpserted *domain.ExchangeRate
	ratesByUser  map[uuid.UUID][]*domain.ExchangeRate
}

func (m *mockExchangeRateRepository) Upsert(_ context.Context, rate *domain.ExchangeRate) (*domain.ExchangeRate, error) {
	copied := *rate
	if copied.ID == uuid.Nil {
		copied.ID = uuid.New()
	}
	m.lastUpserted = &copied
	return &copied, nil
}

func (m *mockExchangeRateRepository) GetLatestForPair(
	_ context.Context,
	userID uuid.UUID,
	fromCurrency, toCurrency string,
) (*domain.ExchangeRate, error) {
	items := m.ratesByUser[userID]
	for _, item := range items {
		if item.FromCurrency == fromCurrency && item.ToCurrency == toCurrency {
			copied := *item
			return &copied, nil
		}
	}
	return nil, pgx.ErrNoRows
}

func (m *mockExchangeRateRepository) ListByUser(_ context.Context, userID uuid.UUID) ([]*domain.ExchangeRate, error) {
	items := m.ratesByUser[userID]
	out := make([]*domain.ExchangeRate, 0, len(items))
	for _, item := range items {
		copied := *item
		out = append(out, &copied)
	}
	return out, nil
}

func TestRateService_SetManualRate_Success(t *testing.T) {
	t.Parallel()

	repo := &mockExchangeRateRepository{}
	service, err := NewRateService(repo)
	if err != nil {
		t.Fatalf("create rate service: %v", err)
	}
	service.now = func() time.Time {
		return time.Date(2026, time.April, 26, 6, 30, 0, 0, time.UTC)
	}

	created, err := service.SetManualRate(context.Background(), SetManualRateInput{
		UserID:       uuid.New(),
		FromCurrency: "usd",
		ToCurrency:   "zwg",
		Rate:         "26.7512",
	})
	if err != nil {
		t.Fatalf("set manual rate: %v", err)
	}

	if created.Source != manualRateSource {
		t.Fatalf("expected source=%s, got=%s", manualRateSource, created.Source)
	}
	if created.FromCurrency != "USD" || created.ToCurrency != "ZWG" {
		t.Fatalf("expected normalized currencies USD/ZWG, got %s/%s", created.FromCurrency, created.ToCurrency)
	}
	if repo.lastUpserted == nil {
		t.Fatal("expected repository upsert to be called")
	}
	if repo.lastUpserted.ValidAt.IsZero() {
		t.Fatal("expected valid_at to be set")
	}
}

func TestRateService_SetManualRate_ValidatesInput(t *testing.T) {
	t.Parallel()

	repo := &mockExchangeRateRepository{}
	service, err := NewRateService(repo)
	if err != nil {
		t.Fatalf("create rate service: %v", err)
	}

	_, err = service.SetManualRate(context.Background(), SetManualRateInput{
		UserID:       uuid.Nil,
		FromCurrency: "USD",
		ToCurrency:   "ZWG",
		Rate:         "1.2",
	})
	if err == nil {
		t.Fatal("expected validation error for missing user_id")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}

	_, err = service.SetManualRate(context.Background(), SetManualRateInput{
		UserID:       uuid.New(),
		FromCurrency: "USD",
		ToCurrency:   "USD",
		Rate:         "1.2",
	})
	if err == nil {
		t.Fatal("expected validation error for same currency pair")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}

	_, err = service.SetManualRate(context.Background(), SetManualRateInput{
		UserID:       uuid.New(),
		FromCurrency: "USD",
		ToCurrency:   "ZWG",
		Rate:         "-1",
	})
	if err == nil {
		t.Fatal("expected validation error for negative rate")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

func TestRateService_GetRates_ReturnsUserRates(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	otherUserID := uuid.New()
	repo := &mockExchangeRateRepository{
		ratesByUser: map[uuid.UUID][]*domain.ExchangeRate{
			userID: {
				{
					ID:           uuid.New(),
					UserID:       userID,
					FromCurrency: "USD",
					ToCurrency:   "ZWG",
					Rate:         "26.7512",
					Source:       manualRateSource,
					ValidAt:      time.Date(2026, time.April, 26, 6, 30, 0, 0, time.UTC),
				},
			},
			otherUserID: {
				{
					ID:           uuid.New(),
					UserID:       otherUserID,
					FromCurrency: "USD",
					ToCurrency:   "ZAR",
					Rate:         "18.5000",
					Source:       manualRateSource,
					ValidAt:      time.Date(2026, time.April, 26, 6, 35, 0, 0, time.UTC),
				},
			},
		},
	}
	service, err := NewRateService(repo)
	if err != nil {
		t.Fatalf("create rate service: %v", err)
	}

	rates, err := service.GetRates(context.Background(), GetRatesInput{UserID: userID})
	if err != nil {
		t.Fatalf("get rates: %v", err)
	}
	if len(rates) != 1 {
		t.Fatalf("expected 1 rate for user, got %d", len(rates))
	}
	if rates[0].UserID != userID {
		t.Fatalf("expected user id %s, got %s", userID, rates[0].UserID)
	}
}

func TestRateService_GetLatestRate_ReturnsLatestForPair(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	repo := &mockExchangeRateRepository{
		ratesByUser: map[uuid.UUID][]*domain.ExchangeRate{
			userID: {
				{
					ID:           uuid.New(),
					UserID:       userID,
					FromCurrency: "USD",
					ToCurrency:   "ZAR",
					Rate:         "18.5000",
					Source:       manualRateSource,
					ValidAt:      time.Date(2026, time.April, 26, 6, 35, 0, 0, time.UTC),
				},
			},
		},
	}
	service, err := NewRateService(repo)
	if err != nil {
		t.Fatalf("create rate service: %v", err)
	}

	rate, err := service.GetLatestRate(context.Background(), GetLatestRateInput{
		UserID:       userID,
		FromCurrency: "usd",
		ToCurrency:   "zar",
	})
	if err != nil {
		t.Fatalf("get latest rate: %v", err)
	}
	if rate.Rate != "18.5000" {
		t.Fatalf("expected rate 18.5000, got %s", rate.Rate)
	}
}

func TestRateService_GetLatestRate_NotFoundReturnsValidationError(t *testing.T) {
	t.Parallel()

	service, err := NewRateService(&mockExchangeRateRepository{
		ratesByUser: map[uuid.UUID][]*domain.ExchangeRate{},
	})
	if err != nil {
		t.Fatalf("create rate service: %v", err)
	}

	_, err = service.GetLatestRate(context.Background(), GetLatestRateInput{
		UserID:       uuid.New(),
		FromCurrency: "USD",
		ToCurrency:   "BWP",
	})
	if err == nil {
		t.Fatal("expected validation error for missing rate")
	}
	if !errors.Is(err, ErrValidation) {
		t.Fatalf("expected ErrValidation, got %v", err)
	}
}

