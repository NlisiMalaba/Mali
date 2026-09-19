import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/digest/weekly_digest_messages.dart';
import 'package:mali_app/domain/usecases/build_weekly_digest_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/domain/value_objects/money.dart';

WeeklyDigest _digest({
  String totalSpent = '120.5',
  String? topCategoryId = 'cat-food',
  String topCategoryAmount = '60',
  String? goalName = 'Emergency Fund',
  int goalPercent = 40,
  int expenseCount = 3,
}) {
  Money money(String amount) => Money(
        amount: Decimal.parse(amount),
        currency: CurrencyCode.usd,
      );

  return WeeklyDigest(
    window: DateRange(
      start: DateTime(2026, 9, 14),
      end: DateTime(2026, 9, 20, 23, 59, 59),
    ),
    totalSpent: money(totalSpent),
    expenseCount: expenseCount,
    topCategory: topCategoryId == null
        ? null
        : DigestCategorySpend(
            categoryId: topCategoryId,
            amount: money(topCategoryAmount),
          ),
    topGoal: goalName == null
        ? null
        : DigestGoalProgress(
            goalId: 'g-1',
            name: goalName,
            percentFunded: goalPercent,
          ),
  );
}

void main() {
  group('WeeklyDigestMessages', () {
    test('builds the full digest sentence', () {
      expect(
        WeeklyDigestMessages.notificationBody(_digest()),
        'You spent USD 120.50 this week. Food was your biggest expense. '
        'Your Emergency Fund is 40% funded.',
      );
    });

    test('omits the category sentence when there is no ranked category', () {
      expect(
        WeeklyDigestMessages.notificationBody(_digest(topCategoryId: null)),
        'You spent USD 120.50 this week. Your Emergency Fund is 40% funded.',
      );
    });

    test('omits the goal sentence when no goal is active', () {
      expect(
        WeeklyDigestMessages.notificationBody(_digest(goalName: null)),
        'You spent USD 120.50 this week. Food was your biggest expense.',
      );
    });

    test('falls back to a generic label for unknown categories', () {
      expect(
        WeeklyDigestMessages.notificationBody(
          _digest(topCategoryId: 'cat-custom-1'),
        ),
        contains('Uncategorised spending was your biggest expense.'),
      );
    });
  });
}
