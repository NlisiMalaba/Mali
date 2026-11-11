import 'package:mali_app/domain/entities/category.dart';

/// Default system categories mirrored from backend seed data.
/// Used until local category sync is implemented.
class SystemCategories {
  const SystemCategories._();

  static const _epoch = '2024-01-01T00:00:00.000Z';

  /// Expense colors are spaced around the hue wheel so Insights charts and
  /// category chips stay visually distinct (especially Groceries vs Transport).
  static final List<Category> expense = [
    _system('cat-groceries', 'Groceries', 'shopping_cart', '#2E7D32'),
    _system('cat-transport', 'Transport', 'directions_bus', '#FB8C00'),
    _system('cat-entertainment', 'Eating out', 'movie', '#8E24AA'),
    _system('cat-airtime', 'Airtime', 'signal_cellular_alt', '#1E88E5'),
    _system('cat-food', 'Food', 'restaurant', '#E53935'),
    _system('cat-utilities', 'Utilities', 'bolt', '#F9A825'),
    _system('cat-education', 'School/Education', 'school', '#5E35B1'),
    _system('cat-medical', 'Medical', 'local_hospital', '#00897B'),
    _system('cat-clothing', 'Clothing', 'checkroom', '#6D4C41'),
    _system('cat-rent', 'Rent/Housing', 'home', '#455A64'),
    _system('cat-other-expense', 'Other Expense', 'receipt_long', '#90A4AE'),
  ];

  static final List<Category> income = [
    _system('cat-salary', 'Salary', 'payments', '#43A047', type: 'income'),
    _system('cat-freelance', 'Freelance', 'work', '#1E88E5', type: 'income'),
    _system('cat-remittance', 'Remittance', 'send', '#8E24AA', type: 'income'),
    _system(
      'cat-other-income',
      'Other Income',
      'account_balance_wallet',
      '#00897B',
      type: 'income',
    ),
  ];

  static List<Category> get all => [...expense, ...income];

  /// Display name for [categoryId], or [fallback] when it is not a known
  /// system category.
  static String nameFor(String categoryId, {required String fallback}) {
    return nameForOrNull(categoryId) ?? fallback;
  }

  /// Display name for [categoryId], or null when it is not a known system
  /// category.
  static String? nameForOrNull(String categoryId) {
    for (final category in all) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return null;
  }

  static List<Category> forType(String type) {
    return switch (type) {
      'income' => income,
      'transfer' => expense,
      _ => expense,
    };
  }

  static List<Category> gridForType(String type, {int limit = 8}) {
    return forType(type).take(limit).toList(growable: false);
  }

  static Category _system(
    String id,
    String name,
    String iconKey,
    String colorHex, {
    String type = 'expense',
  }) {
    final timestamp = DateTime.parse(_epoch);
    return Category(
      id: id,
      name: name,
      type: type,
      iconKey: iconKey,
      colorHex: colorHex,
      isSystem: true,
      isArchived: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }
}
