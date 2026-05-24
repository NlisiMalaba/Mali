import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/utils/amount_keypad_input.dart';
import 'package:mali_app/presentation/widgets/transaction/numeric_keypad.dart';

void main() {
  group('AmountKeypadInput', () {
    test('appends digits and replaces leading zero', () {
      var amount = AmountKeypadInput.initialValue;

      amount = AmountKeypadInput.applyKey(
        current: amount,
        key: '1',
        decimalPlaces: 2,
      );
      amount = AmountKeypadInput.applyKey(
        current: amount,
        key: '2',
        decimalPlaces: 2,
      );

      expect(amount, '12');
      expect(AmountKeypadInput.formatDisplay(amount, 2), '12');
    });

    test('preserves trailing decimal while typing', () {
      var amount = '12';

      amount = AmountKeypadInput.applyKey(
        current: amount,
        key: '.',
        decimalPlaces: 2,
      );

      expect(amount, '12.');
      expect(AmountKeypadInput.formatDisplay(amount, 2), '12.');
    });

    test('limits fractional digits to currency precision', () {
      var amount = '12.';

      amount = AmountKeypadInput.applyKey(
        current: amount,
        key: '3',
        decimalPlaces: 2,
      );
      amount = AmountKeypadInput.applyKey(
        current: amount,
        key: '4',
        decimalPlaces: 2,
      );
      final ignored = AmountKeypadInput.applyKey(
        current: amount,
        key: '5',
        decimalPlaces: 2,
      );

      expect(amount, '12.34');
      expect(ignored, '12.34');
    });

    test('backspace removes digits and resets to zero', () {
      var amount = '12.3';

      for (var i = 0; i < 4; i++) {
        amount = AmountKeypadInput.applyKey(
          current: amount,
          key: 'backspace',
          decimalPlaces: 2,
        );
      }

      expect(amount, AmountKeypadInput.initialValue);
    });

    test('rejects decimal point when currency has no fractional digits', () {
      final amount = AmountKeypadInput.applyKey(
        current: '12',
        key: '.',
        decimalPlaces: 0,
      );

      expect(amount, '12');
    });

    test('clamps amount when currency precision changes', () {
      expect(
        AmountKeypadInput.clampToDecimalPlaces('12.345', 2),
        '12.34',
      );
      expect(
        AmountKeypadInput.clampToDecimalPlaces('12.', 2),
        '12.',
      );
    });

    test('toCanonicalAmount normalizes in-progress values', () {
      expect(AmountKeypadInput.toCanonicalAmount('12.'), '12');
      expect(AmountKeypadInput.toCanonicalAmount('12.50'), '12.5');
      expect(AmountKeypadInput.isPositive('0.'), isFalse);
      expect(AmountKeypadInput.isPositive('0.01'), isTrue);
    });
  });

  group('NumericKeypad', () {
    testWidgets('formats amount with currency decimal places as user types',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: _KeypadHarness(currency: CurrencyCode.usd),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('numeric-keypad-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('numeric-keypad-2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('numeric-keypad-decimal')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('numeric-keypad-5')));
      await tester.pump();

      expect(find.text('12.5'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('blocks extra fractional digits for selected currency',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: _KeypadHarness(
                currency: CurrencyCode.zar,
                initialAmount: '12.3',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('numeric-keypad-4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('numeric-keypad-5')));
      await tester.pump();

      expect(find.text('12.34'), findsOneWidget);
    });
  });
}

class _KeypadHarness extends StatefulWidget {
  const _KeypadHarness({
    required this.currency,
    this.initialAmount = AmountKeypadInput.initialValue,
  });

  final CurrencyCode currency;
  final String initialAmount;

  @override
  State<_KeypadHarness> createState() => _KeypadHarnessState();
}

class _KeypadHarnessState extends State<_KeypadHarness> {
  late String _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
  }

  @override
  Widget build(BuildContext context) {
    return NumericKeypad(
      amount: _amount,
      currency: widget.currency,
      onChanged: (value) => setState(() => _amount = value),
    );
  }
}
