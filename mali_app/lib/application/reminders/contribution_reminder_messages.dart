import 'package:intl/intl.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

/// Copy for the 1st-of-the-month contribution reminder.
class ContributionReminderMessages {
  const ContributionReminderMessages._();

  static const String notificationTitle = 'Put last month to work';

  static String notificationBody({
    required Money surplus,
    required DateTime month,
    required String goalName,
  }) {
    final monthName = DateFormat.MMMM().format(month);
    final amount = MoneyDisplay.withCurrency(
      amount: surplus.amount.toString(),
      currencyCode: surplus.currency.value,
    );

    return 'You had a $amount surplus in $monthName. '
        'Allocate to your $goalName?';
  }
}
