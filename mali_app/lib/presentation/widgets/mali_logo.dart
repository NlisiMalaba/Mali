import 'package:flutter/material.dart';
import 'package:mali_app/core/constants/app_info.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';

/// Master of Coin brand mark: three stacks of silver coins (5, 2 and 6 high)
/// that form an "M", on a navy tile, with an optional wordmark underneath.
///
/// Detail adapts to size the way the logo sheet specifies: the full 13-coin
/// mark from 64 px, an eight-coin cut from 32 px, and three bars below that.
/// The class keeps its original name so existing imports keep working.
class MaliLogo extends StatelessWidget {
  const MaliLogo({
    this.size = 96,
    this.showWordmark = true,
    this.onDark = false,
    this.showTile = true,
    this.animate = false,
    super.key,
  });

  final double size;
  final bool showWordmark;

  /// Use when the logo sits on a navy surface: the tile lifts to raised navy
  /// so it stays visible.
  final bool onDark;

  /// When false, only the silver stacks are drawn (for navy headers).
  final bool showTile;

  /// Drops the coins in one by one, bottom row first.
  final bool animate;

  static const Duration _dropDuration = Duration(milliseconds: 1300);
  static const double _tileRadiusFactor = 0.24;

  @override
  Widget build(BuildContext context) {
    final tileColor = onDark ? AppColors.navyRaised : AppColors.navy;
    final wordColor = onDark ? AppColors.onPrimary : AppColors.navy;
    final mutedWordColor = onDark ? AppColors.navInactive : AppColors.onSurfaceVariant;

    Widget mark(double progress) => CustomPaint(
          size: Size.square(size),
          painter: CoinStackPainter(
            progress: progress,
            detail: CoinStackDetail.forSize(size),
            cropToStacks: !showTile,
          ),
        );

    final animated = animate && !MediaQuery.disableAnimationsOf(context);
    final markWidget = animated
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: _dropDuration,
            builder: (context, t, _) => mark(t),
          )
        : mark(1);

