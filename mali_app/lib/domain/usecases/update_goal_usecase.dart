import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';
import 'package:mali_app/domain/usecases/create_goal_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

class UpdateGoalParams {
  const UpdateGoalParams({
    required this.goalId,
    required this.name,
    this.emoji,
    required this.currencyCode,
    required this.targetAmount,
    required this.deadline,
  });

  final String goalId;
  final String name;
  final String? emoji;
  final CurrencyCode currencyCode;
  final String targetAmount;
  final DateTime deadline;
}

class UpdateGoalUseCase {
  const UpdateGoalUseCase({
    required IGoalRepository goalRepository,
  }) : _goalRepository = goalRepository;

  final IGoalRepository _goalRepository;

  Future<Either<Failure, SavingsGoal>> call(UpdateGoalParams params) async {
    final trimmedName = params.name.trim();
    if (trimmedName.isEmpty) {
      return left(
        const ValidationFailure(
          message: 'Goal name is required.',
          field: 'name',
        ),
      );
    }

    if (trimmedName.length > CreateGoalUseCase.maxNameLength) {
      return left(
        ValidationFailure(
          message:
              'Goal name must be at most ${CreateGoalUseCase.maxNameLength} characters.',
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

    late final SavingsGoal existing;
    try {
      final goals = await _goalRepository.watchActiveGoals().first;
      SavingsGoal? match;
      for (final goal in goals) {
        if (goal.id == params.goalId) {
          match = goal;
          break;
        }
      }
      if (match == null) {
        return left(
          const NotFoundFailure(
            message: 'Goal not found.',
            resource: 'goal',
          ),
        );
      }
      existing = match;
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Could not load goal.',
          cause: error,
        ),
      );
    }

    final emoji = params.emoji?.trim();
    final current = _parseNonNegativeDecimal(existing.currentAmount);
    if (current == null) {
      return left(
        const StorageFailure(message: 'Goal amount values are invalid.'),
      );
    }

    final updated = existing.copyWith(
      name: trimmedName,
      emoji: (emoji == null || emoji.isEmpty) ? null : emoji,
      targetAmount: amount.toString(),
      currencyCode: params.currencyCode.value,
      targetDate: deadline,
      isCompleted: current >= amount,
      isSynced: false,
      updatedAt: DateTime.now(),
    );

    try {
      await _goalRepository.saveGoal(updated);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to update goal.',
          cause: error,
        ),
      );
    }

    return right(updated);
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

  Decimal? _parseNonNegativeDecimal(String value) {
    try {
      final parsed = Decimal.parse(value.trim());
      if (parsed < Decimal.zero) {
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
