import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/presentation/utils/transaction_date_grouping.dart';

void main() {
  group('formatTransactionDateGroupHeader', () {
    final reference = DateTime(2026, 5, 24, 15, 30);

    test('returns Today for same calendar day', () {
      expect(
        formatTransactionDateGroupHeader(
          DateTime(2026, 5, 24, 8),
          referenceNow: reference,
        ),
        'Today',
      );
    });

    test('returns Yesterday for previous calendar day', () {
      expect(
        formatTransactionDateGroupHeader(
          DateTime(2026, 5, 23, 22),
          referenceNow: reference,
        ),
        'Yesterday',
      );
    });

    test('returns weekday label for older dates', () {
      expect(
        formatTransactionDateGroupHeader(
          DateTime(2026, 5, 5, 12),
          referenceNow: reference,
        ),
        'Tue 5 May',
      );
    });
  });
}
