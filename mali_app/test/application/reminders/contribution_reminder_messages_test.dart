import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/application/reminders/contribution_reminder_messages.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/money.dart';

void main() {
  group('ContributionReminderMessages', () {
    test('builds the prompt with amount, month name and goal', () {
      expect(
        ContributionReminderMessages.notificationBody(
          surplus: Money(
            amount: Decimal.parse('749.75'),
            currency: CurrencyCode.usd,
          ),
          month: DateTime(2026, 9),
          goalName: 'Emergency Fund',
        ),
        'You had a USD 749.75 surplus in September. '
        'Allocate to your Emergency Fund?',
      );
    });

    test('pads whole amounts to two decimal places', () {
      expect(
        ContributionReminderMessages.notificationBody(
          surplus: Money(
            amount: Decimal.parse('300'),
            currency: CurrencyCode.zar,
          ),
          month: DateTime(2026, 12),
          goalName: 'Car',
        ),
        'You had a ZAR 300.00 surplus in December. Allocate to your Car?',
      );
    });
  });
}
