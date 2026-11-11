import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/models/home_monthly_summary_display.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/application/providers/wallet_card_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/usecases/calculate_net_worth_usecase.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_motion.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/common/currency_flag_badge.dart';
import 'package:mali_app/presentation/widgets/common/fade_slide_in.dart';
import 'package:mali_app/presentation/widgets/common/pressable_scale.dart';
import 'package:mali_app/presentation/widgets/wallet/add_wallet_sheet.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      if (_ambient.isAnimating) {
        _ambient.stop();
      }
      _ambient.value = 0;
      return;
    }
    if (!_ambient.isAnimating) {
      _ambient.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _openAddWallet() async {
    final created = await AddWalletSheet.show(context);
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet added.')),
      );
    }
  }

  Future<bool> _archiveWallet(Wallet wallet) async {
    final result = await ref.read(archiveWalletUseCaseProvider)(
      walletId: wallet.id,
    );

    if (!mounted) return false;

    final failure = result.fold((left) => left, (_) => null);
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${wallet.name} archived.')),
    );
    return true;
  }

  void _selectWallet(int index, int length) {
    if (length == 0) return;
    final next = index.clamp(0, length - 1);
    if (next == _selectedIndex) return;
    setState(() => _selectedIndex = next);
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(activeWalletsProvider);
    final summaryAsync = ref.watch(homeMonthlySummaryDisplayProvider);
    final netWorthAsync = ref.watch(homeNetWorthProvider);
    final canPop = GoRouter.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: walletsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load wallets: $error'),
            ),
          ),
          data: (wallets) {
            if (_selectedIndex >= wallets.length && wallets.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedIndex = 0);
              });
            }

            return Column(
              children: [
                FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        if (canPop) ...[
                          _HeaderIconButton(
                            icon: Icons.chevron_left,
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            'Wallets',
                            style: AppTypography.money(
                              fontSize: 28,
                              color: AppColors.onSurface,
                            ).copyWith(letterSpacing: -0.6),
                          ),
                        ),
                        PressableScale(
                          onTap: _openAddWallet,
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppColors.silver,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: AppColors.silver,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: wallets.isEmpty
                      ? _EmptyWallets(onAdd: _openAddWallet)
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 16),
                          children: [
                            FadeSlideIn(
                              index: 1,
                              child: _WalletDeck(
                                wallets: wallets,
                                selectedIndex: _selectedIndex,
                                ambient: _ambient,
                                onSelected: (index) =>
                                    _selectWallet(index, wallets.length),
                                onOpen: (wallet) =>
                                    context.push('/wallets/${wallet.id}'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeSlideIn(
                              index: 2,
                              child: _PageDots(
                                count: wallets.length,
                                selectedIndex: _selectedIndex,
                                onSelect: (index) =>
                                    _selectWallet(index, wallets.length),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeSlideIn(
                              index: 3,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: _MonthFlowCard(
                                  summaryAsync: summaryAsync,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeSlideIn(
                              index: 4,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: DecoratedBox(
                                  decoration: AppDecorations.surfaceCard(
                                    radius: 22,
                                    color: AppColors.surfaceContainerLowest,
                                  ),
                                  child: Column(
                                    children: [
                                      for (var i = 0;
                                          i < wallets.length;
                                          i++) ...[
                                        if (i > 0)
                                          const Divider(
                                            height: 1,
                                            indent: 66,
                                            endIndent: 8,
                                          ),
                                        Dismissible(
                                          key: ValueKey(wallets[i].id),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                              right: 24,
                                            ),
                                            color: AppColors.errorContainer,
                                            child: const Icon(
                                              Icons.archive_outlined,
                                            ),
                                          ),
                                          confirmDismiss: (_) =>
                                              _archiveWallet(wallets[i]),
                                          child: _WalletListTile(
                                            wallet: wallets[i],
                                            emphasize: i == _selectedIndex,
                                            onTap: () {
                                              _selectWallet(
                                                i,
                                                wallets.length,
                                              );
                                              context.push(
                                                '/wallets/${wallets[i].id}',
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                if (wallets.isNotEmpty)
                  FadeSlideIn(
                    index: 5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _TotalBar(netWorthAsync: netWorthAsync),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _HeroWalletVariant {
  silver,
  navy,
  light;

  static _HeroWalletVariant forIndex(int index) {
    switch (index % 3) {
      case 0:
        return _HeroWalletVariant.silver;
      case 1:
        return _HeroWalletVariant.navy;
      default:
        return _HeroWalletVariant.light;
    }
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE1E5EE), width: 0.8),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.onSurface, size: 20),
        ),
      ),
    );
  }
}

class _WalletDeck extends StatefulWidget {
  const _WalletDeck({
    required this.wallets,
    required this.selectedIndex,
    required this.ambient,
    required this.onSelected,
    required this.onOpen,
  });

  final List<Wallet> wallets;
  final int selectedIndex;
  final Animation<double> ambient;
  final ValueChanged<int> onSelected;
  final ValueChanged<Wallet> onOpen;

  @override
  State<_WalletDeck> createState() => _WalletDeckState();
}

class _WalletDeckState extends State<_WalletDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
      return;
    }
    if (_entrance.status == AnimationStatus.dismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final threshold = 48.0;
    if (_dragDx < -threshold || velocity < -300) {
      widget.onSelected(widget.selectedIndex + 1);
    } else if (_dragDx > threshold || velocity > 300) {
      widget.onSelected(widget.selectedIndex - 1);
    }
    setState(() => _dragDx = 0);
  }

  List<int> _visibleIndexes() {
    final count = widget.wallets.length;
    if (count == 0) return const [];
    if (count == 1) return [0];
    if (count == 2) {
      final other = widget.selectedIndex == 0 ? 1 : 0;
      return [other, widget.selectedIndex];
    }

    final behind2 =
        (widget.selectedIndex - 2 + count) % count;
    final behind1 =
        (widget.selectedIndex - 1 + count) % count;
    return [behind2, behind1, widget.selectedIndex];
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final visible = _visibleIndexes();

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() => _dragDx += details.delta.dx);
      },
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entrance, widget.ambient]),
        builder: (context, _) {
          final enter = reduceMotion
              ? 1.0
              : Curves.easeOutCubic.transform(_entrance.value);
          final float = reduceMotion
              ? 0.0
              : math.sin(widget.ambient.value * math.pi) * 4;
          final dragTilt = (_dragDx / 280).clamp(-0.12, 0.12);

          return SizedBox(
            height: 250,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..translateByDouble(0, float, 0, 1)
                  ..rotateY(dragTilt)
                  ..rotateX(-0.06 + (1 - enter) * 0.18),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    for (var layer = 0; layer < visible.length; layer++)
                      _buildLayer(
                        walletIndex: visible[layer],
                        depthFromFront: visible.length - 1 - layer,
                        enter: enter,
                        reduceMotion: reduceMotion,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _desaturateIfBehind({
    required bool isFront,
    required Widget child,
  }) {
    if (isFront) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.82, 0.16, 0.02, 0, 0,
        0.08, 0.82, 0.1, 0, 0,
        0.02, 0.14, 0.84, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: child,
    );
  }

  Widget _buildLayer({
    required int walletIndex,
    required int depthFromFront,
    required double enter,
    required bool reduceMotion,
  }) {
    final wallet = widget.wallets[walletIndex];
    final delay = depthFromFront * 0.1;
    final local = reduceMotion
        ? 1.0
        : ((enter - delay) / (1 - delay)).clamp(0.0, 1.0);
    final t = Curves.easeOutBack.transform(local);

    final scale = switch (depthFromFront) {
      0 => 1.0,
      1 => 0.92,
      _ => 0.84,
    };
    final translateY = switch (depthFromFront) {
      0 => 40.0,
      1 => 14.0,
      _ => -10.0,
    };
    final translateZ = switch (depthFromFront) {
      0 => 0.0,
      1 => -60.0,
      _ => -120.0,
    };
    final rotateX = switch (depthFromFront) {
      0 => 0.14,
      1 => 0.26,
      _ => 0.32,
    };
    final isFront = depthFromFront == 0;

    return Positioned(
      left: 8,
      right: 8,
      top: 0,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translateByDouble(
            (1 - t) * 20,
            translateY + (1 - t) * 36,
            translateZ * t,
            1,
          )
          ..rotateX(rotateX * t)
          ..scaleByDouble(scale, scale, 1, 1),
        child: Opacity(
          opacity: (isFront ? 1.0 : 0.88) * t.clamp(0.0, 1.0),
          child: _desaturateIfBehind(
            isFront: isFront,
            child: _HeroWalletCard(
              wallet: wallet,
              variant: _HeroWalletVariant.forIndex(walletIndex),
              emphasize: isFront,
              onTap: () {
                if (isFront) {
                  widget.onOpen(wallet);
                } else {
                  widget.onSelected(walletIndex);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroWalletCard extends ConsumerWidget {
  const _HeroWalletCard({
    required this.wallet,
    required this.variant,
    required this.onTap,
    this.emphasize = false,
  });

  final Wallet wallet;
  final _HeroWalletVariant variant;
  final VoidCallback onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final equivalentAsync = ref.watch(
      walletEquivalentLabelProvider((
        balance: wallet.balance,
        currencyCode: wallet.currencyCode,
      )),
    );
    final txAsync = ref.watch(walletTransactionsProvider(wallet.id));
    final txCount = txAsync.asData?.value.length;

    final background = switch (variant) {
      _HeroWalletVariant.silver => AppColors.silver,
      _HeroWalletVariant.navy => AppColors.navy,
      _HeroWalletVariant.light => AppColors.surfaceContainerLowest,
    };
    final foreground = switch (variant) {
      _HeroWalletVariant.navy => AppColors.onPrimary,
      _ => AppColors.navy,
    };
    final muted = foreground.withValues(alpha: 0.85);
    final leftMeta = equivalentAsync.asData?.value ??
        _walletSubtitle(wallet.name);

    return Material(
      color: background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: variant == _HeroWalletVariant.navy
            ? BorderSide.none
            : const BorderSide(color: Color(0xFFD4DAE6), width: 0.8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 190,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(
                  alpha: emphasize ? 0.55 : 0.3,
                ),
                blurRadius: emphasize ? 40 : 20,
                offset: Offset(0, emphasize ? 28 : 10),
                spreadRadius: emphasize ? -16 : -10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CurrencyFlag(wallet.currencyCode, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    wallet.currencyCode,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    wallet.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                MoneyDisplay.compact(
                  amount: wallet.balance,
                  currencyCode: wallet.currencyCode,
                  trimTrailingZeros: wallet.currencyCode == 'ZWG',
                ),
                style: AppTypography.money(
                  fontSize: 34,
                  color: foreground,
                ).copyWith(letterSpacing: -1),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      leftMeta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (txCount != null)
                    Text(
                      '$txCount transaction${txCount == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int count;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              width: i == selectedIndex ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == selectedIndex
                    ? AppColors.navy
                    : const Color(0xFFC8CFDD),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MonthFlowCard extends StatelessWidget {
  const _MonthFlowCard({required this.summaryAsync});

  final AsyncValue<HomeMonthlySummaryDisplay> summaryAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surfaceCard(
        radius: 22,
        color: AppColors.surfaceContainerLowest,
      ),
      child: summaryAsync.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => Text(
          'Could not load month summary',
          style: theme.textTheme.bodySmall,
        ),
        data: (summary) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In this month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoneyDisplay.compactSigned(
                        amount: summary.income.toString(),
                        currencyCode: summary.displayCurrency.value,
                        prefix: '+',
                      ),
                      style: AppTypography.money(
                        fontSize: 20,
                        color: AppColors.income,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Out this month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoneyDisplay.compactSigned(
                        amount: summary.expenses.toString(),
                        currencyCode: summary.displayCurrency.value,
                        prefix: '\u2212',
                      ),
                      style: AppTypography.money(
                        fontSize: 20,
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WalletListTile extends ConsumerWidget {
  const _WalletListTile({
    required this.wallet,
    required this.onTap,
    this.emphasize = false,
  });

  final Wallet wallet;
  final VoidCallback onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final equivalentAsync = ref.watch(
      walletEquivalentLabelProvider((
        balance: wallet.balance,
        currencyCode: wallet.currencyCode,
      )),
    );

    final badgeBackground =
        emphasize ? AppColors.navy : const Color(0xFFECEFF5);
    final meta = equivalentAsync.asData?.value ??
        _walletSubtitle(wallet.name);

    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CurrencyFlag(wallet.currencyCode, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${wallet.currencyCode} · $meta',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              MoneyDisplay.compact(
                amount: wallet.balance,
                currencyCode: wallet.currencyCode,
                trimTrailingZeros: wallet.currencyCode == 'ZWG',
              ),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.netWorthAsync});

  final AsyncValue<CalculateNetWorthResult> netWorthAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text(
            'Total in USD',
            style: TextStyle(
              color: AppColors.onNavyMuted,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          netWorthAsync.when(
            loading: () => const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.silver,
              ),
            ),
            error: (_, _) => Text(
              '—',
              style: AppTypography.money(
                fontSize: 22,
                color: AppColors.onPrimary,
              ),
            ),
            data: (netWorth) => Text(
              MoneyDisplay.compact(
                amount: netWorth.total.amount.toString(),
                currencyCode: netWorth.total.currency.value,
              ),
              style: AppTypography.money(
                fontSize: 22,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWallets extends StatelessWidget {
  const _EmptyWallets({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No wallets yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            PressableScale(
              onTap: onAdd,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Add your first wallet',
                  style: TextStyle(
                    color: AppColors.silver,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _walletSubtitle(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('ecocash') || lower.contains('onemoney')) {
    return 'Mobile money';
  }
  if (lower.contains('bank')) {
    return 'Bank account';
  }
  if (lower.contains('cash')) {
    return 'Main wallet';
  }
  return 'Digital wallet';
}
