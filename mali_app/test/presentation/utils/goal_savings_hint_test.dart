import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/presentation/utils/goal_savings_hint.dart';

void main() {
  test('formats a live save-per-month sentence with currency', () {
    expect(
      GoalSavingsHint.saveEachMonth(
        targetAmount: '900',
        currencyCode: 'USD',
        deadline: DateTime(2026, 6, 30),
        now: DateTime(2026, 4, 10),
      ),
      'Save USD 300.00/month to hit your goal',
    );
  });

  test('returns null until amount, currency, and deadline are set', () {
    expect(
      GoalSavingsHint.saveEachMonth(
        targetAmount: '900',
        currencyCode: null,
        deadline: DateTime(2026, 6, 30),
        now: DateTime(2026, 4, 10),
      ),
      isNull,
    );
  });
}
