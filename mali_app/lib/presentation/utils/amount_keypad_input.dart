import 'package:decimal/decimal.dart';

/// Keypad input rules for currency amount entry.
class AmountKeypadInput {
  const AmountKeypadInput._();

  static const String initialValue = '0';

  static String applyKey({
    required String current,
    required String key,
    required int decimalPlaces,
  }) {
    assert(decimalPlaces >= 0);

    var raw = _editableRaw(current);

    if (key == 'backspace') {
      if (raw.isEmpty) {
        return initialValue;
      }
      raw = raw.substring(0, raw.length - 1);
      return raw.isEmpty ? initialValue : raw;
    }

    if (key == '.') {
      if (decimalPlaces == 0 || raw.contains('.')) {
        return current;
      }
      return raw.isEmpty ? '0.' : '$raw.';
    }

    if (!_isDigit(key)) {
      return current;
    }

    if (raw.contains('.')) {
      final fraction = raw.split('.')[1];
      if (fraction.length >= decimalPlaces) {
        return current;
      }
    }

    final next = raw.isEmpty ? key : '$raw$key';
    return _stripLeadingZeros(next);
  }

  /// Formats the in-progress keypad value for display without rounding away
  /// partial decimal entry (for example `12.` stays `12.`).
  static String formatDisplay(String amount, int decimalPlaces) {
    if (amount.isEmpty || amount == initialValue) {
      return initialValue;
    }

    if (amount.endsWith('.')) {
      final whole = amount.substring(0, amount.length - 1);
      return '${_formatWholePart(whole)}.';
    }

    final parts = amount.split('.');
    final whole = _formatWholePart(parts[0]);
    if (parts.length == 1) {
      return whole;
    }

    final fraction = parts[1].substring(
      0,
      parts[1].length.clamp(0, decimalPlaces),
    );
    return '$whole.$fraction';
  }

  /// Truncates fractional digits when the currency precision changes.
  static String clampToDecimalPlaces(String amount, int decimalPlaces) {
    if (decimalPlaces == 0) {
      if (amount.contains('.')) {
        return amount.split('.').first;
      }
      return amount;
    }

    if (!amount.contains('.')) {
      return amount;
    }

    if (amount.endsWith('.')) {
      return amount;
    }

    final parts = amount.split('.');
    final fraction = parts[1];
    if (fraction.length <= decimalPlaces) {
      return amount;
    }
    return '${parts[0]}.${fraction.substring(0, decimalPlaces)}';
  }

  /// Parses the keypad value to a decimal-safe canonical string for persistence.
  static String toCanonicalAmount(String amount) {
    if (amount.isEmpty || amount == initialValue || amount == '0.') {
      return initialValue;
    }

    final normalized = amount.endsWith('.') ? amount.substring(0, amount.length - 1) : amount;
    if (normalized.isEmpty) {
      return initialValue;
    }

    return Decimal.parse(normalized).toString();
  }

  static bool isPositive(String amount) {
    try {
      return Decimal.parse(toCanonicalAmount(amount)) > Decimal.zero;
    } catch (_) {
      return false;
    }
  }

  static String _editableRaw(String current) {
    if (current == initialValue) {
      return '';
    }
    return current;
  }

  static String _stripLeadingZeros(String value) {
    if (value.startsWith('0.') || value == '0') {
      return value;
    }
    return value.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  }

  static String _formatWholePart(String whole) {
    if (whole.isEmpty) {
      return initialValue;
    }
    return _stripLeadingZeros(whole);
  }

  static bool _isDigit(String key) {
    return key.length == 1 && '0123456789'.contains(key);
  }
}
