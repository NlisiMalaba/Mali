import 'package:mali_app/domain/usecases/build_weekly_digest_usecase.dart';
import 'package:mali_app/domain/value_objects/money.dart';
import 'package:mali_app/presentation/constants/system_categories.dart';
import 'package:mali_app/presentation/utils/money_display.dart';

/// Copy for the Sunday-evening digest notification.
class WeeklyDigestMessages {
  const WeeklyDigestMessages._();

  static const String notificationTitle = 'Your weekly digest';

  static const String _unknownCategoryName = 'Uncategorised spending';

  /// Sentences are omitted when the underlying data is absent, so the body
  /// never claims progress the user does not have.
  static String notificationBody(WeeklyDigest digest) {
    final sentences = <String>[
      'You spent ${_format(digest.totalSpent)} this week.',
      if (digest.topCategory != null)
        '${_categoryName(digest.topCategory!)} was your biggest expense.',
      if (digest.topGoal != null)
        'Your ${digest.topGoal!.name} is ${digest.topGoal!.percentFunded}% funded.',
    ];

    return sentences.join(' ');
  }

  static String _categoryName(DigestCategorySpend spend) {
    return SystemCategories.nameFor(
      spend.categoryId,
      fallback: _unknownCategoryName,
    );
  }

  static String _format(Money money) {
    return MoneyDisplay.withCurrency(
      amount: money.amount.toString(),
      currencyCode: money.currency.value,
    );
  }
}
