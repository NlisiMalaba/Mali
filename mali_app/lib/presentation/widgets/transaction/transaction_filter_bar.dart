import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/transaction_list_filters_provider.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/presentation/utils/transaction_filter_labels.dart';

class TransactionFilterBar extends ConsumerWidget {
  const TransactionFilterBar({
    required this.scopedWalletId,
    super.key,
  });

  final String? scopedWalletId;

  Future<void> _pickCategory(BuildContext context, WidgetRef ref) async {
    final categories = ref.read(allCategoriesProvider);
    final filters = ref.read(transactionListFiltersProvider(scopedWalletId));
    final selected = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CategoryFilterSheet(
        categories: categories,
        selectedCategoryId: filters.categoryId,
      ),
    );

    if (selected == null || !context.mounted) {
      return;
    }

    ref
        .read(transactionListFiltersProvider(scopedWalletId).notifier)
        .setCategory(selected.id);
  }

  Future<void> _pickWallet(BuildContext context, WidgetRef ref) async {
    final wallets = await ref.read(activeWalletsProvider.future);
    if (!context.mounted) {
      return;
    }
    final filters = ref.read(transactionListFiltersProvider(scopedWalletId));
    final selected = await showModalBottomSheet<String?>(
      context: context,
      useSafeArea: true,
      builder: (context) => _WalletFilterSheet(
        wallets: wallets,
        selectedWalletId: filters.walletId,
      ),
    );

    if (!context.mounted) {
      return;
    }

    ref
        .read(transactionListFiltersProvider(scopedWalletId).notifier)
        .setWallet(selected);
  }

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final filters = ref.read(transactionListFiltersProvider(scopedWalletId));
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: filters.dateFrom != null && filters.dateTo != null
          ? DateTimeRange(start: filters.dateFrom!, end: filters.dateTo!)
          : null,
    );

    if (picked == null || !context.mounted) {
      return;
    }

    ref.read(transactionListFiltersProvider(scopedWalletId).notifier).setDateRange(
          from: picked.start,
          to: picked.end,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(transactionListFiltersProvider(scopedWalletId));
    final theme = Theme.of(context);
    final showWalletFilter = scopedWalletId == null;

    final activeChips = <Widget>[];

    if (filters.categoryId != null) {
      final category = ref.watch(categoryByIdProvider(filters.categoryId!));
      if (category != null) {
        activeChips.add(
          InputChip(
            key: Key('active-filter-category-${category.id}'),
            label: Text(TransactionFilterLabels.categoryLabel(category)),
            onDeleted: () => ref
                .read(transactionListFiltersProvider(scopedWalletId).notifier)
                .clearCategory(),
          ),
        );
      }
    }

    if (showWalletFilter && filters.walletId != null) {
      final walletAsync = ref.watch(walletByIdProvider(filters.walletId!));
      final walletName = walletAsync.value?.name;
      if (walletName != null) {
        activeChips.add(
          InputChip(
            key: Key('active-filter-wallet-${filters.walletId}'),
            label: Text(walletName),
            onDeleted: () => ref
                .read(transactionListFiltersProvider(scopedWalletId).notifier)
                .clearWallet(),
          ),
        );
      }
    }

    if (filters.dateFrom != null || filters.dateTo != null) {
      activeChips.add(
        InputChip(
          key: const Key('active-filter-date-range'),
          label: Text(TransactionFilterLabels.dateRangeLabel(filters)),
          onDeleted: () => ref
              .read(transactionListFiltersProvider(scopedWalletId).notifier)
              .clearDateRange(),
        ),
      );
    }

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                ActionChip(
                  key: const Key('filter-chip-category'),
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  label: const Text('Category'),
                  onPressed: () => _pickCategory(context, ref),
                ),
                if (showWalletFilter) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    key: const Key('filter-chip-wallet'),
                    avatar: const Icon(Icons.account_balance_wallet_outlined,
                        size: 18),
                    label: const Text('Wallet'),
                    onPressed: () => _pickWallet(context, ref),
                  ),
                ],
                const SizedBox(width: 8),
                ActionChip(
                  key: const Key('filter-chip-date'),
                  avatar: const Icon(Icons.date_range_outlined, size: 18),
                  label: const Text('Date'),
                  onPressed: () => _pickDateRange(context, ref),
                ),
              ],
            ),
          ),
          if (activeChips.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  for (var i = 0; i < activeChips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    activeChips[i],
                  ],
                  if (filters.hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    ActionChip(
                      key: const Key('filter-clear-all'),
                      label: const Text('Clear all'),
                      onPressed: () => ref
                          .read(
                            transactionListFiltersProvider(scopedWalletId)
                                .notifier,
                          )
                          .clearAll(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryFilterSheet extends StatelessWidget {
  const _CategoryFilterSheet({
    required this.categories,
    required this.selectedCategoryId,
  });

  final List<Category> categories;
  final String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Filter by category',
              style: theme.textTheme.titleMedium,
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category.name),
                  trailing: selectedCategoryId == category.id
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletFilterSheet extends StatelessWidget {
  const _WalletFilterSheet({
    required this.wallets,
    required this.selectedWalletId,
  });

  final List<Wallet> wallets;
  final String? selectedWalletId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Filter by wallet',
              style: theme.textTheme.titleMedium,
            ),
          ),
          ListTile(
            title: const Text('All wallets'),
            trailing: selectedWalletId == null
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () => Navigator.of(context).pop<String?>(null),
          ),
          ...wallets.map(
            (wallet) => ListTile(
              title: Text(wallet.name),
              subtitle: Text(wallet.currencyCode),
              trailing: selectedWalletId == wallet.id
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(wallet.id),
            ),
          ),
        ],
      ),
    );
  }
}
