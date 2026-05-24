import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/exchange_rate_settings_providers.dart';
import 'package:mali_app/application/providers/home_providers.dart';
import 'package:mali_app/domain/entities/exchange_rate.dart';
import 'package:mali_app/presentation/utils/exchange_rate_display.dart';
import 'package:mali_app/presentation/utils/exchange_rate_labels.dart';
import 'package:mali_app/presentation/widgets/settings/edit_exchange_rate_sheet.dart';

class ExchangeRatesSettingsScreen extends ConsumerWidget {
  const ExchangeRatesSettingsScreen({super.key});

  static const Key screenKey = Key('exchange-rates-settings-screen');

  Future<void> _onRefresh(WidgetRef ref, BuildContext context) async {
    final message = await ref.read(exchangeRateRefreshProvider.notifier).refresh();
    if (!context.mounted) {
      return;
    }
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exchange rates updated.')),
      );
    }
  }

  Future<void> _onEditPair(
    BuildContext context,
    ExchangeRateSettingsItem item,
  ) async {
    final saved = await EditExchangeRateSheet.show(
      context,
      pair: item.pair,
      initialRate: item.rate?.rate,
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exchange rate saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(exchangeRateSettingsItemsProvider);
    final lastUpdatedAsync = ref.watch(exchangeRatesLastUpdatedProvider);
    final refreshState = ref.watch(exchangeRateRefreshProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      key: screenKey,
      appBar: AppBar(
        title: const Text('Exchange rates'),
        actions: [
          IconButton(
            key: const Key('exchange-rates-refresh-button'),
            tooltip: 'Refresh rates',
            onPressed: refreshState.isLoading
                ? null
                : () => _onRefresh(ref, context),
            icon: refreshState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load exchange rates: $error'),
          ),
        ),
        data: (items) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              lastUpdatedAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (lastUpdated) {
                  if (lastUpdated == null) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Text(
                        'No rates saved yet. Refresh when online or set rates manually.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      ExchangeRateLabels.lastUpdated(
                        lastUpdated.toLocal(),
                        now,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final rate = item.rate;
                    final sourceLabel = ExchangeRateDisplay.sourceLabel(rate);

                    return Card(
                      child: ListTile(
                        key: ValueKey(item.pair.key),
                        title: Text(
                          ExchangeRateDisplay.pairLabel(
                            item.pair.base,
                            item.pair.quote,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              ExchangeRateDisplay.rateValue(rate),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(sourceLabel),
                            if (ExchangeRateDisplay.updatedSubtitle(
                                  rate,
                                  now,
                                ) !=
                                null)
                              Text(
                                ExchangeRateDisplay.updatedSubtitle(
                                  rate,
                                  now,
                                )!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                        trailing: _SourceChip(label: sourceLabel, rate: rate),
                        onTap: () => _onEditPair(context, item),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.rate,
  });

  final String label;
  final ExchangeRate? rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color background;
    final Color foreground;

    if (rate == null) {
      background = theme.colorScheme.surfaceContainerHighest;
      foreground = theme.colorScheme.onSurfaceVariant;
    } else if (label == 'Manual') {
      background = theme.colorScheme.secondaryContainer;
      foreground = theme.colorScheme.onSecondaryContainer;
    } else {
      background = theme.colorScheme.primaryContainer;
      foreground = theme.colorScheme.onPrimaryContainer;
    }

    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall?.copyWith(color: foreground),
      backgroundColor: background,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
