import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/domain/value_objects/receipt_scan.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';
import 'package:mali_app/presentation/widgets/common/fade_slide_in.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';

/// Full-screen confirm step after OCR: show the photo, what we found, then
/// Retake or Use these details.
///
/// Pops `true` to apply, `false` to retake, or `null` if the user closed.
class ReceiptScanReviewScreen extends StatefulWidget {
  const ReceiptScanReviewScreen({
    required this.scan,
    super.key,
  });

  final ReceiptScan scan;

  static Future<bool?> open(
    BuildContext context, {
    required ReceiptScan scan,
  }) {
    return Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: true,
        barrierDismissible: false,
        transitionDuration: AppMotion.sheet,
        reverseTransitionDuration: AppMotion.normal,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ReceiptScanReviewScreen(scan: scan);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.decelerate,
          );
          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<ReceiptScanReviewScreen> createState() =>
      _ReceiptScanReviewScreenState();
}

class _ReceiptScanReviewScreenState extends State<ReceiptScanReviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanLine;

  @override
  void initState() {
    super.initState();
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _scanLine.value = 0.35;
    } else if (!_scanLine.isAnimating) {
      _scanLine.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scanLine.dispose();
    super.dispose();
  }

  ReceiptScan get _scan => widget.scan;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      key: const Key('receipt-scan-review'),
      backgroundColor: const Color(0xFF0A0F1C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 8),
                _HeaderBar(
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(36, 12, 36, 8),
                    child: FadeSlideIn(
                      index: 0,
                      child: _ReceiptStage(
                        scan: _scan,
                        scanLine: _scanLine,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 268 + bottomInset),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeSlideIn(
              index: 2,
              offsetY: 32,
              child: _FoundSheet(
                scan: _scan,
                bottomInset: bottomInset,
                onRetake: () => Navigator.of(context).pop(false),
                onUse: () => Navigator.of(context).pop(true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _RoundIconButton(
            key: const Key('receipt-scan-close'),
            onTap: onClose,
            child: const Icon(Icons.close, color: AppColors.silver, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: AppColors.silver.withValues(alpha: 0.92),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Read on your phone',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.silver.withValues(alpha: 0.95),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _RoundIconButton(
            key: const Key('receipt-scan-flash'),
            onTap: () {},
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.silver,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.onTap,
    required this.child,
    super.key,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ReceiptStage extends StatelessWidget {
  const _ReceiptStage({
    required this.scan,
    required this.scanLine,
  });

  final ReceiptScan scan;
  final Animation<double> scanLine;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateX(-0.21)
              ..rotateY(-0.01)
              ..rotateZ(-0.05),
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 60,
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _ReceiptImage(scan: scan),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: _ScanCorners()),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: scanLine,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ScanLinePainter(progress: scanLine.value),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptImage extends StatelessWidget {
  const _ReceiptImage({required this.scan});

  final ReceiptScan scan;

  @override
  Widget build(BuildContext context) {
    final path = scan.imagePath;
    if (path != null && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _PaperFallback(scan: scan),
      );
    }
    return _PaperFallback(scan: scan);
  }
}

/// Soft paper stand-in when the photo path is missing (tests / OCR-only).
class _PaperFallback extends StatelessWidget {
  const _PaperFallback({required this.scan});

  final ReceiptScan scan;

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(
      color: const Color(0xFF2B2B2B),
      fontSize: 11,
      height: 1.75,
    );
    final muted = mono.copyWith(color: const Color(0xFF6B6B6B));
    final date = scan.date;
    final amount = scan.amount;
    final currency = scan.currency ?? CurrencyCode.usd;

    return ColoredBox(
      color: const Color(0xFFFAF8F2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              (scan.merchant ?? 'RECEIPT').toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: mono.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            if (date != null)
              Text(
                DateFormat('dd/MM/yyyy').format(date),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            const SizedBox(height: 8),
            if (amount != null)
              Text(
                'TOTAL ${currency.value}  $amount',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: mono.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            const Spacer(),
            Text(
              'Scanned on your phone',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted.copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanCorners extends StatelessWidget {
  const _ScanCorners();

  static const double _size = 34;
  static const double _thickness = 4;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.silver.withValues(alpha: 0.95);
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: _corner(color, top: true, left: true),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _corner(color, top: true, left: false),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: _corner(color, top: false, left: true),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: _corner(color, top: false, left: false),
        ),
      ],
    );
  }

  Widget _corner(Color color, {required bool top, required bool left}) {
    return SizedBox(
      width: _size,
      height: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(14) : Radius.zero,
            topRight: top && !left ? const Radius.circular(14) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(14) : Radius.zero,
            bottomRight:
                !top && !left ? const Radius.circular(14) : Radius.zero,
          ),
          border: Border(
            top: top
                ? BorderSide(color: color, width: _thickness)
                : BorderSide.none,
            bottom: !top
                ? BorderSide(color: color, width: _thickness)
                : BorderSide.none,
            left: left
                ? BorderSide(color: color, width: _thickness)
                : BorderSide.none,
            right: !left
                ? BorderSide(color: color, width: _thickness)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  const _ScanLinePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = 8 + (size.height - 16) * progress;
    final paint = Paint()
      ..color = AppColors.silver.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(
      Offset(12, y),
      Offset(size.width - 12, y),
      paint,
    );
    final core = Paint()
      ..color = AppColors.silver
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(12, y),
      Offset(size.width - 12, y),
      core,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FoundSheet extends StatelessWidget {
  const _FoundSheet({
    required this.scan,
    required this.bottomInset,
    required this.onRetake,
    required this.onUse,
  });

  final ReceiptScan scan;
  final double bottomInset;
  final VoidCallback onRetake;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final found = scan.foundFieldCount;
    final currency = scan.currency ?? CurrencyCode.usd;
    final amountLabel = scan.amount == null
        ? '—'
        : '${CurrencyDisplay.symbol(currency)}${scan.amount}';
    final dateLabel = scan.date == null
        ? '—'
        : DateFormat('EEE, d MMM yyyy').format(scan.date!);
    final shopLabel = scan.merchant ?? '—';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD4DAE6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Found on this receipt',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Container(
                key: const Key('receipt-scan-found-count'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$found of ${ReceiptScan.expectedFieldCount}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _FoundRow(
                  label: 'Total',
                  value: amountLabel,
                  valueStyle: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  found: scan.amount != null,
                ),
                const Divider(height: 1, color: AppColors.settingsDivider),
                _FoundRow(
                  label: 'Date',
                  value: dateLabel,
                  found: scan.date != null,
                ),
                const Divider(height: 1, color: AppColors.settingsDivider),
                _FoundRow(
                  label: 'Shop',
                  value: shopLabel,
                  found: scan.merchant != null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: PressableScale(
                  key: const Key('receipt-scan-retake'),
                  onTap: onRetake,
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4DAE6)),
                    ),
                    child: const Text(
                      'Retake',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: PressableScale(
                  key: const Key('receipt-scan-use-details'),
                  onTap: onUse,
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Use these details',
                      style: TextStyle(
                        color: AppColors.silver,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoundRow extends StatelessWidget {
  const _FoundRow({
    required this.label,
    required this.value,
    required this.found,
    this.valueStyle,
  });

  final String label;
  final String value;
  final bool found;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF556079),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (found) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 18,
            ),
          ],
        ],
      ),
    );
  }
}
