import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/exchange_rate_settings_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/services/exchange_rate_math.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/currency_display.dart';
import 'package:mali_app/presentation/utils/exchange_rate_row_copy.dart';
import 'package:mali_app/presentation/utils/money_display.dart';
import 'package:mali_app/presentation/widgets/settings/edit_exchange_rate_sheet.dart';

class ExchangeRatesSettingsScreen extends ConsumerStatefulWidget {
  const ExchangeRatesSettingsScreen({super.key});

  static const Key screenKey = Key('exchange-rates-settings-screen');
  static const Key refreshButtonKey = Key('exchange-rates-refresh-button');
  static const Key converterKey = Key('exchange-rates-converter');

  @override
  ConsumerState<ExchangeRatesSettingsScreen> createState() =>
      _ExchangeRatesSettingsScreenState();
}

class _ExchangeRatesSettingsScreenState
    extends ConsumerState<ExchangeRatesSettingsScreen> {
  static const _previewBase = CurrencyCode.usd;
  static const _previewTargets = [
    CurrencyCode.zwg,
    CurrencyCode.zar,
    CurrencyCode.bwp,
  ];

  CurrencyCode _target = CurrencyCode.zwg;

  Future<void> _onRefresh() async {
    final message =
        await ref.read(exchangeRateRefreshProvider.notifier).refresh();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Exchange rates updated.'),
      ),
    );
  }

  Future<void> _onEditPair(ExchangeRateSettingsItem item) async {
    final saved = await EditExchangeRateSheet.show(
      context,
      pair: item.pair,
      initialRate: item.rate?.rate,
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exchange rate saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(exchangeRateSettingsItemsProvider);
    final netWorthAsync = ref.watch(homeNetWorthProvider);
    final refreshState = ref.watch(exchangeRateRefreshProvider);
    final now = DateTime.now();

    return Scaffold(
      key: ExchangeRatesSettingsScreen.screenKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load exchange rates: $error'),
            ),
          ),
          data: (items) {
            final usdPairs = [
              for (final item in items)
                if (item.pair.base == _previewBase &&
                    _previewTargets.contains(item.pair.quote))
                  item,
            ]..sort(
                (a, b) => _previewTargets
                    .indexOf(a.pair.quote)
                    .compareTo(_previewTargets.indexOf(b.pair.quote)),
              );

            final youHave = netWorthAsync.maybeWhen(
              data: (result) => result.total,
              orElse: () => null,
            );

            return Column(
              children: [
                _Header(
                  refreshing: refreshState.isLoading,
                  onRefresh: refreshState.isLoading ? null : _onRefresh,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    children: [
                      _ConverterCard(
                        youHaveAmount: youHave?.amount.toString() ?? '0',
                        youHaveCurrency:
                            youHave?.currency.value ?? _previewBase.value,
                        target: _target,
                        targets: _previewTargets,
                        convertedLabel: _convertedLabel(
                          amount: youHave?.amount ?? Decimal.zero,
                          from: youHave?.currency ?? _previewBase,
                          to: _target,
                          items: items,
                        ),
                        onTargetChanged: (code) {
                          setState(() => _target = code);
                        },
                      ),
                      const SizedBox(height: 22),
                      Text(
                        '1 ${_previewBase.value} EQUALS',
                        style: AppTypography.sectionLabel(context).copyWith(
                          fontSize: 12,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            for (var index = 0;
                                index < usdPairs.length;
                                index++) ...[
                              if (index > 0)
                                const Divider(
                                  height: 1,
                                  thickness: 0.8,
                                  color: Color(0xFFEDF0F6),
                                ),
                              _RateRow(
                                item: usdPairs[index],
                                now: now,
                                onTap: () => _onEditPair(usdPairs[index]),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _InfoNote(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _convertedLabel({
    required Decimal amount,
    required CurrencyCode from,
    required CurrencyCode to,
    required List<ExchangeRateSettingsItem> items,
  }) {
    final converted = _convert(
      amount: amount,
      from: from,
      to: to,
      items: items,
    );
    if (converted == null) {
      return 'Rate not set';
    }
    return MoneyDisplay.compact(
      amount: converted.toString(),
      currencyCode: to.value,
    );
  }

  Decimal? _convert({
    required Decimal amount,
    required CurrencyCode from,
    required CurrencyCode to,
    required List<ExchangeRateSettingsItem> items,
  }) {
    if (from == to) {
      return amount;
    }

    final direct = _rateString(items, from: from, to: to);
    if (direct != null) {
      final rate = ExchangeRateMath.parsePositiveRate(direct);
      if (rate == null) {
        return null;
      }
      return (amount * rate).round(scale: 2);
    }

    final inverse = _rateString(items, from: to, to: from);
    if (inverse != null) {
      final rate = ExchangeRateMath.parsePositiveRate(inverse);
      if (rate == null) {
        return null;
      }
      return (amount / rate)
          .toDecimal(scaleOnInfinitePrecision: 8)
          .round(scale: 2);
    }

    // Bridge through USD when needed.
    if (from != _previewBase && to != _previewBase) {
      final toUsd = _convert(
        amount: amount,
        from: from,
        to: _previewBase,
        items: items,
      );
      if (toUsd == null) {
        return null;
      }
      return _convert(
        amount: toUsd,
        from: _previewBase,
        to: to,
        items: items,
      );
    }

    return null;
  }

  String? _rateString(
    List<ExchangeRateSettingsItem> items, {
    required CurrencyCode from,
    required CurrencyCode to,
  }) {
    for (final item in items) {
      if (item.pair.base == from &&
          item.pair.quote == to &&
          item.rate != null) {
        return item.rate!.rate;
      }
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.refreshing,
    required this.onRefresh,
  });

  final bool refreshing;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Material(
            color: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE1E5EE), width: 0.8),
            ),
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Exchange rates',
              style: AppTypography.money(
                fontSize: 26,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Material(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: ExchangeRatesSettingsScreen.refreshButtonKey,
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 44,
                height: 44,
                child: refreshing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.silver,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: AppColors.silver,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConverterCard extends StatelessWidget {
  const _ConverterCard({
    required this.youHaveAmount,
    required this.youHaveCurrency,
    required this.target,
    required this.targets,
    required this.convertedLabel,
    required this.onTargetChanged,
  });

  final String youHaveAmount;
  final String youHaveCurrency;
  final CurrencyCode target;
  final List<CurrencyCode> targets;
  final String convertedLabel;
  final ValueChanged<CurrencyCode> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ExchangeRatesSettingsScreen.converterKey,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: AppDecorations.heroCard(radius: 24),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'You have',
                style: TextStyle(
                  color: AppColors.onNavyMuted,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                MoneyDisplay.compact(
                  amount: youHaveAmount,
                  currencyCode: youHaveCurrency,
                ),
                style: AppTypography.money(
                  fontSize: 26,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFF21386E)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Worth about',
                style: TextStyle(
                  color: AppColors.onNavyMuted,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  convertedLabel,
                  key: ValueKey(convertedLabel),
                  style: AppTypography.money(
                    fontSize: 30,
                    color: AppColors.silver,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.navyRaised,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                for (final code in targets)
                  Expanded(
                    child: _TargetChip(
                      label: CurrencyDisplay.codeWithFlag(code),
                      selected: code == target,
                      onTap: () => onTargetChanged(code),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.silver : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.navy : AppColors.onNavyMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({
    required this.item,
    required this.now,
    required this.onTap,
  });

  final ExchangeRateSettingsItem item;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rate = item.rate;
    final chip = ExchangeRateRowCopy.chipLabel(rate);
    final isManual = rate?.isManual == true;
    final isMissing = rate == null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                CurrencyDisplay.flagEmoji(item.pair.quote),
                style: const TextStyle(fontSize: 20, height: 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ExchangeRateRowCopy.rateAmount(
                      rate,
                      item.pair.quote.value,
                    ),
                    style: AppTypography.money(
                      fontSize: 19,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ExchangeRateRowCopy.subtitle(rate, now),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: isMissing
                    ? AppColors.surfaceContainer
                    : isManual
                        ? AppColors.warningContainer
                        : AppColors.successContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                chip,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isMissing
                      ? AppColors.onSurfaceVariant
                      : isManual
                          ? AppColors.warningText
                          : AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Rates only change how totals are shown. Every transaction '
            'keeps its original amount and currency. Tap a rate to set '
            'your own — useful for street rates.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
