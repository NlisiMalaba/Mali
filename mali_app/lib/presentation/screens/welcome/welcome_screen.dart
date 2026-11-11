import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/core/constants/app_info.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';
import 'package:mali_app/presentation/widgets/mali_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static const Key screenKey = Key('welcome-screen');
  static const Key createLedgerButtonKey = Key('welcome-create-ledger');
  static const Key loginButtonKey = Key('welcome-login');
  static const Key skipButtonKey = Key('welcome-skip');

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _ambientController;
  int _pageIndex = 0;

  static const _pages = <_WelcomePageData>[
    _WelcomePageData(
      title: 'Every currency.\nOne calm ledger.',
      body:
          'USD, ZiG and Rand in one place. Log in seconds, scan receipts, and watch your goals fill up — even offline.',
      showCardStack: true,
    ),
    _WelcomePageData(
      title: 'Know where\nit all goes.',
      body:
          'Track income, expenses and transfers across wallets. Budgets and goals stay clear without the noise.',
      showCardStack: false,
    ),
    _WelcomePageData(
      title: 'Built for\nreal life money.',
      body:
          'Scan receipts, sync when you reconnect, and keep your ledger private behind a PIN or biometrics.',
      showCardStack: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _ambientController.stop();
      _ambientController.value = 0;
    } else if (!_ambientController.isAnimating) {
      _ambientController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goRegister() => context.go('/auth/register');

  void _goLogin() => context.go('/auth/login');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      key: WelcomeScreen.screenKey,
      backgroundColor: AppColors.navy,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, _) {
              final pulse = reduceMotion ? 0.0 : _ambientController.value;
              return Positioned(
                top: 100 + (pulse * 18),
                right: -40 + (pulse * 12),
                child: IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                    child: Container(
                      width: 420,
                      height: 420,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1D3A80)
                            .withValues(alpha: 0.55 + pulse * 0.2),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomInset * 0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const MaliLogo(
                        size: 30,
                        showWordmark: false,
                        showTile: false,
                        onDark: true,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppInfo.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.money(
                            fontSize: 20,
                            color: AppColors.onPrimary,
                          ).copyWith(letterSpacing: -0.3),
                        ),
                      ),
                      TextButton(
                        key: WelcomeScreen.skipButtonKey,
                        onPressed: _goLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB5C9FF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (index) {
                        setState(() => _pageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return _WelcomePage(
                          page: _pages[index],
                          ambient: _ambientController,
                          reduceMotion: reduceMotion,
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        AnimatedContainer(
                          duration: AppMotion.resolve(
                            context,
                            AppMotion.fast,
                          ),
                          curve: AppMotion.standard,
                          width: i == _pageIndex ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _pageIndex
                                ? AppColors.silver
                                : const Color(0xFF3B5394),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    key: WelcomeScreen.createLedgerButtonKey,
                    onPressed: _goRegister,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.silver,
                      foregroundColor: AppColors.navy,
                      minimumSize: const Size.fromHeight(58),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create my ledger',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: WelcomeScreen.loginButtonKey,
                    onPressed: _goLogin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onPrimary,
                      side: const BorderSide(color: AppColors.navyBorder),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'I already have an account',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePageData {
  const _WelcomePageData({
    required this.title,
    required this.body,
    required this.showCardStack,
  });

  final String title;
  final String body;
  final bool showCardStack;
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.page,
    required this.ambient,
    required this.reduceMotion,
  });

  final _WelcomePageData page;
  final Animation<double> ambient;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: page.showCardStack
              ? Center(
                  child: _WalletCardStack(
                    ambient: ambient,
                    reduceMotion: reduceMotion,
                  ),
                )
              : Center(
                  child: MaliLogo(
                    size: 120,
                    showWordmark: false,
                    onDark: true,
                    animate: !reduceMotion,
                  ),
                ),
        ),
        TweenAnimationBuilder<double>(
          key: ValueKey(page.title),
          tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
          duration: AppMotion.resolve(context, AppMotion.celebration),
          curve: AppMotion.standard,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 18),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                page.title,
                style: AppTypography.money(
                  fontSize: 40,
                  color: AppColors.onPrimary,
                ).copyWith(
                  letterSpacing: -1.2,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                page.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onNavyMuted,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}

/// Perspective stack matching the welcome mock: back ZAR, mid ZWG, front USD.
class _WalletCardStack extends StatefulWidget {
  const _WalletCardStack({
    required this.ambient,
    required this.reduceMotion,
  });

  final Animation<double> ambient;
  final bool reduceMotion;

  @override
  State<_WalletCardStack> createState() => _WalletCardStackState();
}

class _WalletCardStackState extends State<_WalletCardStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.reduceMotion) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _WalletCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && !oldWidget.reduceMotion) {
      _entrance.value = 1;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, widget.ambient]),
      builder: (context, _) {
        final enter = Curves.easeOutCubic.transform(_entrance.value);
        final float = widget.reduceMotion
            ? 0.0
            : math.sin(widget.ambient.value * math.pi) * 6;

        return SizedBox(
          width: 300,
          height: 240,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..translateByDouble(0, float, 0, 1)
              ..rotateX(-0.08 + (1 - enter) * 0.25),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _buildLayer(
                  enter: enter,
                  delay: 0,
                  translateY: 34,
                  translateZ: -70,
                  rotateY: -0.22,
                  rotateZ: -0.05,
                  child: const _DemoWalletCard(
                    currency: 'ZAR',
                    label: 'RAND WALLET',
                    amount: 'R 2,450.00',
                    background: AppColors.navyRaised,
                    foreground: AppColors.onNavyMuted,
                    amountColor: AppColors.onPrimary,
                    border: true,
                  ),
                ),
                _buildLayer(
                  enter: enter,
                  delay: 0.12,
                  translateY: 12,
                  translateZ: -20,
                  rotateY: 0.16,
                  rotateZ: 0.04,
                  child: const _DemoWalletCard(
                    currency: 'ZWG',
                    label: 'ECOCASH',
                    amount: 'ZiG 41,200.00',
                    background: AppColors.background,
                    foreground: Color(0xFF4A5570),
                    amountColor: AppColors.navy,
                  ),
                ),
                _buildLayer(
                  enter: enter,
                  delay: 0.24,
                  translateY: -10,
                  translateZ: 40,
                  rotateY: -0.06,
                  rotateZ: -0.02,
                  child: const _DemoWalletCard(
                    currency: 'USD',
                    label: 'CASH',
                    amount: '\$3,120.40',
                    background: AppColors.silver,
                    foreground: AppColors.navy,
                    amountColor: AppColors.navy,
                    showChip: true,
                    emphasize: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayer({
    required double enter,
    required double delay,
    required double translateY,
    required double translateZ,
    required double rotateY,
    required double rotateZ,
    required Widget child,
  }) {
    final local = ((enter - delay) / (1 - delay)).clamp(0.0, 1.0);
    final t = Curves.easeOutBack.transform(local);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0011)
        ..translateByDouble(
          (1 - t) * 28,
          translateY + (1 - t) * 48,
          translateZ * t,
          1,
        )
        ..rotateY(rotateY * t)
        ..rotateZ(rotateZ * t)
        ..scaleByDouble(0.92 + 0.08 * t, 0.92 + 0.08 * t, 1, 1),
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: child,
      ),
    );
  }
}

class _DemoWalletCard extends StatelessWidget {
  const _DemoWalletCard({
    required this.currency,
    required this.label,
    required this.amount,
    required this.background,
    required this.foreground,
    required this.amountColor,
    this.border = false,
    this.showChip = false,
    this.emphasize = false,
  });

  final String currency;
  final String label;
  final String amount;
  final Color background;
  final Color foreground;
  final Color amountColor;
  final bool border;
  final bool showChip;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 250,
      height: 156,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
        border: border ? Border.all(color: AppColors.navyBorder) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: emphasize ? 0.5 : 0.4),
            blurRadius: emphasize ? 36 : 28,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                CurrencyDisplay.flagEmojiForCode(currency),
                style: const TextStyle(fontSize: 14, height: 1),
              ),
              const SizedBox(width: 6),
              Text(
                currency,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: AppTypography.money(
                      fontSize: emphasize ? 28 : 26,
                      color: amountColor,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (showChip) ...[
                const SizedBox(width: 8),
                Opacity(
                  opacity: 0.85,
                  child: Container(
                    width: 30,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
