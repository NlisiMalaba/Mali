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
import 'package:mali_app/presentation/utils/amount_keypad_input.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';
import 'package:mali_app/presentation/utils/shell_insets.dart';
import 'package:mali_app/presentation/widgets/transaction/category_selector.dart';
import 'package:mali_app/presentation/widgets/transaction/numeric_keypad.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_success_overlay.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_type_toggle.dart';
import 'package:mali_app/presentation/widgets/transaction/transfer_exchange_rate_field.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/widgets/sovereign/gradient_button.dart';
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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => AddTransactionSheet(
        initialWalletId: initialWalletId,
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
    _selectedCategory = SystemCategories.gridForType(_type.value).firstOrNull;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
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
        orElse: () => categories.first,
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
    final theme = Theme.of(context);
    final walletsAsync = ref.watch(activeWalletsProvider);
    final submitState = ref.watch(addTransactionProvider);
    final isSaving = submitState.isLoading;
    final dateLabel = DateFormat.yMMMd().format(_transactionDate);

    ref.listen(addTransactionProvider, _handleSubmitStateChange);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 50,
            offset: Offset(0, -20),
          ),
        ],
      ),
      child: Padding(
      padding: modalSheetPadding(context, top: 8),
      child: walletsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => Text('Could not load wallets: $error'),
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
              AbsorbPointer(
                absorbing: isSaving || _showSuccess,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  'TRANSACTION AMOUNT',
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionLabel(context).copyWith(
                    fontSize: 11,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CurrencyChip(
                      currency: _currency,
                      onTap: () => _showCurrencyPicker(context),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AmountKeypadInput.formatDisplay(
                        _amount,
                        _currency.decimalPlaces,
                      ),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TransactionTypeToggle(
                  selected: _type,
                  onChanged: _onTypeChanged,
                ),
                if (_type == TransactionType.expense) ...[
                  const SizedBox(height: 14),
                  _ScanReceiptCard(
                    isScanning: _isScanning,
                    onTap: _isScanning ? null : _scanReceipt,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Category',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                CategorySelector(
                  transactionType: _type.value,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() => _selectedCategory = category);
                  },
                ),
                const SizedBox(height: 20),
                NumericKeypad(
                  amount: _amount,
                  currency: _currency,
                  onChanged: (value) => setState(() => _amount = value),
                  showAmountDisplay: false,
                ),
                const SizedBox(height: 20),
                WalletSelector(
                  wallets: wallets,
                  mode: _type == TransactionType.transfer
                      ? WalletSelectorMode.transfer
                      : WalletSelectorMode.single,
                  fromWalletId: _fromWalletId,
                  toWalletId: _toWalletId,
                  onFromWalletChanged: _onFromWalletChanged,
                  onToWalletChanged: _onToWalletChanged,
                  exchangeRateController: _exchangeRateController,
                  suggestedExchangeRate: suggestedRate,
                  onExchangeRateChanged: (value) {
                    setState(() => _exchangeRate = value);
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional description',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(dateLabel),
                  ),
                ),
                if (_submitted && !_canSubmit) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Complete required fields before saving.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                GradientButton(
                  key: const Key('add-transaction-submit'),
                  label: 'Save transaction',
                  icon: Icons.arrow_forward,
                  isLoading: isSaving,
                  onPressed: isSaving ? null : _submit,
                ),
                    ],
                  ),
                ),
              ),
              if (_showSuccess) const TransactionSuccessOverlay(),
            ],
          );
        },
      ),
    ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final currency in CurrencyCode.values)
                ListTile(
                  key: Key('currency-${currency.value}'),
                  leading: Text(CurrencyDisplay.flagEmoji(currency)),
                  title: Text(currency.value),
                  trailing: _currency == currency
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _currency = currency;
                      _amount = AmountKeypadInput.clampToDecimalPlaces(
                        _amount,
                        currency.decimalPlaces,
                      );
                    });
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.currency,
    required this.onTap,
  });

  final CurrencyCode currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.secondaryContainer.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.payments_outlined,
              size: 18,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              currency.value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(
              Icons.expand_more,
              size: 18,
              color: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Navy call-to-action that opens the receipt scanner. Sits right under the
/// amount because scanning is the fastest way to log an expense.
class _ScanReceiptCard extends StatelessWidget {
  const _ScanReceiptCard({required this.isScanning, required this.onTap});

  final bool isScanning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('add-transaction-scan-receipt'),
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isScanning ? 'Reading receipt…' : 'Scan a receipt',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Fills amount, date and shop for you',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onNavyMuted,
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
    );
  }
}
