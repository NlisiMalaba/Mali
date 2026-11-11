import 'package:flutter/material.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/widgets/wallet/currency_option_card.dart';

/// Shared 2×2 currency picker used on create/edit goal, wallet, and budget flows.
///
/// Keeps tile height and spacing consistent so forms do not grow a large empty
/// gap under the picker.
class CurrencyOptionGrid extends StatelessWidget {
  const CurrencyOptionGrid({
    required this.isSelected,
    required this.onCurrencyTap,
    super.key,
  });

  /// Vertical space callers should leave after this grid before the next field.
  static const double gapAfter = 12;

  static const double _tileHeight = 78;
  static const double _spacing = 8;

  final bool Function(CurrencyCode currency) isSelected;
  final ValueChanged<CurrencyCode> onCurrencyTap;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: _tileHeight,
        mainAxisSpacing: _spacing,
        crossAxisSpacing: _spacing,
      ),
      children: [
        for (final currency in CurrencyCode.values)
          CurrencyOptionCard(
            currency: currency,
            isSelected: isSelected(currency),
            onTap: () => onCurrencyTap(currency),
          ),
      ],
    );
  }
}
