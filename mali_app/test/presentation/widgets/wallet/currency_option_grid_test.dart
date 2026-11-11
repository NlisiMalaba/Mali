import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/widgets/wallet/currency_option_grid.dart';

void main() {
  testWidgets('currency option grid stays compact', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: CurrencyOptionGrid(
              isSelected: (currency) => currency == CurrencyCode.usd,
              onCurrencyTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final gridSize = tester.getSize(find.byType(CurrencyOptionGrid));
    // Two compact rows (~78px) + one 8px gap should stay well under the old
    // near-square tiles that stretched past ~300px.
    expect(gridSize.height, lessThan(180));
    expect(find.byKey(const Key('currency-USD')), findsOneWidget);
    expect(find.byKey(const Key('currency-BWP')), findsOneWidget);
  });
}
