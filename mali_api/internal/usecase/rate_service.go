package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/mali-app/mali_api/internal/domain"
)

const manualRateSource = "manual"

type SetManualRateInput struct {
	UserID       uuid.UUID
	FromCurrency string
	ToCurrency   string
	Rate         string
	ValidAt      time.Time
}

type GetRatesInput struct {
	UserID uuid.UUID
}

type GetLatestRateInput struct {
	UserID       uuid.UUID
	FromCurrency string
	ToCurrency   string
}

type RateService struct {
	rateRepository domain.IExchangeRateRepository
	now            func() time.Time
}

func NewRateService(rateRepository domain.IExchangeRateRepository) (*RateService, error) {
	if rateRepository == nil {
		return nil, fmt.Errorf("%w: exchange rate repository is required", ErrValidation)
	}
	return &RateService{
		rateRepository: rateRepository,
		now:            time.Now,
	}, nil
}

func (s *RateService) SetManualRate(ctx context.Context, input SetManualRateInput) (*domain.ExchangeRate, error) {
	if s.rateRepository == nil {
		return nil, fmt.Errorf("rate service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	fromCurrency := normalizeCurrencyCode(input.FromCurrency)
	toCurrency := normalizeCurrencyCode(input.ToCurrency)
	if fromCurrency == "" {
		return nil, fmt.Errorf("%w: from_currency is required", ErrValidation)
	}
	if toCurrency == "" {
		return nil, fmt.Errorf("%w: to_currency is required", ErrValidation)
	}
	if fromCurrency == toCurrency {
		return nil, fmt.Errorf("%w: from_currency and to_currency must be different", ErrValidation)
	}

	rate := normalizeAmount(input.Rate)
	parsedRate, err := parseAmount(rate)
	if err != nil {
		return nil, fmt.Errorf("%w: invalid rate", ErrValidation)
	}
	if parsedRate.Sign() <= 0 {
		return nil, fmt.Errorf("%w: rate must be greater than 0", ErrValidation)
	}

	validAt := input.ValidAt
	if validAt.IsZero() {
		validAt = s.now().UTC()
	} else {
		validAt = validAt.UTC()
	}

	created, err := s.rateRepository.Upsert(ctx, &domain.ExchangeRate{
		UserID:       input.UserID,
		FromCurrency: fromCurrency,
		ToCurrency:   toCurrency,
		Rate:         rate,
		Source:       manualRateSource,
		ValidAt:      validAt,
	})
	if err != nil {
		return nil, fmt.Errorf("set manual rate: %w", err)
	}
	return created, nil
}

func (s *RateService) GetRates(ctx context.Context, input GetRatesInput) ([]*domain.ExchangeRate, error) {
	if s.rateRepository == nil {
		return nil, fmt.Errorf("rate service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	rates, err := s.rateRepository.ListByUser(ctx, input.UserID)
	if err != nil {
		return nil, fmt.Errorf("list rates: %w", err)
	}
	return rates, nil
}

func (s *RateService) GetLatestRate(ctx context.Context, input GetLatestRateInput) (*domain.ExchangeRate, error) {
	if s.rateRepository == nil {
		return nil, fmt.Errorf("rate service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	fromCurrency := normalizeCurrencyCode(input.FromCurrency)
	toCurrency := normalizeCurrencyCode(input.ToCurrency)
	if fromCurrency == "" {
		return nil, fmt.Errorf("%w: from_currency is required", ErrValidation)
	}
	if toCurrency == "" {
		return nil, fmt.Errorf("%w: to_currency is required", ErrValidation)
	}
	if fromCurrency == toCurrency {
		return nil, fmt.Errorf("%w: from_currency and to_currency must be different", ErrValidation)
	}

	rate, err := s.rateRepository.GetLatestForPair(ctx, input.UserID, fromCurrency, toCurrency)
	if err != nil {
		if isNotFound(err) {
			return nil, fmt.Errorf("%w: rate not found", ErrValidation)
		}
		return nil, fmt.Errorf("get latest rate: %w", err)
	}
	return rate, nil
}

