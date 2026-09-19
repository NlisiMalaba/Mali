import 'package:mali_app/data/local/dao/goal_dao.dart';
import 'package:mali_app/data/local/mappers/goal_mapper.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';

class LocalGoalRepository implements IGoalRepository {
  const LocalGoalRepository({
    required GoalDao goalDao,
  }) : _goalDao = goalDao;

  final GoalDao _goalDao;

  @override
  Future<void> saveGoal(SavingsGoal goal) {
    return _goalDao.upsertGoal(GoalMapper.toGoalCompanion(goal));
  }

  @override
  Stream<List<SavingsGoal>> watchActiveGoals() {
    return _goalDao.watchActiveGoals().map(GoalMapper.toDomainList);
  }

  @override
  Future<List<SavingsGoal>> listActiveGoals() async {
    return GoalMapper.toDomainList(await _goalDao.listActiveGoals());
  }

  @override
  Future<void> addContribution(GoalContribution contribution) {
    return _goalDao.addContribution(
      GoalMapper.toContributionCompanion(contribution),
    );
  }

  @override
  Stream<List<GoalContribution>> watchContributions(String goalId) {
    return _goalDao
        .watchContributions(goalId)
        .map(GoalMapper.toContributionDomainList);
  }
}
