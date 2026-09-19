import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/usecases/create_goal_usecase.dart';
import 'package:mali_app/domain/usecases/update_goal_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/models/goal_preset.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/goal_form_validators.dart';
import 'package:mali_app/presentation/utils/goal_savings_hint.dart';
import 'package:mali_app/presentation/utils/shell_insets.dart';
import 'package:mali_app/presentation/widgets/wallet/currency_option_card.dart';

class AddGoalSheet extends ConsumerStatefulWidget {
  const AddGoalSheet({
    this.now,
    this.initialDeadline,
    this.existingGoal,
    super.key,
  });

  static const int maxDeadlineYearsAhead = 10;
  static const Key sheetKey = Key('add-goal-sheet');

  /// Clock used for the live savings hint and date picker bounds.
  final DateTime? now;
  final DateTime? initialDeadline;
  final SavingsGoal? existingGoal;

  static Future<bool?> show(
    BuildContext context, {
    SavingsGoal? goal,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddGoalSheet(existingGoal: goal),
    );
  }

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  GoalPreset? _selectedPreset;
  String? _selectedEmoji;
  CurrencyCode? _selectedCurrency;
  DateTime? _deadline;
  bool _isSubmitting = false;
  bool _submitted = false;
  final _touchedFields = <String>{};

  DateTime get _now => widget.now ?? DateTime.now();

  DateTime get _tomorrow {
    final now = _now;
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  DateTime get _latestDeadline {
    final now = _now;
    return DateTime(
      now.year + AddGoalSheet.maxDeadlineYearsAhead,
      now.month,
      now.day,
    );
  }

  bool get _isEditing => widget.existingGoal != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGoal;
    if (existing != null) {
      _nameController.text = existing.name;
      _amountController.text = existing.targetAmount;
      _selectedEmoji = existing.emoji;
      _deadline = existing.targetDate ?? widget.initialDeadline;
      _selectedPreset = GoalPreset.matching(
        name: existing.name,
        emoji: existing.emoji,
      );
      try {
        _selectedCurrency = CurrencyCode(existing.currencyCode);
      } on ArgumentError {
        _selectedCurrency = null;
      }
    } else {
      _deadline = widget.initialDeadline;
    }
    _amountController.addListener(_rebuildForHint);
  }

  @override
  void dispose() {
    _amountController.removeListener(_rebuildForHint);
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _rebuildForHint() => setState(() {});

  bool _isTouched(String field) => _submitted || _touchedFields.contains(field);

  void _markTouched(String field) {
    setState(() => _touchedFields.add(field));
    _formKey.currentState?.validate();
  }

  void _selectPreset(GoalPreset preset) {
    final previous = _selectedPreset;
    setState(() {
      _selectedPreset = preset;
      if (preset == GoalPreset.custom) {
        return;
      }
      final currentName = _nameController.text.trim();
      if (currentName.isEmpty || currentName == previous?.label) {
        _nameController.text = preset.label;
      }
      _selectedEmoji = preset.emoji;
    });
  }

  Future<void> _pickDeadline() async {
    final initial = _deadline ?? _tomorrow;
    final initialDate = initial.isBefore(_tomorrow) ? _tomorrow : initial;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _tomorrow,
      lastDate: _latestDeadline,
    );
    if (picked == null) {
      return;
    }
    setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _touchedFields
        ..add('name')
        ..add('amount');
    });

    if (_selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a currency for this goal.')),
      );
      return;
    }

    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a deadline for this goal.')),
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

    final Either<Failure, SavingsGoal> result;
    if (_isEditing) {
      result = await ref.read(updateGoalUseCaseProvider)(
        UpdateGoalParams(
          goalId: widget.existingGoal!.id,
          name: _nameController.text,
          emoji: _selectedEmoji,
          currencyCode: _selectedCurrency!,
          targetAmount: _amountController.text,
          deadline: _deadline!,
        ),
      );
    } else {
      result = await ref.read(createGoalUseCaseProvider)(
        CreateGoalParams(
          userId: user.id,
          name: _nameController.text,
          emoji: _selectedEmoji,
          currencyCode: _selectedCurrency!,
          targetAmount: _amountController.text,
          deadline: _deadline!,
        ),
      );
    }

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
    final savingsHint = GoalSavingsHint.saveEachMonth(
      targetAmount: _amountController.text,
      currencyCode: _selectedCurrency?.value,
      deadline: _deadline,
      now: _now,
      savedAmount: widget.existingGoal?.currentAmount ?? '0',
    );

    return Padding(
      key: AddGoalSheet.sheetKey,
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
                _isEditing ? 'Edit goal' : 'Add goal',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Text(
                'What are you saving for?',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in GoalPreset.values)
                    ChoiceChip(
                      key: Key('goal-preset-${preset.id}'),
                      label: Text('${preset.emoji} ${preset.label}'),
                      selected: _selectedPreset == preset,
                      onSelected: (_) => _selectPreset(preset),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('goal-name-field'),
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Goal name',
                ),
                onTapOutside: (_) => _markTouched('name'),
                onEditingComplete: () => _markTouched('name'),
                validator: (value) => GoalFormValidators.goalName(
                  value,
                  touched: _isTouched('name'),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Emoji',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final emoji in GoalPreset.emojiChoices)
                    _EmojiChoice(
                      emoji: emoji,
                      isSelected: _selectedEmoji == emoji,
                      onTap: () => setState(() => _selectedEmoji = emoji),
                    ),
                ],
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
                key: const Key('goal-amount-field'),
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
                  labelText: 'Target amount',
                  suffixText: _selectedCurrency?.value,
                ),
                onTapOutside: (_) => _markTouched('amount'),
                onEditingComplete: () => _markTouched('amount'),
                validator: (value) => GoalFormValidators.targetAmount(
                  value,
                  touched: _isTouched('amount'),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Deadline',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('goal-deadline-button'),
                onPressed: _pickDeadline,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _deadline == null
                      ? 'Choose a date'
                      : DateFormat.yMMMd().format(_deadline!),
                ),
              ),
              if (savingsHint != null) ...[
                const SizedBox(height: 16),
                Text(
                  savingsHint,
                  key: const Key('goal-savings-hint'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.tealPrimaryDark,
                    fontWeight: FontWeight.w600,
                  ),
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
                    : Text(_isEditing ? 'Save changes' : 'Save goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiChoice extends StatelessWidget {
  const _EmojiChoice({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  static const double size = 44;
  static const double emojiFontSize = 22;
  static const double selectedBorderWidth = 2;

  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      key: Key('goal-emoji-$emoji'),
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: selectedBorderWidth,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: emojiFontSize)),
          ),
        ),
      ),
    );
  }
}
