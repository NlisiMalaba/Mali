import 'package:flutter/material.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';

/// Compact currency mark: flag + ISO code, for chips, pickers, and list avatars.
class CurrencyFlagBadge extends StatelessWidget {
  const CurrencyFlagBadge({
    required this.currencyCode,
    this.compact = false,
    this.foreground,
    this.background,
    super.key,
  });

  factory CurrencyFlagBadge.fromCode(
    CurrencyCode currency, {
    bool compact = false,
    Color? foreground,
    Color? background,
    Key? key,
  }) {
    return CurrencyFlagBadge(
      key: key,
      currencyCode: currency.value,
      compact: compact,
      foreground: foreground,
      background: background,
    );
  }

  final String currencyCode;
  final bool compact;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final code = currencyCode.trim().toUpperCase();
    final textColor = foreground ?? AppColors.onSurface;
    final flagSize = compact ? 14.0 : 16.0;
    final codeSize = compact ? 12.0 : 13.5;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          CurrencyDisplay.flagEmojiForCode(code),
          style: TextStyle(fontSize: flagSize, height: 1),
        ),
        SizedBox(width: compact ? 4 : 6),
        Text(
          code,
          style: TextStyle(
            fontSize: codeSize,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: compact ? 0.2 : 0.4,
          ),
        ),
      ],
    );

    if (background == null) {
      return content;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: content,
    );
  }
}

/// Just the flag for a currency, sized to sit beside its ISO code.
///
/// Hidden from screen readers: the code next to it already says which
/// currency it is, and "flag of United States" before every amount is noise.
class CurrencyFlag extends StatelessWidget {
  const CurrencyFlag(this.currencyCode, {this.size = 16, super.key});

  final String currencyCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        CurrencyDisplay.flagEmojiForCode(currencyCode),
        style: TextStyle(fontSize: size, height: 1),
      ),
    );
  }
}
