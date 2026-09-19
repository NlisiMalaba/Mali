import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/usecases/allocate_to_goal_usecase.dart';
import 'package:mali_app/presentation/utils/goal_milestone_messages.dart';

void main() {
  test('returns the halfway copy for the 50% milestone', () {
    expect(
      GoalMilestoneMessages.forMilestone(GoalMilestone.half),
      "You're halfway there!",
    );
  });

  test('returns copy for each remaining milestone', () {
    expect(
      GoalMilestoneMessages.forMilestone(GoalMilestone.quarter),
      "You're a quarter of the way there!",
    );
    expect(
      GoalMilestoneMessages.forMilestone(GoalMilestone.threeQuarter),
      "You're three-quarters of the way there!",
    );
    expect(
      GoalMilestoneMessages.forMilestone(GoalMilestone.complete),
      'You reached your goal!',
    );
  });
}
