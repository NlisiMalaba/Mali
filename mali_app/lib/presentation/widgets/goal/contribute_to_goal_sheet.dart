import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/core/utils/local_id_generator.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/usecases/allocate_to_goal_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/utils/goal_form_validators.dart';
import 'package:mali_app/presentation/utils/shell_insets.dart';
import 'package:mali_app/presentation/widgets/goal/milestone_celebration_overlay.dart';
import 'package:mali_app/presentation/widgets/wallet/currency_option_card.dart';

class ContributeToGoalSheet extends ConsumerStatefulWidget {
  const ContributeToGoalSheet({
    required this.goal,
    super.key,
  });

  static const Key sheetKey = Key('contribute-to-goal-sheet');
  static const String contributionIdPrefix = 'contrib';

  final SavingsGoal goal;

  static Future<AllocateToGoalResult?> show(
    BuildContext context, {
    required SavingsGoal goal,
  }) async {
    final result = await showModalBottomSheet<AllocateToGoalResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ContributeToGoalSheet(goal: goal),
    );

    if (result != null &&
        result.reachedMilestones.isNotEmpty &&
        context.mounted) {
      await MilestoneCelebrationOverlay.show(
        context,
        milestone: result.reachedMilestones.last,
      );
    }

    return result;
  }

  @override
  ConsumerState<ContributeToGoalSheet> createState() =>
      _ContributeToGoalSheetState();
}

class _ContributeToGoalSheetState extends ConsumerState<ContributeToGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  CurrencyCode? _selectedCurrency;
  bool _isSubmitting = false;
  bool _submitted = false;
  final _touchedFields = <String>{};

  @override
  void initState() {
    super.initState();
    try {
      _selectedCurrency = CurrencyCode(widget.goal.currencyCode);
    } on ArgumentError {
      _selectedCurrency = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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
        ..add('amount')
        ..add('note');
    });

    if (_selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a currency for this contribution.')),
      );
      return;
    }

    if (_selectedCurrency!.value != widget.goal.currencyCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contribution currency must match goal currency.'),
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final note = _noteController.text.trim();
    final result = await ref.read(allocateToGoalUseCaseProvider)(
      contribution: GoalContribution(
        id: LocalIdGenerator.newId(ContributeToGoalSheet.contributionIdPrefix),
        goalId: widget.goal.id,
        amount: _amountController.text.trim(),
        currencyCode: _selectedCurrency!.value,
        note: note.isEmpty ? null : note,
        contributionDate: now,
        isSynced: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    final failure = result.fold((left) => left, (_) => null);
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      return;
    }

    final allocated = result.getOrElse(
      (_) => throw StateError('expected allocate result'),
    );
    Navigator.of(context).pop(allocated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      key: ContributeToGoalSheet.sheetKey,
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
                'Add contribution',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                widget.goal.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
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
                key: const Key('contribution-amount-field'),
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}'),
                  ),
                ],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  suffixText: _selectedCurrency?.value,
                ),
                onTapOutside: (_) => _markTouched('amount'),
                onEditingComplete: () => _markTouched('amount'),
                validator: (value) => GoalFormValidators.contributionAmount(
                  value,
                  touched: _isTouched('amount'),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('contribution-note-field'),
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLength: GoalFormValidators.maxNoteLength,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
                onTapOutside: (_) => _markTouched('note'),
                onEditingComplete: () => _markTouched('note'),
                validator: (value) => GoalFormValidators.contributionNote(
                  value,
                  touched: _isTouched('note'),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('contribute-submit-button'),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save contribution'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
