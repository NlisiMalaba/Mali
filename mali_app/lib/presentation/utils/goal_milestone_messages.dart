import 'package:mali_app/domain/usecases/allocate_to_goal_usecase.dart';

class GoalMilestoneMessages {
  const GoalMilestoneMessages._();

  static String forMilestone(GoalMilestone milestone) => switch (milestone) {
        GoalMilestone.quarter => "You're a quarter of the way there!",
        GoalMilestone.half => "You're halfway there!",
        GoalMilestone.threeQuarter => "You're three-quarters of the way there!",
        GoalMilestone.complete => 'You reached your goal!',
      };

  static String emojiFor(GoalMilestone milestone) => switch (milestone) {
        GoalMilestone.quarter => '🎯',
        GoalMilestone.half => '🎉',
        GoalMilestone.threeQuarter => '🔥',
        GoalMilestone.complete => '🏆',
      };
}
