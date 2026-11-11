import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/widgets/security/pin_dots.dart';

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onBackspace,
    this.chrome = PinChrome.light,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final PinChrome chrome;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];
    final isDark = chrome == PinChrome.dark;

    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < keys.length; rowIndex++) ...[
          if (rowIndex > 0) SizedBox(height: isDark ? 14 : 12),
          Row(
            mainAxisAlignment:
                isDark ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              for (var colIndex = 0;
                  colIndex < keys[rowIndex].length;
                  colIndex++) ...[
                if (isDark) ...[
                  if (colIndex > 0) const SizedBox(width: 22),
                  _DarkKey(
                    label: keys[rowIndex][colIndex],
                    enabled: enabled,
                    onDigit: onDigit,
                    onBackspace: onBackspace,
                  ),
                ] else
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _LightKey(
                        label: keys[rowIndex][colIndex],
                        enabled: enabled,
                        onDigit: onDigit,
                        onBackspace: onBackspace,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _DarkKey extends StatefulWidget {
  const _DarkKey({
    required this.label,
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
  });

  final String label;
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  State<_DarkKey> createState() => _DarkKeyState();
}

class _DarkKeyState extends State<_DarkKey> {
  bool _pressed = false;

  bool get _isBlank => widget.label.isEmpty;
  bool get _isBack => widget.label == 'back';

  void _tap() {
    if (!widget.enabled || _isBlank) {
      return;
    }
    HapticFeedback.selectionClick();
    if (_isBack) {
      widget.onBackspace();
    } else {
      widget.onDigit(widget.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    const height = 68.0;
    const width = 94.0;
    if (_isBlank) {
      return const SizedBox(width: width, height: height);
    }

    final key = _isBack
        ? const Key('pin-keypad-backspace')
        : Key('pin-key-${widget.label}');

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              _tap();
            }
          : null,
      onTapCancel:
          widget.enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: AppMotion.resolve(context, AppMotion.fast),
        child: Container(
          key: key,
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isBack ? Colors.transparent : AppColors.navyRaised,
            shape: BoxShape.circle,
          ),
          child: _isBack
              ? const Icon(
                  Icons.backspace_outlined,
                  color: AppColors.silver,
                  size: 26,
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.silver,
                  ),
                ),
        ),
      ),
    );
  }
}

class _LightKey extends StatelessWidget {
  const _LightKey({
    required this.label,
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
  });

  final String label;
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const SizedBox(height: 56);
    }

    final theme = Theme.of(context);

    if (label == 'back') {
      return SizedBox(
        height: 56,
        child: IconButton(
          key: const Key('pin-keypad-backspace'),
          onPressed: enabled ? onBackspace : null,
          icon: const Icon(Icons.backspace_outlined),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: FilledButton.tonal(
        key: Key('pin-key-$label'),
        onPressed: enabled ? () => onDigit(label) : null,
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          textStyle: theme.textTheme.headlineSmall,
        ),
        child: Text(label),
      ),
    );
  }
}
