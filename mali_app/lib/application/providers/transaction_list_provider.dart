import 'package:mali_app/application/providers/repository_providers.dart';
import 'package:mali_app/application/providers/sync_providers.dart';
import 'package:mali_app/application/providers/transaction_list_filters_provider.dart';
import 'package:mali_app/application/providers/use_case_providers.dart';
import 'package:mali_app/core/constants/transaction_list_constants.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_list_provider.g.dart';

class TransactionListState {
  const TransactionListState({
    this.items = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<Transaction> items;
  final bool hasMore;
  final bool isLoadingMore;

  TransactionListState copyWith({
    List<Transaction>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TransactionListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

@riverpod
Stream<List<Transaction>> transactionListWatch(
  Ref ref,
  String? scopedWalletId,
) {
  final filters = ref.watch(transactionListFiltersProvider(scopedWalletId));
  return ref.watch(transactionRepositoryProvider).watchList(
        query: filters.toWatchQuery(scopedWalletId),
      );
}

@riverpod
class TransactionListController extends _$TransactionListController {
  @override
  TransactionListState build(String? scopedWalletId) {
    ref.listen(
      transactionListFiltersProvider(scopedWalletId),
      (previous, next) {
        if (previous != next) {
          state = const TransactionListState();
        }
      },
    );

    ref.listen(
      transactionListWatchProvider(scopedWalletId),
      (_, next) {
        next.whenData(_applyLivePage);
      },
      fireImmediately: true,
    );
    return const TransactionListState();
  }

  void _applyLivePage(List<Transaction> livePage) {
    state = _mergeLivePage(state, livePage);
  }

  TransactionListState _mergeLivePage(
    TransactionListState current,
    List<Transaction> livePage,
  ) {
    if (livePage.isEmpty && current.items.isEmpty) {
      return const TransactionListState(hasMore: false);
    }

    final liveIds = livePage.map((transaction) => transaction.id).toSet();
    final olderTail = current.items
        .where((transaction) => !liveIds.contains(transaction.id))
        .toList();
    final merged = [...livePage, ...olderTail];

    return current.copyWith(
      items: merged,
      hasMore: livePage.length >= TransactionListConstants.pageSize ||
          current.hasMore,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.items.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    final filters = ref.read(transactionListFiltersProvider(scopedWalletId));
    final last = state.items.last;
    final nextPage = await ref.read(transactionRepositoryProvider).list(
          query: filters.toListQuery(
            scopedWalletId: scopedWalletId,
            cursor: TransactionCursor(
              transactionDate: last.transactionDate,
              transactionId: last.id,
            ),
            limit: TransactionListConstants.pageSize,
          ),
        );

    final existingIds = state.items.map((transaction) => transaction.id).toSet();
    final newItems = nextPage
        .where((transaction) => !existingIds.contains(transaction.id))
        .toList();

    state = state.copyWith(
      items: [...state.items, ...newItems],
      hasMore: nextPage.length >= TransactionListConstants.pageSize,
      isLoadingMore: false,
    );
  }
}

@riverpod
Future<void> refreshTransactionsSync(Ref ref) async {
  final store = ref.read(lastSyncStoreProvider);
  final since = await store.readSince();
  final result = await ref.read(syncUseCaseProvider)(since: since);

  return result.fold(
    (failure) => throw failure,
    (syncResult) => store.writeSince(syncResult.syncCompletedAt),
  );
}
