import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/goal_contribution.dart';
import 'package:mali_app/domain/entities/savings_goal.dart';
import 'package:mali_app/domain/repositories/goal_repository.dart';
import 'package:mali_app/domain/usecases/allocate_to_goal_usecase.dart';
import 'package:mali_app/presentation/screens/goal/goal_detail_screen.dart';
import 'package:mali_app/presentation/widgets/goal/contribute_to_goal_sheet.dart';
import 'package:mali_app/presentation/widgets/goal/milestone_celebration_overlay.dart';

SavingsGoal _goal({String currentAmount = '200'}) {
  return SavingsGoal(
    id: 'g-1',
    userId: 'u-1',
    name: 'Emergency Fund',
    emoji: '🛟',
    targetAmount: '1000',
    currentAmount: currentAmount,
    currencyCode: 'USD',
    targetDate: DateTime(2026, 6, 30),
    priorityOrder: 0,
    isCompleted: false,
    isSynced: false,
    createdAt: DateTime(2026, 4, 10),
    updatedAt: DateTime(2026, 4, 10),
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

class _RecordingAllocateToGoalUseCase extends AllocateToGoalUseCase {
  _RecordingAllocateToGoalUseCase({
    this.reachedMilestones = const [],
  }) : super(goalRepository: _StubGoalRepository());

  final List<GoalMilestone> reachedMilestones;
  GoalContribution? lastContribution;

  @override
  Future<Either<Failure, AllocateToGoalResult>> call({
    required GoalContribution contribution,
  }) async {
    lastContribution = contribution;
    return right(
      AllocateToGoalResult(
        updatedGoal: _goal(currentAmount: contribution.amount),
        reachedMilestones: reachedMilestones,
      ),
    );
  }
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required SavingsGoal goal,
  AllocateToGoalUseCase? useCase,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (useCase != null)
          allocateToGoalUseCaseProvider.overrideWithValue(useCase),
      ],
      child: MaterialApp(
        home: Scaffold(body: ContributeToGoalSheet(goal: goal)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows amount, currency selector, and optional note',
      (tester) async {
    await _pumpSheet(tester, goal: _goal());

    expect(find.byKey(ContributeToGoalSheet.sheetKey), findsOneWidget);
    expect(find.text('Add contribution'), findsOneWidget);
    expect(find.byKey(const Key('contribution-amount-field')), findsOneWidget);
    expect(find.byKey(const Key('contribution-note-field')), findsOneWidget);
    expect(find.text('Note (optional)'), findsOneWidget);
    expect(find.byKey(const Key('currency-USD')), findsOneWidget);
    expect(find.text('Save contribution'), findsOneWidget);
  });

  testWidgets('Add Contribution on GoalDetailScreen opens the sheet',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final goal = _goal();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeGoalsProvider.overrideWith((ref) => Stream.value([goal])),
          goalContributionsProvider(goal.id).overrideWith(
            (ref) => Stream.value(const <GoalContribution>[]),
          ),
        ],
        child: MaterialApp(
          home: GoalDetailScreen(
            goalId: goal.id,
            now: DateTime(2026, 5, 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(GoalDetailScreen.addContributionButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(ContributeToGoalSheet.sheetKey), findsOneWidget);
    expect(find.text('Add contribution'), findsOneWidget);
  });

  testWidgets('submit calls AllocateToGoalUseCase with amount and note',
      (tester) async {
    final useCase = _RecordingAllocateToGoalUseCase();
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final goal = _goal();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allocateToGoalUseCaseProvider.overrideWithValue(useCase),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => ContributeToGoalSheet.show(
                  context,
                  goal: goal,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('contribution-amount-field')),
      '150.50',
    );
    await tester.enterText(
      find.byKey(const Key('contribution-note-field')),
      'April deposit',
    );
    await tester.tap(find.byKey(const Key('contribute-submit-button')));
    await tester.pumpAndSettle();

    expect(useCase.lastContribution, isNotNull);
    expect(useCase.lastContribution!.goalId, goal.id);
    expect(useCase.lastContribution!.amount, '150.50');
    expect(useCase.lastContribution!.currencyCode, 'USD');
    expect(useCase.lastContribution!.note, 'April deposit');
    expect(find.byKey(ContributeToGoalSheet.sheetKey), findsNothing);
  });

  testWidgets('shows MilestoneCelebrationOverlay when a milestone is crossed',
      (tester) async {
    final useCase = _RecordingAllocateToGoalUseCase(
      reachedMilestones: const [GoalMilestone.half],
    );
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final goal = _goal();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allocateToGoalUseCaseProvider.overrideWithValue(useCase),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => ContributeToGoalSheet.show(
                  context,
                  goal: goal,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('contribution-amount-field')),
      '400',
    );
    await tester.tap(find.byKey(const Key('contribute-submit-button')));
    await tester.pump();
    await tester.pump();
    await tester.pump(MilestoneCelebrationOverlay.transitionDuration);

    expect(find.byKey(MilestoneCelebrationOverlay.overlayKey), findsOneWidget);
    expect(find.text("You're halfway there!"), findsOneWidget);

    await tester.pump(MilestoneCelebrationOverlay.autoDismissDuration);
    await tester.pumpAndSettle();
    expect(find.byKey(MilestoneCelebrationOverlay.overlayKey), findsNothing);
  });
}
