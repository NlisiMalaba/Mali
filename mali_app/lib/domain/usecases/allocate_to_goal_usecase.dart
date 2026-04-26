import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';

class AllocateToGoalUseCase {
  const AllocateToGoalUseCase({
    required IGoalRepository goalRepository,
  }) : _goalRepository = goalRepository;

  final IGoalRepository _goalRepository;

  Future<Either<Failure, AllocateToGoalResult>> call({
    required GoalContribution contribution,
  }) async {
    final contributionAmount = _parseDecimal(contribution.amount);
    if (contributionAmount == null || contributionAmount <= Decimal.zero) {
      return left(
        const ValidationFailure(
          message: 'Contribution amount must be greater than zero.',
          field: 'amount',
        ),
      );
    }

    final goals = await _goalRepository.watchActiveGoals().first;
    SavingsGoal? goal;
    for (final item in goals) {
      if (item.id == contribution.goalId) {
        goal = item;
        break;
      }
    }

    if (goal == null) {
      return left(
        const NotFoundFailure(
          message: 'Goal not found.',
          resource: 'goal',
        ),
      );
    }

    if (goal.currencyCode != contribution.currencyCode) {
      return left(
        const ValidationFailure(
          message: 'Contribution currency must match goal currency.',
          field: 'currencyCode',
        ),
      );
    }

    final currentAmount = _parseDecimal(goal.currentAmount);
    final targetAmount = _parseDecimal(goal.targetAmount);
    if (currentAmount == null || targetAmount == null || targetAmount <= Decimal.zero) {
      return left(
        const StorageFailure(message: 'Goal amount values are invalid.'),
      );
    }

    final nextAmount = currentAmount + contributionAmount;

    final updatedGoal = goal.copyWith(
      currentAmount: nextAmount.toString(),
      isCompleted: nextAmount >= targetAmount,
      updatedAt: DateTime.now(),
    );

    try {
      await _goalRepository.addContribution(contribution);
      await _goalRepository.saveGoal(updatedGoal);
    } catch (error) {
      return left(
        StorageFailure(
          message: 'Failed to allocate contribution to goal.',
          cause: error,
        ),
      );
    }

    return right(
      AllocateToGoalResult(
        updatedGoal: updatedGoal,
        reachedMilestones: _crossedMilestones(
          previousAmount: currentAmount,
          currentAmount: nextAmount,
          targetAmount: targetAmount,
        ),
      ),
    );
  }

  List<GoalMilestone> _crossedMilestones({
    required Decimal previousAmount,
    required Decimal currentAmount,
    required Decimal targetAmount,
  }) {
    final milestones = <GoalMilestone>[];
    const all = [
      GoalMilestone.quarter,
      GoalMilestone.half,
      GoalMilestone.threeQuarter,
      GoalMilestone.complete,
    ];
    for (final milestone in all) {
      final thresholdAmount = targetAmount * milestone.threshold;
      if (previousAmount < thresholdAmount && currentAmount >= thresholdAmount) {
        milestones.add(milestone);
      }
    }
    return milestones;
  }

  Decimal? _parseDecimal(String value) {
    try {
      return Decimal.parse(value);
    } catch (_) {
      return null;
    }
  }
}

class AllocateToGoalResult {
  const AllocateToGoalResult({
    required this.updatedGoal,
    required this.reachedMilestones,
  });

  final SavingsGoal updatedGoal;
  final List<GoalMilestone> reachedMilestones;
}

enum GoalMilestone {
  quarter('0.25'),
  half('0.50'),
  threeQuarter('0.75'),
  complete('1');

  const GoalMilestone(this._thresholdValue);

  final String _thresholdValue;

  Decimal get threshold => Decimal.parse(_thresholdValue);
}
