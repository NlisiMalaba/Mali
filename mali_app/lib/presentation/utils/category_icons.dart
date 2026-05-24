import 'package:flutter/material.dart';

class CategoryIcons {
  const CategoryIcons._();

  static IconData fromKey(String iconKey) {
    return switch (iconKey) {
      'restaurant' => Icons.restaurant_outlined,
      'directions_bus' => Icons.directions_bus_outlined,
      'signal_cellular_alt' => Icons.signal_cellular_alt,
      'bolt' => Icons.bolt_outlined,
      'school' => Icons.school_outlined,
      'local_hospital' => Icons.local_hospital_outlined,
      'checkroom' => Icons.checkroom_outlined,
      'movie' => Icons.movie_outlined,
      'shopping_cart' => Icons.shopping_cart_outlined,
      'home' => Icons.home_outlined,
      'payments' => Icons.payments_outlined,
      'work' => Icons.work_outline,
      'send' => Icons.send_outlined,
      'account_balance_wallet' => Icons.account_balance_wallet_outlined,
      'receipt_long' => Icons.receipt_long_outlined,
      _ => Icons.category_outlined,
    };
  }

  static Color colorFromHex(String colorHex) {
    final normalized =
        colorHex.startsWith('#') ? colorHex.substring(1) : colorHex;
    if (normalized.length != 6) {
      return Colors.grey;
    }
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) {
      return Colors.grey;
    }
    return Color(0xFF000000 | value);
  }
}
