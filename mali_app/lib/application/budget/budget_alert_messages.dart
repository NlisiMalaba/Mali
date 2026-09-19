import 'package:mali_app/domain/events/budget_exceeded_event.dart';
import 'package:mali_app/presentation/constants/system_categories.dart';

class BudgetAlertMessages {
  const BudgetAlertMessages._();

  static const String notificationTitle = 'Budget alert';

  static const String _unknownCategoryName = 'Budget';

  static String categoryName(String categoryId) {
    return SystemCategories.nameFor(
      categoryId,
      fallback: _unknownCategoryName,
    );
  }

  static String notificationBody({
    required String categoryName,
    required BudgetExceededEvent event,
  }) {
    if (event.isExceeded) {
      return "You've reached your $categoryName budget limit this month";
    }
    return "You've used 80% of your $categoryName budget this month";
  }
}
