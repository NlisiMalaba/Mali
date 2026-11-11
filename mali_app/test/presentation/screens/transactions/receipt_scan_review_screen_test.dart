import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/receipt_scan.dart';
import 'package:mali_app/presentation/screens/transactions/receipt_scan_review_screen.dart';

void main() {
  final scan = ReceiptScan(
    amount: '24.50',
    currency: CurrencyCode.usd,
    date: DateTime(2026, 11, 8),
    merchant: 'OK Zimbabwe',
  );

  Widget wrap(Widget child) {
    return MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(home: child),
    );
  }

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows found fields and count chip', (tester) async {
    setPhoneViewport(tester);
    await tester.pumpWidget(
      wrap(ReceiptScanReviewScreen(scan: scan)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('receipt-scan-review')), findsOneWidget);
    expect(find.text('Found on this receipt'), findsOneWidget);
    expect(find.byKey(const Key('receipt-scan-found-count')), findsOneWidget);
    expect(find.text('3 of 3'), findsOneWidget);
    expect(find.text(r'$24.50'), findsOneWidget);
    expect(find.textContaining('8 Nov 2026'), findsOneWidget);
    expect(find.text('OK Zimbabwe'), findsOneWidget);
    expect(find.text('Read on your phone'), findsOneWidget);
  });

  testWidgets('Use these details pops true', (tester) async {
    setPhoneViewport(tester);
    bool? result;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await ReceiptScanReviewScreen.open(
                    context,
                    scan: scan,
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('receipt-scan-use-details')));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('Retake pops false', (tester) async {
    setPhoneViewport(tester);
    bool? result = true;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await ReceiptScanReviewScreen.open(
                    context,
                    scan: scan,
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('receipt-scan-retake')));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('partial OCR shows lower found count', (tester) async {
    setPhoneViewport(tester);
    await tester.pumpWidget(
      wrap(
        const ReceiptScanReviewScreen(
          scan: ReceiptScan(amount: '10.00', currency: CurrencyCode.usd),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
  });
}
