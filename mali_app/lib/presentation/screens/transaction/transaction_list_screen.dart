import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/transaction_list_provider.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/presentation/models/transaction_list_item.dart';
import 'package:mali_app/application/providers/transaction_list_filters_provider.dart';
import 'package:mali_app/presentation/widgets/transaction/add_transaction_sheet.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_filter_bar.dart';
import 'package:mali_app/presentation/widgets/transaction/transaction_tile.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({
    this.walletId,
    super.key,
  });

  final String? walletId;

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
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

    final appBarTitle = widget.walletId == null
        ? 'Transactions'
        : walletAsync?.when(
              data: (wallet) => wallet?.name ?? 'Transactions',
              loading: () => 'Transactions',
              error: (_, __) => 'Transactions',
            ) ??
            'Transactions';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        automaticallyImplyLeading: widget.walletId != null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddTransactionSheet.show(
          context,
          initialWalletId: widget.walletId,
        ),
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TransactionFilterBar(scopedWalletId: widget.walletId),
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
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
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
                      padding: const EdgeInsets.only(bottom: 88),
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
                          TransactionDateHeaderItem(:final label) => Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 20, 16, 8),
                              child: Text(
                                label,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          TransactionEntryItem(:final transaction) =>
                            Dismissible(
                              key: ValueKey(transaction.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                color: theme.colorScheme.errorContainer,
                                child: Icon(
                                  Icons.delete_outline,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                              onDismissed: (_) =>
                                  _onTransactionDismissed(transaction),
                              child: TransactionTile(transaction: transaction),
                            ),
                        };
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
