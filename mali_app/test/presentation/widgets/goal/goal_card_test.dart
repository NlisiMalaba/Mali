import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/widgets/goal/goal_card.dart';
import 'package:mali_app/presentation/widgets/goal/goal_progress_ring.dart';

SavingsGoal _goal({
  String name = 'Car',
  String? emoji = '🚗',
  String targetAmount = '4000.00',
  String currentAmount = '1000.00',
  DateTime? targetDate,
  bool isCompleted = false,
}) {
  return SavingsGoal(
    id: 'g-1',
    userId: 'u-1',
    name: name,
    emoji: emoji,
    targetAmount: targetAmount,
    currentAmount: currentAmount,
    currencyCode: 'USD',
    targetDate: targetDate,
    priorityOrder: 0,
    isCompleted: isCompleted,
    isSynced: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

PieChart _pieChart(WidgetTester tester) {
  return tester.widget<PieChart>(
    find.descendant(
      of: find.byType(GoalProgressRing),
      matching: find.byType(PieChart),
    ),
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required SavingsGoal goal,
  DateTime? now,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GoalCard(
          goal: goal,
          now: now ?? DateTime(2026, 9, 19),
          onTap: onTap,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('GoalCard', () {
    testWidgets(
        'shows name, emoji, amounts, fl_chart ring fill, milestones, and countdown',
        (tester) async {
      await _pumpCard(
        tester,
        goal: _goal(targetDate: DateTime(2026, 12, 19)),
      );

      expect(find.text('Car'), findsOneWidget);
      expect(find.text('🚗'), findsOneWidget);
      expect(find.text('USD 1000.00'), findsOneWidget);
      expect(find.text('USD 4000.00'), findsOneWidget);
      expect(find.text('3 months to go'), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.byKey(GoalProgressRing.milestoneKey(25)), findsOneWidget);
      expect(find.byKey(GoalProgressRing.milestoneKey(50)), findsOneWidget);
      expect(find.byKey(GoalProgressRing.milestoneKey(75)), findsOneWidget);

      final sections = _pieChart(tester).data.sections;
      expect(sections.first.value, 0.25);
      expect(sections.first.color, AppColors.primary);
      expect(sections.last.value, 0.75);
    });

    testWidgets('shows percent in the ring when the goal has no emoji',
        (tester) async {
      await _pumpCard(
        tester,
        goal: _goal(emoji: null, currentAmount: '3000.00'),
      );

      expect(find.text('75%'), findsOneWidget);
      expect(_pieChart(tester).data.sections.first.value, 0.75);
    });

    testWidgets('progress ring displays the correct percentage', (tester) async {
      await _pumpCard(
        tester,
        goal: _goal(
          emoji: null,
          currentAmount: '2000.00',
          targetAmount: '4000.00',
        ),
      );

      expect(find.text('50%'), findsOneWidget);

      final sections = _pieChart(tester).data.sections;
      expect(sections.first.value, 0.5);
      expect(sections.last.value, 0.5);
    });

    testWidgets('months remaining calculates from the deadline', (tester) async {
      final now = DateTime(2026, 9, 19);

      await _pumpCard(
        tester,
        now: now,
        goal: _goal(targetDate: DateTime(2026, 10, 19)),
      );
      expect(find.text('1 month to go'), findsOneWidget);

      await _pumpCard(
        tester,
        now: now,
        goal: _goal(targetDate: DateTime(2026, 12, 19)),
      );
      expect(find.text('3 months to go'), findsOneWidget);
      expect(find.text('1 month to go'), findsNothing);
    });

    testWidgets('completed goal shows a checkmark instead of the countdown',
        (tester) async {
      await _pumpCard(
        tester,
        goal: _goal(
          currentAmount: '4000.00',
          targetDate: DateTime(2026, 12, 19),
          isCompleted: true,
        ),
      );

      expect(find.byKey(GoalCard.completedCheckKey), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('3 months to go'), findsNothing);
      expect(find.text('Overdue'), findsNothing);
    });

    testWidgets('invokes onTap when the card is pressed', (tester) async {
      var taps = 0;
      await _pumpCard(
        tester,
        goal: _goal(),
        onTap: () => taps++,
      );

      await tester.tap(find.byType(GoalCard));
      expect(taps, 1);
    });
  });
}
