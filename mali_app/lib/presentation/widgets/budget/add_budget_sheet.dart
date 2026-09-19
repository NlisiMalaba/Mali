import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/domain/usecases/create_budget_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/utils/budget_form_validators.dart';
import 'package:mali_app/presentation/utils/shell_insets.dart';
import 'package:mali_app/presentation/widgets/transaction/category_selector.dart';
import 'package:mali_app/presentation/widgets/wallet/currency_option_card.dart';

class AddBudgetSheet extends ConsumerStatefulWidget {
  const AddBudgetSheet({super.key});

  static const String expenseTransactionType = 'expense';

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddBudgetSheet(),
    );
  }

  @override
  ConsumerState<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  Category? _selectedCategory;
  CurrencyCode? _selectedCurrency;
  late int _selectedMonth;
  late int _selectedYear;
  bool _rolloverEnabled = false;
  bool _isSubmitting = false;
  bool _submitted = false;
  final _touchedFields = <String>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool _isTouched(String field) => _submitted || _touchedFields.contains(field);

  void _markTouched(String field) {
    setState(() => _touchedFields.add(field));
    _formKey.currentState?.validate();
  }

  List<int> get _yearOptions {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - 2 + index);
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _touchedFields.add('amount');
    });

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category for this budget.')),
      );
      return;
    }

    if (_selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a currency for this budget.')),
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

    final result = await ref.read(createBudgetUseCaseProvider)(
      CreateBudgetParams(
        userId: user.id,
        categoryId: _selectedCategory!.id,
        currencyCode: _selectedCurrency!,
        amount: _amountController.text,
        month: _selectedMonth,
        year: _selectedYear,
        rolloverEnabled: _rolloverEnabled,
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
                'Add budget',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Text(
                'Category',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              CategorySelector(
                transactionType: AddBudgetSheet.expenseTransactionType,
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Currency',
                style: theme.textTheme.titleSmall,
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
                      isSelected: _selectedCurrency == currency,
                      onTap: () => setState(() => _selectedCurrency = currency),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}'),
                  ),
                ],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Budget amount',
                  suffixText: _selectedCurrency?.value,
                ),
                onTapOutside: (_) => _markTouched('amount'),
                onEditingComplete: () => _markTouched('amount'),
                validator: (value) => BudgetFormValidators.budgetAmount(
                  value,
                  touched: _isTouched('amount'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('budget-month-$_selectedMonth'),
                      initialValue: _selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                      ),
                      items: [
                        for (var month = 1; month <= 12; month++)
                          DropdownMenuItem(
                            value: month,
                            child: Text(
                              DateFormat.MMMM().format(
                                DateTime(2000, month),
                              ),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _selectedMonth = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('budget-year-$_selectedYear'),
                      initialValue: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                      ),
                      items: [
                        for (final year in _yearOptions)
                          DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _selectedYear = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rollover unused amount'),
                subtitle: Text(
                  'Carry remaining budget into the next month',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                value: _rolloverEnabled,
                onChanged: (value) {
                  setState(() => _rolloverEnabled = value);
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
