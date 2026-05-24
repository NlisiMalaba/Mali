import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/exchange_rate_settings_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/exchange_rates/exchange_rate_catalog.dart';
import 'package:mali_app/domain/usecases/set_manual_exchange_rate_usecase.dart';
import 'package:mali_app/presentation/utils/exchange_rate_display.dart';
import 'package:mali_app/presentation/widgets/transaction/transfer_exchange_rate_field.dart';

class EditExchangeRateSheet extends ConsumerStatefulWidget {
  const EditExchangeRateSheet({
    required this.pair,
    this.initialRate,
    super.key,
  });

  final ExchangeRatePairRef pair;
  final String? initialRate;

  static Future<bool?> show(
    BuildContext context, {
    required ExchangeRatePairRef pair,
    String? initialRate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EditExchangeRateSheet(
        pair: pair,
        initialRate: initialRate,
      ),
    );
  }

  @override
  ConsumerState<EditExchangeRateSheet> createState() =>
      _EditExchangeRateSheetState();
}

class _EditExchangeRateSheetState extends ConsumerState<EditExchangeRateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rateController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(text: widget.initialRate ?? '');
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!isValidExchangeRate(_rateController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid rate greater than zero.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref.read(setManualExchangeRateUseCaseProvider)(
      SetManualExchangeRateParams(
        baseCurrency: widget.pair.base,
        quoteCurrency: widget.pair.quote,
        rate: _rateController.text.trim(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        ref.invalidate(exchangeRateSettingsItemsProvider);
        ref.invalidate(exchangeRatesLastUpdatedProvider);
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit rate',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              ExchangeRateDisplay.pairLabel(widget.pair.base, widget.pair.quote),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            TransferExchangeRateField(
              fromCurrency: widget.pair.base.value,
              toCurrency: widget.pair.quote.value,
              controller: _rateController,
              suggestedRate: null,
              onChanged: (_) {},
            ),
            const SizedBox(height: 8),
            Text(
              widget.pair.autoFetchedFromApi
                  ? 'Saving marks this pair as manual. Auto refresh will not overwrite it.'
                  : 'This pair is not available from the market feed. Set it manually.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save rate'),
            ),
          ],
        ),
      ),
    );
  }
}
