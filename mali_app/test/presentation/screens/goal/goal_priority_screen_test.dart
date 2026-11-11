import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';
import 'package:mali_app/domain/usecases/reorder_goals_usecase.dart';
import 'package:mali_app/presentation/screens/goal/goal_priority_screen.dart';
import 'package:mali_app/presentation/screens/goal/goals_screen.dart';

SavingsGoal _goal({
  required String id,
  required String name,
  required int priorityOrder,
  String emoji = '🎯',
  String currentAmount = '100',
  String targetAmount = '1000',
}) {
  return SavingsGoal(
    id: id,
    userId: 'u-1',
    name: name,
    emoji: emoji,
    targetAmount: targetAmount,
    currentAmount: currentAmount,
    currencyCode: 'USD',
    targetDate: DateTime(2026, 12, 31),
    priorityOrder: priorityOrder,
    isCompleted: false,
    isSynced: false,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
  );
}

class _StubGoalRepository implements IGoalRepository {
  @override
  Future<void> addContribution(GoalContribution contribution) async {}

  @override
  Future<void> saveGoal(SavingsGoal goal) async {}

  @override
  Stream<List<SavingsGoal>> watchActiveGoals() => const Stream.empty();

  @override
  Future<List<SavingsGoal>> listActiveGoals() async => const [];

  @override
  Stream<List<GoalContribution>> watchContributions(String goalId) =>
      const Stream.empty();
}

class _RecordingReorderGoalsUseCase extends ReorderGoalsUseCase {
  _RecordingReorderGoalsUseCase() : super(goalRepository: _StubGoalRepository());

  List<String>? lastOrderedIds;

  @override
  Future<Either<Failure, List<SavingsGoal>>> call({
    required List<String> orderedGoalIds,
  }) async {
    lastOrderedIds = orderedGoalIds;
    return right(const []);
  }
}

void main() {
  final goals = [
    _goal(id: 'g-1', name: 'Emergency Fund', priorityOrder: 0, emoji: '🛟'),
    _goal(id: 'g-2', name: 'Car', priorityOrder: 1, emoji: '🚗'),
  ];

  testWidgets('lists goals with move controls and explainer', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeGoalsProvider.overrideWith((ref) => Stream.value(goals)),
        ],
        child: MaterialApp(
          home: GoalPriorityScreen(now: DateTime(2026, 5, 10)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(GoalPriorityScreen.screenKey), findsOneWidget);
    expect(find.text('Goal order'), findsOneWidget);
    expect(find.textContaining('#1 first'), findsOneWidget);
    expect(find.text('Emergency Fund'), findsOneWidget);
    expect(find.text('Car'), findsOneWidget);
    expect(find.byKey(GoalPriorityScreen.moveDownKey('g-1')), findsOneWidget);
    expect(find.byKey(GoalPriorityScreen.moveUpKey('g-2')), findsOneWidget);
    expect(find.text('Save order'), findsOneWidget);
  });

  testWidgets('moves goal then saves order', (tester) async {
    final useCase = _RecordingReorderGoalsUseCase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeGoalsProvider.overrideWith((ref) => Stream.value(goals)),
          reorderGoalsUseCaseProvider.overrideWithValue(useCase),
        ],
        child: MaterialApp(
          home: GoalPriorityScreen(now: DateTime(2026, 5, 10)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(GoalPriorityScreen.moveDownKey('g-1')));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Car')).dy <
          tester.getTopLeft(find.text('Emergency Fund')).dy,
      isTrue,
    );
    expect(useCase.lastOrderedIds, isNull);

    await tester.tap(find.byKey(GoalPriorityScreen.saveButtonKey));
    await tester.pumpAndSettle();

    expect(useCase.lastOrderedIds, ['g-2', 'g-1']);
    expect(find.text('Goal order saved.'), findsOneWidget);
  });

  testWidgets('GoalsScreen reorder action opens GoalPriorityScreen',
      (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const GoalsScreen(),
        ),
        GoRoute(
          path: '/goals/priority',
          builder: (context, state) => const GoalPriorityScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeGoalsProvider.overrideWith((ref) => Stream.value(goals)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(GoalsScreen.reorderButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(GoalPriorityScreen.screenKey), findsOneWidget);
    expect(find.text('Goal order'), findsOneWidget);
  });
}
