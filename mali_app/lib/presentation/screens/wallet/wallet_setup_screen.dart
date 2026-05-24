import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/usecases/create_wallet_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/widgets/wallet/currency_option_card.dart';
import 'package:mali_app/presentation/widgets/wallet/wallet_draft_card.dart';

class WalletSetupScreen extends ConsumerStatefulWidget {
  const WalletSetupScreen({super.key});

  @override
  ConsumerState<WalletSetupScreen> createState() => _WalletSetupScreenState();
}

class _WalletSetupScreenState extends ConsumerState<WalletSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _selectedCurrencies = <CurrencyCode>{};
  final _draftControllers = <CurrencyCode, _WalletDraftControllers>{};

  bool _isSubmitting = false;
  bool _submitted = false;
  final _touchedFields = <String>{};

  @override
  void dispose() {
    for (final draft in _draftControllers.values) {
      draft.dispose();
    }
    super.dispose();
  }

  void _toggleCurrency(CurrencyCode currency) {
    setState(() {
      if (_selectedCurrencies.contains(currency)) {
        _selectedCurrencies.remove(currency);
        _draftControllers.remove(currency)?.dispose();
      } else {
        _selectedCurrencies.add(currency);
        _draftControllers[currency] = _WalletDraftControllers(currency);
      }
    });
  }

  bool _isTouched(String fieldKey) =>
      _submitted || _touchedFields.contains(fieldKey);

  void _markTouched(String fieldKey) {
    setState(() => _touchedFields.add(fieldKey));
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      for (final currency in _selectedCurrencies) {
        _touchedFields
          ..add('name-$currency')
          ..add('balance-$currency');
      }
    });

    if (_selectedCurrencies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one currency to create a wallet.'),
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = ref.read(authProvider).value;
    if (user == null) {
      if (!mounted) return;
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        context.go('/auth/login');
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final useCase = ref.read(createWalletUseCaseProvider);
    for (final currency in _selectedCurrencies) {
      final draft = _draftControllers[currency]!;
      final result = await useCase(
        CreateWalletParams(
          userId: user.id,
          name: draft.nameController.text,
          currencyCode: currency,
          openingBalance: draft.balanceController.text,
        ),
      );

      if (!mounted) return;

      final failure = result.fold((left) => left, (_) => null);
      if (failure != null) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
        return;
      }
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up wallets'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create your first wallet',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose one or more currencies you use. '
                        'You can add a name and opening balance for each.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Currencies',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                              isSelected:
                                  _selectedCurrencies.contains(currency),
                              onTap: () => _toggleCurrency(currency),
                            ),
                        ],
                      ),
                      if (_selectedCurrencies.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Text(
                          'Wallet details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final currency
                            in CurrencyCode.values
                                .where(_selectedCurrencies.contains))
                          WalletDraftCard(
                            currency: currency,
                            nameController:
                                _draftControllers[currency]!.nameController,
                            balanceController: _draftControllers[currency]!
                                .balanceController,
                            nameTouched: _isTouched('name-$currency'),
                            balanceTouched: _isTouched('balance-$currency'),
                            onNameBlur: () => _markTouched('name-$currency'),
                            onBalanceBlur: () =>
                                _markTouched('balance-$currency'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletDraftControllers {
  _WalletDraftControllers(CurrencyCode currency)
      : nameController = TextEditingController(),
        balanceController = TextEditingController(text: '0');

  final TextEditingController nameController;
  final TextEditingController balanceController;

  void dispose() {
    nameController.dispose();
    balanceController.dispose();
  }
}
