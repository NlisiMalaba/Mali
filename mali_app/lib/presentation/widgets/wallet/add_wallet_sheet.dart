import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/usecases/create_wallet_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/utils/shell_insets.dart';
import 'package:mali_app/presentation/widgets/wallet/currency_option_card.dart';
import 'package:mali_app/presentation/widgets/wallet/wallet_draft_card.dart';

class AddWalletSheet extends ConsumerStatefulWidget {
  const AddWalletSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddWalletSheet(),
    );
  }

  @override
  ConsumerState<AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends ConsumerState<AddWalletSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  CurrencyCode? _selectedCurrency;

  bool _isSubmitting = false;
  bool _submitted = false;
  final _touchedFields = <String>{};

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  bool _isTouched(String field) => _submitted || _touchedFields.contains(field);

  void _markTouched(String field) {
    setState(() => _touchedFields.add(field));
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _touchedFields
        ..add('name')
        ..add('balance');
    });

    if (_selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a currency for this wallet.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = ref.read(authProvider).value;
    if (user == null) {
      if (!mounted) return;
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref.read(createWalletUseCaseProvider)(
      CreateWalletParams(
        userId: user.id,
        name: _nameController.text,
        currencyCode: _selectedCurrency!,
        openingBalance: _balanceController.text,
      ),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    final failure = result.fold((left) => left, (_) => null);
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: modalSheetPadding(context),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add wallet',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  for (final currency in CurrencyCode.values)
                    CurrencyOptionCard(
                      currency: currency,
                      isSelected: _selectedCurrency == currency,
                      onTap: () => setState(() => _selectedCurrency = currency),
                    ),
                ],
              ),
              if (_selectedCurrency != null) ...[
                const SizedBox(height: 20),
                WalletDraftCard(
                  currency: _selectedCurrency!,
                  nameController: _nameController,
                  balanceController: _balanceController,
                  nameTouched: _isTouched('name'),
                  balanceTouched: _isTouched('balance'),
                  onNameBlur: () => _markTouched('name'),
                  onBalanceBlur: () => _markTouched('balance'),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
