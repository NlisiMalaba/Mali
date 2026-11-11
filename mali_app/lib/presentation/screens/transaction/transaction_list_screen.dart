import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/providers/transaction_list_provider.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/presentation/models/transaction_list_item.dart';
import 'package:mali_app/application/providers/transaction_list_filters_provider.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_decorations.dart';
import 'package:mali_app/presentation/widgets/transaction/activity_type_filter_chips.dart';
import 'package:mali_app/presentation/widgets/transaction/add_transaction_sheet.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_tile.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({
    this.walletId,
    super.key,
  });

  static const Key exportButtonKey = Key('activity-export-button');

  final String? walletId;

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      ref
          .read(transactionListControllerProvider(widget.walletId).notifier)
          .loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      ref
          .read(transactionListFiltersProvider(widget.walletId).notifier)
          .setSearchQuery(value);
    });
  }

  Future<void> _onRefresh() async {
    try {
      ref.invalidate(refreshTransactionsSyncProvider);
      await ref.read(refreshTransactionsSyncProvider.future);
    } on Failure catch (failure) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $error')),
      );
    }
  }

  Future<void> _onTransactionDismissed(Transaction transaction) async {
    final result = await ref.read(deleteTransactionUseCaseProvider)(
      transaction.id,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (deleted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _undoDelete(deleted),
            ),
          ),
        );
      },
    );
  }

  Future<void> _undoDelete(Transaction transaction) async {
    final result = await ref.read(restoreTransactionUseCaseProvider)(transaction);

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction restored')),
        );
      },
    );
  }

  Widget _headerButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Key? key,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        key: key,
        color: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: AppColors.onSurface, size: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState =
        ref.watch(transactionListControllerProvider(widget.walletId));
    final filters =
        ref.watch(transactionListFiltersProvider(widget.walletId));
    final walletAsync = widget.walletId == null
        ? null
        : ref.watch(walletByIdProvider(widget.walletId!));
    final theme = Theme.of(context);
    final groupedItems = buildGroupedTransactionListItems(listState.items);
    final canPop = GoRouter.of(context).canPop();

    final title = widget.walletId == null
        ? 'Activity'
        : walletAsync?.when(
              data: (wallet) => wallet?.name ?? 'Activity',
              loading: () => 'Activity',
              error: (_, _) => 'Activity',
            ) ??
            'Activity';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddTransactionSheet.show(
          context,
          initialWalletId: widget.walletId,
        ),
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  if (canPop || widget.walletId != null)
                    _headerButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Back',
                      onPressed: () {
                        if (canPop) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                  if (canPop || widget.walletId != null) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  _headerButton(
                    key: TransactionListScreen.exportButtonKey,
                    icon: Icons.file_download_outlined,
                    tooltip: 'Export',
                    onPressed: () => context.push('/export'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search transactions',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDecorations.radiusMd),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDecorations.radiusMd),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDecorations.radiusMd),
                    borderSide: const BorderSide(color: AppColors.navy),
                  ),
                ),
              ),
            ),
            ActivityTypeFilterChips(scopedWalletId: widget.walletId),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: groupedItems.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.35,
                            child: Center(
                              child: Text(
                                filters.hasActiveFilters
                                    ? 'No transactions match your filters.'
                                    : 'No transactions yet.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
                        itemCount: groupedItems.length +
                            (listState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= groupedItems.length) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final item = groupedItems[index];
                          return switch (item) {
                            TransactionDateHeaderItem(
                              :final label,
                              :final summary,
                            ) =>
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  4,
                                  index == 0 ? 0 : 18,
                                  4,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      label,
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (summary.isNotEmpty)
                                      Text(
                                        summary,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            TransactionEntryItem(:final transaction) =>
                              _ActivityTransactionCard(
                                transaction: transaction,
                                isFirstInGroup: index > 0 &&
                                    groupedItems[index - 1]
                                        is TransactionDateHeaderItem,
                                isLastInGroup: index ==
                                        groupedItems.length - 1 ||
                                    groupedItems[index + 1]
                                        is TransactionDateHeaderItem,
                                onDismissed: () =>
                                    _onTransactionDismissed(transaction),
                              ),
                          };
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTransactionCard extends StatelessWidget {
  const _ActivityTransactionCard({
    required this.transaction,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.onDismissed,
  });

  final Transaction transaction;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: isFirstInGroup
          ? const Radius.circular(AppDecorations.radiusLg)
          : Radius.zero,
      bottom: isLastInGroup
          ? const Radius.circular(AppDecorations.radiusLg)
          : Radius.zero,
    );

    return ClipRRect(
      borderRadius: radius,
      child: Dismissible(
        key: ValueKey(transaction.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: AppColors.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 20),
              SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        onDismissed: (_) => onDismissed(),
        child: ColoredBox(
          color: AppColors.surfaceContainerLowest,
          child: TransactionTile(
            transaction: transaction,
            compact: true,
          ),
        ),
      ),
    );
  }
}
