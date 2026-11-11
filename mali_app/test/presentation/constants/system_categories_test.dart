import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/presentation/constants/system_categories.dart';
import 'package:mali_app/presentation/utils/category_icons.dart';

void main() {
  test('expense category colors are unique', () {
    final colors = {
      for (final category in SystemCategories.expense)
        category.colorHex.toUpperCase(),
    };

    expect(colors.length, SystemCategories.expense.length);
  });

  test('groceries and transport are visually distinct hues', () {
    final groceries = SystemCategories.expense
        .firstWhere((category) => category.id == 'cat-groceries');
    final transport = SystemCategories.expense
        .firstWhere((category) => category.id == 'cat-transport');

    expect(groceries.colorHex, isNot(equals(transport.colorHex)));

    final groceriesColor = CategoryIcons.colorFromHex(groceries.colorHex);
    final transportColor = CategoryIcons.colorFromHex(transport.colorHex);
    expect(groceriesColor, isNot(equals(transportColor)));
  });
}
