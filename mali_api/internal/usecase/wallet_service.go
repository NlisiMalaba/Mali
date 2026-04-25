package usecase

import (
	"context"
	"errors"
	"fmt"
	"math/big"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/mali-app/mali_api/internal/domain"
)

type CreateWalletInput struct {
	UserID     uuid.UUID
	Name       string
	Currency   string
	WalletType string
	Balance    string
}

type UpdateBalanceInput struct {
	UserID   uuid.UUID
	WalletID uuid.UUID
	Balance  string
}

type UpdateWalletNameInput struct {
	UserID   uuid.UUID
	WalletID uuid.UUID
	Name     string
}

type DeleteWalletInput struct {
	UserID   uuid.UUID
	WalletID uuid.UUID
}

type WalletService struct {
	walletRepository    domain.IWalletRepository
	supportedCurrencies map[string]struct{}
}

func NewWalletService(
	walletRepository domain.IWalletRepository,
	supportedCurrencies []string,
) (*WalletService, error) {
	if walletRepository == nil {
		return nil, fmt.Errorf("%w: wallet repository is required", ErrValidation)
	}

	currencySet := make(map[string]struct{}, len(supportedCurrencies))
	for _, code := range supportedCurrencies {
		normalized := normalizeCurrencyCode(code)
		if normalized == "" {
			continue
		}
		currencySet[normalized] = struct{}{}
	}
	if len(currencySet) == 0 {
		return nil, fmt.Errorf("%w: supported currencies are required", ErrValidation)
	}

	return &WalletService{
		walletRepository:    walletRepository,
		supportedCurrencies: currencySet,
	}, nil
}

func (s *WalletService) CreateWallet(ctx context.Context, input CreateWalletInput) (*domain.Wallet, error) {
	if s.walletRepository == nil {
		return nil, fmt.Errorf("wallet service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	name := strings.TrimSpace(input.Name)
	currency := normalizeCurrencyCode(input.Currency)
	walletType := strings.TrimSpace(input.WalletType)
	balance := normalizeAmount(input.Balance)
	if balance == "" {
		balance = "0"
	}

	if name == "" {
		return nil, fmt.Errorf("%w: wallet name is required", ErrValidation)
	}
	if walletType == "" {
		return nil, fmt.Errorf("%w: wallet_type is required", ErrValidation)
	}
	if !s.isSupportedCurrency(currency) {
		return nil, fmt.Errorf("%w: unsupported currency code", ErrValidation)
	}
	if _, err := parseAmount(balance); err != nil {
		return nil, fmt.Errorf("%w: invalid wallet balance", ErrValidation)
	}

	created, err := s.walletRepository.Create(ctx, &domain.Wallet{
		UserID:     input.UserID,
		Name:       name,
		Currency:   currency,
		WalletType: walletType,
		Balance:    balance,
		IsActive:   true,
	})
	if err != nil {
		return nil, fmt.Errorf("create wallet: %w", err)
	}
	return created, nil
}

func (s *WalletService) ListWallets(ctx context.Context, userID uuid.UUID) ([]*domain.Wallet, error) {
	if s.walletRepository == nil {
		return nil, fmt.Errorf("wallet service dependencies are not configured")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	wallets, err := s.walletRepository.ListByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list wallets: %w", err)
	}
	return wallets, nil
}

func (s *WalletService) UpdateBalance(ctx context.Context, input UpdateBalanceInput) error {
	if s.walletRepository == nil {
		return fmt.Errorf("wallet service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if input.WalletID == uuid.Nil {
		return fmt.Errorf("%w: wallet_id is required", ErrValidation)
	}

	balance := normalizeAmount(input.Balance)
	if balance == "" {
		return fmt.Errorf("%w: balance is required", ErrValidation)
	}
	if _, err := parseAmount(balance); err != nil {
		return fmt.Errorf("%w: invalid wallet balance", ErrValidation)
	}

	if _, err := s.getOwnedWallet(ctx, input.UserID, input.WalletID); err != nil {
		return err
	}

	if err := s.walletRepository.UpdateBalance(ctx, input.WalletID, balance); err != nil {
		return fmt.Errorf("update wallet balance: %w", err)
	}
	return nil
}

func (s *WalletService) UpdateName(ctx context.Context, input UpdateWalletNameInput) error {
	if s.walletRepository == nil {
		return fmt.Errorf("wallet service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if input.WalletID == uuid.Nil {
		return fmt.Errorf("%w: wallet_id is required", ErrValidation)
	}

	name := strings.TrimSpace(input.Name)
	if name == "" {
		return fmt.Errorf("%w: wallet name is required", ErrValidation)
	}

	if _, err := s.getOwnedWallet(ctx, input.UserID, input.WalletID); err != nil {
		return err
	}

	if err := s.walletRepository.UpdateName(ctx, input.WalletID, name); err != nil {
		return fmt.Errorf("update wallet name: %w", err)
	}
	return nil
}

func (s *WalletService) Delete(ctx context.Context, input DeleteWalletInput) error {
	if s.walletRepository == nil {
		return fmt.Errorf("wallet service dependencies are not configured")
	}
	if input.UserID == uuid.Nil {
		return fmt.Errorf("%w: user_id is required", ErrValidation)
	}
	if input.WalletID == uuid.Nil {
		return fmt.Errorf("%w: wallet_id is required", ErrValidation)
	}

	wallet, err := s.getOwnedWallet(ctx, input.UserID, input.WalletID)
	if err != nil {
		return err
	}

	amount, err := parseAmount(wallet.Balance)
	if err != nil {
		return fmt.Errorf("%w: invalid wallet balance", ErrValidation)
	}
	if amount.Sign() != 0 {
		return fmt.Errorf("%w: wallet with non-zero balance cannot be deleted", ErrValidation)
	}

	if err := s.walletRepository.SoftDelete(ctx, input.WalletID); err != nil {
		return fmt.Errorf("soft delete wallet: %w", err)
	}
	return nil
}

func (s *WalletService) isSupportedCurrency(code string) bool {
	_, ok := s.supportedCurrencies[code]
	return ok
}

func normalizeCurrencyCode(code string) string {
	return strings.ToUpper(strings.TrimSpace(code))
}

func normalizeAmount(amount string) string {
	return strings.TrimSpace(amount)
}

func parseAmount(value string) (*big.Rat, error) {
	amount := new(big.Rat)
	if _, ok := amount.SetString(value); !ok {
		return nil, fmt.Errorf("invalid amount")
	}
	return amount, nil
}

func isNotFound(err error) bool {
	return errors.Is(err, pgx.ErrNoRows)
}

func (s *WalletService) getOwnedWallet(ctx context.Context, userID, walletID uuid.UUID) (*domain.Wallet, error) {
	wallet, err := s.walletRepository.FindByID(ctx, walletID)
	if err != nil {
		if isNotFound(err) {
			return nil, fmt.Errorf("%w: wallet not found", ErrValidation)
		}
		return nil, fmt.Errorf("find wallet by id: %w", err)
	}
	if wallet.UserID != userID {
		return nil, fmt.Errorf("%w: wallet not found", ErrValidation)
	}
	return wallet, nil
}

