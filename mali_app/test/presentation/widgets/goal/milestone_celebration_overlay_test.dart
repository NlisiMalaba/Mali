import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/usecases/allocate_to_goal_usecase.dart';
import 'package:mali_app/presentation/utils/goal_milestone_messages.dart';
import 'package:mali_app/presentation/widgets/goal/milestone_celebration_overlay.dart';
import 'package:mali_app/presentation/widgets/goal/milestone_confetti.dart';

Future<void> _openOverlay(
  WidgetTester tester, {
  required GoalMilestone milestone,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => MilestoneCelebrationOverlay.show(
              context,
              milestone: milestone,
            ),
            child: const Text('celebrate'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('celebrate'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows confetti, the halfway message, and auto-dismisses',
      (tester) async {
    await _openOverlay(tester, milestone: GoalMilestone.half);

    expect(find.byKey(MilestoneCelebrationOverlay.overlayKey), findsOneWidget);
    expect(find.byKey(MilestoneConfetti.confettiKey), findsOneWidget);
    expect(find.text("You're halfway there!"), findsOneWidget);

    await tester.pump(MilestoneCelebrationOverlay.autoDismissDuration);
    await tester.pumpAndSettle();

    expect(find.byKey(MilestoneCelebrationOverlay.overlayKey), findsNothing);
    expect(find.byKey(MilestoneConfetti.confettiKey), findsNothing);
    expect(find.text("You're halfway there!"), findsNothing);
  });

  testWidgets('shows a message for each 25/50/75/100% milestone',
      (tester) async {
    const cases = <GoalMilestone, String>{
      GoalMilestone.quarter: "You're a quarter of the way there!",
      GoalMilestone.half: "You're halfway there!",
      GoalMilestone.threeQuarter: "You're three-quarters of the way there!",
      GoalMilestone.complete: 'You reached your goal!',
    };

    for (final entry in cases.entries) {
      await _openOverlay(tester, milestone: entry.key);

      expect(find.byKey(MilestoneConfetti.confettiKey), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
      expect(
        GoalMilestoneMessages.forMilestone(entry.key),
        entry.value,
      );

      await tester.pump(MilestoneCelebrationOverlay.autoDismissDuration);
      await tester.pumpAndSettle();
    }
  });
}
