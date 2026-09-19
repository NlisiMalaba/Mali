import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/goal_providers.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/presentation/screens/goal/goals_screen.dart';
import 'package:mali_app/presentation/widgets/goal/add_goal_sheet.dart';

class _TestAuth extends Auth {
  @override
  Future<User?> build() async {
    return User(
      id: 'user-1',
      name: 'Mali User',
      email: 'user@example.com',
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required DateTime now,
  DateTime? initialDeadline,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_TestAuth.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AddGoalSheet(
            now: now,
            initialDeadline: initialDeadline,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final now = DateTime(2026, 4, 10);

  testWidgets('selecting a preset fills name and emoji', (tester) async {
    await _pumpSheet(tester, now: now);

    await tester.tap(find.byKey(const Key('goal-preset-car')));
    await tester.pump();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('goal-name-field')))
          .controller
          ?.text,
      'Car',
    );
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('goal-preset-car'))).selected,
      isTrue,
    );
    final theme = Theme.of(tester.element(find.byType(AddGoalSheet)));
    expect(
      tester.widget<Material>(find.byKey(const Key('goal-emoji-🚗'))).color,
      theme.colorScheme.primaryContainer,
    );
  });

  testWidgets('shows live save-per-month hint as the amount is typed',
      (tester) async {
    await _pumpSheet(
      tester,
      now: now,
      initialDeadline: DateTime(2026, 6, 30),
    );

    await tester.tap(find.byKey(const Key('currency-USD')));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('goal-amount-field')), '900');
    await tester.pump();

    expect(
      find.text('Save USD 900.00/month to hit your goal'),
      findsNothing,
    );
    expect(
      find.text('Save USD 300.00/month to hit your goal'),
      findsOneWidget,
    );
  });

  testWidgets('Add goal action on GoalsScreen opens AddGoalSheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_TestAuth.new),
          activeGoalsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: GoalsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add your first goal'));
    await tester.pumpAndSettle();

    expect(find.byKey(AddGoalSheet.sheetKey), findsOneWidget);
    expect(find.text('Add goal'), findsOneWidget);
  });
}
