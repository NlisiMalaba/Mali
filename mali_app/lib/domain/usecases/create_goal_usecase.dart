import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/core/utils/local_id_generator.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

class CreateGoalParams {
  const CreateGoalParams({
    required this.userId,
    required this.name,
    this.emoji,
    required this.currencyCode,
    required this.targetAmount,
    required this.deadline,
  });

  final String userId;
  final String name;
  final String? emoji;
  final CurrencyCode currencyCode;
  final String targetAmount;
  final DateTime deadline;
}

class CreateGoalUseCase {
  const CreateGoalUseCase({
    required IGoalRepository goalRepository,
  }) : _goalRepository = goalRepository;

  final IGoalRepository _goalRepository;

  static const int maxNameLength = 120;

  Future<Either<Failure, SavingsGoal>> call(CreateGoalParams params) async {
    final trimmedName = params.name.trim();
    if (trimmedName.isEmpty) {
      return left(
        const ValidationFailure(
          message: 'Goal name is required.',
          field: 'name',
        ),
      );
    }

    if (trimmedName.length > maxNameLength) {
      return left(
        ValidationFailure(
          message: 'Goal name must be at most $maxNameLength characters.',
          field: 'name',
        ),
      );
    }

    final amount = _parsePositiveDecimal(params.targetAmount);
    if (amount == null) {
      return left(
        const ValidationFailure(
          message: 'Enter a target amount greater than zero.',
          field: 'targetAmount',
        ),
      );
    }

    final today = _dateOnly(DateTime.now());
    final deadline = _dateOnly(params.deadline);
    if (!deadline.isAfter(today)) {
      return left(
        const ValidationFailure(
          message: 'Deadline must be a future date.',
          field: 'deadline',
        ),
      );
    }

    final emoji = params.emoji?.trim();

    int nextPriority = 0;
    try {
      final existing = await _goalRepository.watchActiveGoals().first;
      for (final goal in existing) {
        if (goal.priorityOrder >= nextPriority) {
          nextPriority = goal.priorityOrder + 1;
        }
      }
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Could not load existing goals.',
          cause: error,
        ),
      );
    }

    final now = DateTime.now();
    final goal = SavingsGoal(
      id: LocalIdGenerator.newId('goal'),
      userId: params.userId,
      name: trimmedName,
      emoji: (emoji == null || emoji.isEmpty) ? null : emoji,
      targetAmount: amount.toString(),
      currentAmount: Decimal.zero.toString(),
      currencyCode: params.currencyCode.value,
      targetDate: deadline,
      priorityOrder: nextPriority,
      isCompleted: false,
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _goalRepository.saveGoal(goal);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to save goal.',
          cause: error,
        ),
      );
    }

    return right(goal);
  }

  Decimal? _parsePositiveDecimal(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final parsed = Decimal.parse(trimmed);
      if (parsed <= Decimal.zero) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