    return Semantics(
      label: AppInfo.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTile)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(size * _tileRadiusFactor),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDeep.withValues(alpha: 0.45),
                    blurRadius: size * 0.5,
                    spreadRadius: -size * 0.12,
                    offset: Offset(0, size * 0.22),
                  ),
                ],
              ),
              child: markWidget,
            )
          else
            markWidget,
          if (showWordmark) ...[
            SizedBox(height: size * 0.22),
            ExcludeSemantics(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Master\n'),
                    TextSpan(
                      text: 'of ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: mutedWordColor,
                        fontSize: size * 0.27,
                      ),
                    ),
                    const TextSpan(text: 'Coin'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: AppTypography.money(
                  fontSize: size * 0.38,
                  color: wordColor,
                ).copyWith(height: 1.05),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// How much detail the mark carries at a given size.
enum CoinStackDetail {
  /// 13 coins with rim lines — 64 px and up.
  full,

  /// Eight larger coins — 32 to 63 px.
  reduced,

  /// Three solid bars — under 32 px.
  bars;

  static const double _fullMin = 64;
  static const double _reducedMin = 32;

  static CoinStackDetail forSize(double size) {
    if (size >= _fullMin) return CoinStackDetail.full;
    if (size >= _reducedMin) return CoinStackDetail.reduced;
    return CoinStackDetail.bars;
  }
}

/// One coin (or bar) on the 100-unit tile grid from the logo sheet.
class _Coin {
  const _Coin(this.x, this.y, this.w, this.h, this.r);
  final double x;
  final double y;
  final double w;
  final double h;
  final double r;
}

/// Paints the coin stacks on the logo sheet's 100-unit grid, scaled to fit.
class CoinStackPainter extends CustomPainter {
  const CoinStackPainter({
    this.progress = 1,
    this.detail = CoinStackDetail.full,
    this.cropToStacks = false,
    this.coinColor = AppColors.silver,
    this.rimColor = AppColors.outline,
  });

  /// 0 = nothing placed yet, 1 = every coin in place.
  final double progress;
  final CoinStackDetail detail;

  /// Map just the stacks (not the whole tile) onto the canvas.
  final bool cropToStacks;
  final Color coinColor;
  final Color rimColor;

  static const double _grid = 100;
  static const double _coinW = 17;
  static const double _coinH = 6.2;
  static const double _step = 7.6;
  static const double _base = 66;
  static const double _rimInset = 3.2;
  static const double _rimFromTop = 4.5;
  static const double _rimWidth = 0.8;
  static const double _dropDistance = 24;
  static const double _perCoinShare = 0.35;

  /// Stack heights 5, 2, 6 — fixed by the brand rules. Listed row by row,
  /// bottom first, so they land in a natural order when animated.
  static final List<_Coin> _full = () {
    const columns = [21.0, 41.5, 62.0];
    const heights = [5, 2, 6];
    final coins = <_Coin>[];
    for (var row = 0; row < 6; row++) {
      for (var c = 0; c < columns.length; c++) {
        if (row < heights[c]) {
          coins.add(
            _Coin(columns[c], _base - row * _step, _coinW, _coinH, _coinH / 2),
          );
        }
      }
    }
    return coins;
  }();

  static const List<_Coin> _reduced = [
    _Coin(18, 68, 20, 13, 5),
    _Coin(40, 68, 20, 13, 5),
    _Coin(62, 68, 20, 13, 5),
    _Coin(18, 52, 20, 13, 5),
    _Coin(62, 52, 20, 13, 5),
    _Coin(18, 36, 20, 13, 5),
    _Coin(62, 36, 20, 13, 5),
    _Coin(62, 20, 20, 13, 5),
  ];

  static const List<_Coin> _bars = [
    _Coin(12, 30, 22, 52, 7),
    _Coin(39, 58, 22, 24, 7),
    _Coin(66, 16, 22, 66, 7),
  ];

  /// Grid area that holds the stacks, used when [cropToStacks] is on.
  static const Rect _stacksArea = Rect.fromLTWH(16, 16, 68, 68);

  List<_Coin> get _coins => switch (detail) {
        CoinStackDetail.full => _full,
        CoinStackDetail.reduced => _reduced,
        CoinStackDetail.bars => _bars,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final source = cropToStacks
        ? _stacksArea
        : const Rect.fromLTWH(0, 0, _grid, _grid);
    final scale = size.shortestSide / source.width;
    final dx = (size.width - source.width * scale) / 2 - source.left * scale;
    final dy = (size.height - source.height * scale) / 2 - source.top * scale;

    final coins = _coins;
    final coinPaint = Paint()..color = coinColor;
    final rimPaint = Paint()
      ..color = rimColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _rimWidth * scale;
    final showRims = detail == CoinStackDetail.full;
    final staggerSpan = 1 - _perCoinShare;

    for (var i = 0; i < coins.length; i++) {
      final start = coins.length == 1 ? 0.0 : staggerSpan * i / (coins.length - 1);
      final local = ((progress - start) / _perCoinShare).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final eased = Curves.easeOutBack.transform(local);
      final lift = (1 - eased) * _dropDistance;

      final coin = coins[i];
      final rect = Rect.fromLTWH(
        dx + coin.x * scale,
        dy + (coin.y - lift) * scale,
        coin.w * scale,
        coin.h * scale,
      );
      final alpha = local.clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(coin.r * scale)),
        coinPaint..color = coinColor.withValues(alpha: alpha),
      );
      if (showRims) {
        final y = rect.top + _rimFromTop * scale;
        canvas.drawLine(
          Offset(rect.left + _rimInset * scale, y),
          Offset(rect.right - _rimInset * scale, y),
          rimPaint..color = rimColor.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(CoinStackPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.detail != detail ||
      oldDelegate.cropToStacks != cropToStacks ||
      oldDelegate.coinColor != coinColor ||
      oldDelegate.rimColor != rimColor;
}
