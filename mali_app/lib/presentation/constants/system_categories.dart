import 'package:mali_app/domain/entities/category.dart';

/// Default system categories mirrored from backend seed data.
/// Used until local category sync is implemented.
class SystemCategories {
  const SystemCategories._();

  static const _epoch = '2024-01-01T00:00:00.000Z';

  static final List<Category> expense = [
    _system('cat-food', 'Food', 'restaurant', '#FF6B6B'),
    _system('cat-transport', 'Transport', 'directions_bus', '#4ECDC4'),
    _system('cat-airtime', 'Airtime/Data', 'signal_cellular_alt', '#45B7D1'),
    _system('cat-utilities', 'Utilities', 'bolt', '#F7B731'),
    _system('cat-education', 'School/Education', 'school', '#5F27CD'),
    _system('cat-medical', 'Medical', 'local_hospital', '#EE5253'),
    _system('cat-clothing', 'Clothing', 'checkroom', '#10AC84'),
    _system('cat-entertainment', 'Entertainment', 'movie', '#FF9FF3'),
    _system('cat-groceries', 'Groceries', 'shopping_cart', '#00D2D3'),
    _system('cat-rent', 'Rent/Housing', 'home', '#576574'),
    _system('cat-other-expense', 'Other Expense', 'receipt_long', '#8395A7'),
  ];

  static final List<Category> income = [
    _system('cat-salary', 'Salary', 'payments', '#1DD1A1', type: 'income'),
    _system('cat-freelance', 'Freelance', 'work', '#54A0FF', type: 'income'),
    _system('cat-remittance', 'Remittance', 'send', '#5F9EA0', type: 'income'),
    _system(
      'cat-other-income',
      'Other Income',
      'account_balance_wallet',
      '#2ECC71',
      type: 'income',
    ),
  ];

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
