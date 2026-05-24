import 'package:decimal/decimal.dart';

class WalletFormValidators {
  const WalletFormValidators._();

  static String? walletName(String? value, {required bool touched}) {
    if (!touched) return null;

    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter a wallet name';
    }

    if (trimmed.length > 80) {
      return 'Name must be 80 characters or fewer';
    }

    return null;
  }

  static String? openingBalance(String? value, {required bool touched}) {
    if (!touched) return null;

    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      if (Decimal.parse(trimmed) < Decimal.zero) {
        return 'Enter a valid amount (0 or greater)';
      }
    } catch (_) {
      return 'Enter a valid amount (0 or greater)';
    }

    return null;
  }
}
