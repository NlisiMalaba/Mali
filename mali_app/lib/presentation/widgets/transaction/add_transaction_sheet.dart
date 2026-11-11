import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/mappers/add_transaction_mapper.dart';
import 'package:mali_app/application/providers/add_transaction_provider.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/receipt_scan_providers.dart';
import 'package:mali_app/application/providers/recent_wallets_provider.dart';
import 'package:mali_app/application/providers/transfer_exchange_rate_provider.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/repositories/receipt_text_recognizer.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/receipt_scan.dart';
import 'package:mali_app/presentation/constants/system_categories.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/amount_keypad_input.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';
import 'package:mali_app/presentation/widgets/transaction/category_selector.dart';
import 'package:mali_app/presentation/widgets/transaction/numeric_keypad.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_success_overlay.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_type_toggle.dart';
import 'package:mali_app/presentation/widgets/transaction/transfer_exchange_rate_field.dart';
import 'package:mali_app/presentation/widgets/transaction/wallet_selector.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({
    this.initialWalletId,
    super.key,
  });

  final String? initialWalletId;

  static Future<bool?> show(
    BuildContext context, {
    String? initialWalletId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height,
        child: AddTransactionSheet(
          initialWalletId: initialWalletId,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _notesController = TextEditingController();
  final _exchangeRateController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _amount = AmountKeypadInput.initialValue;
  CurrencyCode _currency = CurrencyCode.usd;
  Category? _selectedCategory;
  String? _fromWalletId;
  String? _toWalletId;
  String? _exchangeRate;
  String? _loadedExchangeRateKey;
  DateTime _transactionDate = DateTime.now();
  bool _submitted = false;
  bool _defaultWalletApplied = false;
  bool _showSuccess = false;
  bool _isScanning = false;

  static const _successDismissDelay = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _fromWalletId = widget.initialWalletId;
    _selectedCategory = _defaultCategoryFor(_type);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  Category _defaultCategoryFor(TransactionType type) {
    final categories = SystemCategories.gridForType(type.value);
    return categories.firstWhere(
      (category) => category.id == 'cat-groceries',
      orElse: () => categories.first,
    );
  }

  bool get _hasValidAmount => AmountKeypadInput.isPositive(_amount);

  bool get _needsExchangeRate {
    if (_type != TransactionType.transfer) {
      return false;
    }
    final fromWallet = _findWallet(_fromWalletId);
    final toWallet = _findWallet(_toWalletId);
    if (fromWallet == null || toWallet == null) {
      return false;
    }
    return fromWallet.currencyCode != toWallet.currencyCode;
  }

  bool get _canSubmit {
    if (!_hasValidAmount || _fromWalletId == null) {
      return false;
    }
    if (_type == TransactionType.transfer) {
      if (_toWalletId == null || _toWalletId == _fromWalletId) {
        return false;
      }
      if (_needsExchangeRate && !isValidExchangeRate(_exchangeRate)) {
        return false;
      }
    }
    return true;
  }

  Wallet? _findWallet(String? walletId, [List<Wallet>? wallets]) {
    if (walletId == null) {
      return null;
    }
    final source = wallets;
    if (source == null) {
      return null;
    }
    for (final wallet in source) {
      if (wallet.id == walletId) {
        return wallet;
      }
    }
    return null;
  }

  void _applyDefaultWallet(List<Wallet> wallets) {
    if (_defaultWalletApplied || wallets.isEmpty) {
      return;
    }

    final defaultId = ref.read(
      defaultWalletIdProvider(
        (
          walletIds: wallets.map((wallet) => wallet.id).toList(),
          preferredWalletId: widget.initialWalletId,
        ),
      ),
    );

    if (defaultId == null) {
      return;
    }

    _defaultWalletApplied = true;
    final wallet = _findWallet(defaultId, wallets);
    if (wallet == null) {
      return;
    }

    setState(() {
      _fromWalletId = wallet.id;
      _syncCurrencyFromWallet(wallet);
    });
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      final categories = SystemCategories.gridForType(type.value);
      _selectedCategory = categories.firstWhere(
        (category) => category.id == _selectedCategory?.id,
        orElse: () => _defaultCategoryFor(type),
      );
      if (type != TransactionType.transfer) {
        _toWalletId = null;
        _clearExchangeRate();
      }
    });
  }

  void _syncCurrencyFromWallet(Wallet? wallet) {
    if (wallet == null) {
      return;
    }
    try {
      _currency = CurrencyCode(wallet.currencyCode);
    } catch (_) {
      // Keep current selection when wallet currency is unsupported.
    }
  }

  void _onFromWalletChanged(Wallet wallet) {
    setState(() {
      _fromWalletId = wallet.id;
      _syncCurrencyFromWallet(wallet);
      if (_toWalletId == wallet.id) {
        _toWalletId = null;
      }
      _clearExchangeRate();
    });
  }

  void _onToWalletChanged(Wallet wallet) {
    setState(() {
      _toWalletId = wallet.id;
      _clearExchangeRate();
    });
  }

  void _clearExchangeRate() {
    _exchangeRate = null;
    _loadedExchangeRateKey = null;
    _exchangeRateController.clear();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _transactionDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _transactionDate.hour,
          _transactionDate.minute,
        );
      });
    }
  }

  Future<void> _pickWallet(List<Wallet> wallets) async {
    if (wallets.isEmpty) {
      return;
    }
    final selected = await showModalBottomSheet<Wallet>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final wallet in wallets)
              ListTile(
                key: Key('wallet-picker-${wallet.id}'),
                leading: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.success,
                ),
                title: Text(wallet.name),
                subtitle: Text(wallet.currencyCode),
                trailing: wallet.id == _fromWalletId
                    ? const Icon(Icons.check, color: AppColors.navy)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(wallet),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      await ref.read(recentWalletsProvider.notifier).recordUsage(selected.id);
      _onFromWalletChanged(selected);
    }
  }

  Future<void> _scanReceipt() async {
    final source = await showModalBottomSheet<ReceiptImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('receipt-source-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ReceiptImageSource.camera),
            ),
            ListTile(
              key: const Key('receipt-source-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ReceiptImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) {
      return;
    }

    setState(() => _isScanning = true);
    final result = await ref.read(scanReceiptUseCaseProvider)(source);
    if (!mounted) {
      return;
    }
    setState(() => _isScanning = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (scan) {
        if (scan == null) {
          return;
        }
        _applyReceiptScan(scan);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              scan.amount == null
                  ? 'Couldn\'t find a total — enter the amount.'
                  : 'Filled from receipt. Check the amount before saving.',
            ),
          ),
        );
      },
    );
  }

  void _applyReceiptScan(ReceiptScan scan) {
    setState(() {
      final currency = scan.currency;
      if (currency != null) {
        _currency = currency;
      }
      final amount = scan.amount;
      if (amount != null) {
        _amount = AmountKeypadInput.clampToDecimalPlaces(
          amount,
          _currency.decimalPlaces,
        );
      }
      final date = scan.date;
      if (date != null) {
        _transactionDate = DateTime(
          date.year,
          date.month,
          date.day,
          _transactionDate.hour,
          _transactionDate.minute,
        );
      }
      final merchant = scan.merchant;
      if (merchant != null && _notesController.text.trim().isEmpty) {
        _notesController.text = merchant;
      }
    });
  }

  String _transactionTitle() {
    if (_selectedCategory != null) {
      return _selectedCategory!.name;
    }
    return switch (_type) {
      TransactionType.income => 'Income',
      TransactionType.transfer => 'Transfer',
      _ => 'Expense',
    };
  }

  String? _optionalNotes() {
    final notes = _notesController.text.trim();
    return notes.isEmpty ? null : notes;
  }

  String _walletLabel(Wallet? wallet) {
    if (wallet == null) {
      return 'Select wallet';
    }
    return '${wallet.name} · ${wallet.currencyCode}';
  }

  String _dateLabel() {
    final now = DateTime.now();
    final isToday = _transactionDate.year == now.year &&
        _transactionDate.month == now.month &&
        _transactionDate.day == now.day;
    if (isToday) {
      return 'Today';
    }
    return DateFormat.MMMd().format(_transactionDate);
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_canSubmit) {
      final message = !_hasValidAmount
          ? 'Enter an amount greater than zero.'
          : _type == TransactionType.transfer && _toWalletId == null
              ? 'Select a destination wallet for the transfer.'
              : _needsExchangeRate && !isValidExchangeRate(_exchangeRate)
                  ? 'Enter a valid exchange rate for this transfer.'
                  : 'Select a wallet for this transaction.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    final user = ref.read(authProvider).value;
    if (user == null) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(false);
      return;
    }

    final input = AddTransactionInput(
      userId: user.id,
      type: _type.value,
      amount: AmountKeypadInput.toCanonicalAmount(_amount),
      currencyCode: _currency.value,
      walletId: _fromWalletId!,
      categoryId: _selectedCategory?.id,
      exchangeRate: _needsExchangeRate ? _exchangeRate?.trim() : null,
      title: _transactionTitle(),
      notes: _optionalNotes(),
      transactionDate: _transactionDate,
    );

    await ref.read(addTransactionProvider.notifier).submit(input);
  }

  void _handleSubmitStateChange(
    AsyncValue<void>? previous,
    AsyncValue<void> next,
  ) {
    if (!mounted) {
      return;
    }

    if (next.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(addTransactionErrorMessage(next.error!)),
        ),
      );
      return;
    }

    if (next.hasValue && (previous?.isLoading ?? false)) {
      setState(() => _showSuccess = true);
      Future<void>.delayed(_successDismissDelay, () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(activeWalletsProvider);
    final submitState = ref.watch(addTransactionProvider);
    final isSaving = submitState.isLoading;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    ref.listen(addTransactionProvider, _handleSubmitStateChange);

    return Material(
      color: AppColors.navy,
      child: walletsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.silver),
        ),
        error: (error, _) => Center(
          child: Text(
            'Could not load wallets: $error',
            style: const TextStyle(color: AppColors.silver),
          ),
        ),
        data: (wallets) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _applyDefaultWallet(wallets);
          });

          final fromWallet = _findWallet(_fromWalletId, wallets);
          final toWallet = _findWallet(_toWalletId, wallets);
          final suggestedRateAsync = fromWallet != null &&
                  toWallet != null &&
                  fromWallet.currencyCode != toWallet.currencyCode
              ? ref.watch(
                  suggestedTransferExchangeRateProvider(
                    (
                      fromCurrency: fromWallet.currencyCode,
                      toCurrency: toWallet.currencyCode,
                    ),
                  ),
                )
              : null;

          final suggestedRate = suggestedRateAsync?.asData?.value;

          if (_needsExchangeRate &&
              _loadedExchangeRateKey == null &&
              suggestedRate != null &&
              (_exchangeRate == null || _exchangeRate!.isEmpty)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _loadedExchangeRateKey != null) {
                return;
              }
              setState(() {
                _loadedExchangeRateKey =
                    '${fromWallet!.currencyCode}->${toWallet!.currencyCode}';
                _exchangeRate = suggestedRate;
                _exchangeRateController.text = suggestedRate;
              });
            });
          }

          return Stack(
            children: [
              Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _walletLabel(fromWallet),
                            style: const TextStyle(
                              color: AppColors.onNavyMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceBright,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: AbsorbPointer(
                        absorbing: isSaving || _showSuccess,
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDim,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  20,
                                  14,
                                  20,
                                  12 + bottomInset,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            TransactionTypeToggle(
                                              selected: _type,
                                              onChanged: _onTypeChanged,
                                            ),
                                            const SizedBox(height: 18),
                                            _AmountDisplay(
                                              amount: _amount,
                                              currency: _currency,
                                            ),
                                            if (_type ==
                                                TransactionType.expense) ...[
                                              const SizedBox(height: 16),
                                              _ScanReceiptCard(
                                                isScanning: _isScanning,
                                                onTap: _isScanning
                                                    ? null
                                                    : _scanReceipt,
                                              ),
                                            ],
                                            const SizedBox(height: 14),
                                            CategorySelector(
                                              transactionType: _type.value,
                                              selectedCategory:
                                                  _selectedCategory,
                                              onCategorySelected: (category) {
                                                setState(
                                                  () => _selectedCategory =
                                                      category,
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 14),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _MetaChip(
                                                    icon: Icons
                                                        .account_balance_wallet_outlined,
                                                    label: _walletLabel(
                                                      fromWallet,
                                                    ),
                                                    onTap: () =>
                                                        _pickWallet(wallets),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: _MetaChip(
                                                    icon: Icons
                                                        .calendar_today_outlined,
                                                    label: _dateLabel(),
                                                    onTap: _pickDate,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (_type ==
                                                TransactionType.transfer) ...[
                                              const SizedBox(height: 12),
                                              WalletSelector(
                                                wallets: wallets,
                                                mode:
                                                    WalletSelectorMode.transfer,
                                                fromWalletId: _fromWalletId,
                                                toWalletId: _toWalletId,
                                                onFromWalletChanged:
                                                    _onFromWalletChanged,
                                                onToWalletChanged:
                                                    _onToWalletChanged,
                                                exchangeRateController:
                                                    _exchangeRateController,
                                                suggestedExchangeRate:
                                                    suggestedRate,
                                                onExchangeRateChanged: (value) {
                                                  setState(
                                                    () => _exchangeRate = value,
                                                  );
                                                },
                                              ),
                                            ],
                                            if (_submitted && !_canSubmit) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'Complete required fields before saving.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppColors.error,
                                                    ),
                                              ),
                                            ],
                                            const SizedBox(height: 12),
                                            NumericKeypad(
                                              amount: _amount,
                                              currency: _currency,
                                              onChanged: (value) => setState(
                                                () => _amount = value,
                                              ),
                                              showAmountDisplay: false,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _SaveButton(
                                      label: _type.saveLabel,
                                      isLoading: isSaving,
                                      onPressed: isSaving ? null : _submit,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showSuccess) const TransactionSuccessOverlay(),
            ],
          );
        },
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({
    required this.amount,
    required this.currency,
  });

  final String amount;
  final CurrencyCode currency;

  @override
  Widget build(BuildContext context) {
    final digits = AmountKeypadInput.formatDisplay(
      amount,
      currency.decimalPlaces,
    );
    final symbol = CurrencyDisplay.symbol(currency);

    return Column(
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                symbol,
                style: AppTypography.money(
                  fontSize: 28,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              digits,
              style: AppTypography.money(
                fontSize: 56,
                color: AppColors.navy,
              ).copyWith(letterSpacing: -2),
            ),
            const SizedBox(width: 4),
            Container(
              width: 3,
              height: 44,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE1E5EE)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.link.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FilledButton(
          key: const Key('add-transaction-submit'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.silver,
            disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.silver,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}

class _ScanReceiptCard extends StatelessWidget {
  const _ScanReceiptCard({required this.isScanning, required this.onTap});

  final bool isScanning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('add-transaction-scan-receipt'),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.navy,
                Color(0xFF1D3570),
                AppColors.navy,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.silver,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isScanning
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.navy,
                          ),
                        )
                      : const Icon(
                          Icons.document_scanner_outlined,
                          color: AppColors.navy,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isScanning ? 'Reading receipt…' : 'Scan a receipt',
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const Text(
                        'Fills amount, date and shop for you',
                        style: TextStyle(
                          color: AppColors.onNavyMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.silver),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
