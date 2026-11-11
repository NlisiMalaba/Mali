import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/core/constants/app_info.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/widgets/mali_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static const Key screenKey = Key('welcome-screen');

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController();
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goRegister() => context.go('/auth/register');

  void _goLogin() => context.go('/auth/login');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      key: WelcomeScreen.screenKey,
      backgroundColor: AppColors.navy,
      body: Stack(
        children: [
          Positioned(
            top: 120,
            left: -15,
            child: IgnorePointer(
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1D3A80).withValues(alpha: 0.9),
                      AppColors.navy.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
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
                      Text(
                        AppInfo.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _goLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB5C9FF),
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
                        final page = _pages[index];
                        return _WelcomePage(page: page);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
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
  const _WelcomePage({required this.page});

  final _WelcomePageData page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: page.showCardStack
              ? const Center(child: _WalletCardStack())
              : Center(
                  child: MaliLogo(
                    size: 120,
                    showWordmark: false,
                    onDark: true,
                    animate: true,
                  ),
                ),
        ),
        Text(
          page.title,
          style: theme.textTheme.displaySmall?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          page.body,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.onNavyMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _WalletCardStack extends StatelessWidget {
  const _WalletCardStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 30),
            child: Transform.rotate(
              angle: -0.08,
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
          ),
          Transform.translate(
            offset: const Offset(8, 14),
            child: Transform.rotate(
              angle: 0.05,
              child: const _DemoWalletCard(
                currency: 'ZWG',
                label: 'ECOCASH',
                amount: 'ZiG 41,200.00',
                background: AppColors.background,
                foreground: Color(0xFF4A5570),
                amountColor: AppColors.navy,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(-6, -8),
            child: Transform.rotate(
              angle: -0.03,
              child: const _DemoWalletCard(
                currency: 'USD',
                label: 'CASH',
                amount: '\$3,120.40',
                background: AppColors.silver,
                foreground: AppColors.navy,
                amountColor: AppColors.navy,
                showChip: true,
              ),
            ),
          ),
        ],
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
  });

  final String currency;
  final String label;
  final String amount;
  final Color background;
  final Color foreground;
  final Color amountColor;
  final bool border;
  final bool showChip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 250,
      height: 156,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
        border: border
            ? Border.all(color: AppColors.navyBorder)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                currency,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  amount,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showChip)
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
          ),
        ],
      ),
    );
  }
}
