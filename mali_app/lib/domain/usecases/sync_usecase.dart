import 'package:fpdart/fpdart.dart';
import 'package:mali_app/core/error/failure.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';

class SyncUseCase {
  const SyncUseCase({
    required ITransactionRepository transactionRepository,
    required ISyncPushGateway syncPushGateway,
    required ISyncPullGateway syncPullGateway,
  })  : _transactionRepository = transactionRepository,
        _syncPushGateway = syncPushGateway,
        _syncPullGateway = syncPullGateway;

  final ITransactionRepository _transactionRepository;
  final ISyncPushGateway _syncPushGateway;
  final ISyncPullGateway _syncPullGateway;

  Future<Either<Failure, SyncResult>> call({
    required DateTime since,
  }) async {
    try {
      final unsynced = await _transactionRepository.listUnsynced();
      final pushResult = await _syncPushGateway.pushTransactions(unsynced);

      for (final synced in pushResult.accepted) {
        await _transactionRepository.save(
          synced.copyWith(
            isSynced: true,
            updatedAt: DateTime.now(),
          ),
        );
      }

      final pulledChanges = await _syncPullGateway.pullChanges(since: since);
      for (final change in pulledChanges.transactions) {
        await _transactionRepository.save(change.copyWith(isSynced: true));
      }

      return right(
        SyncResult(
          pushedAcceptedCount: pushResult.accepted.length,
          pushedRejectedCount: pushResult.rejected.length,
          pulledCount: pulledChanges.transactions.length,
          syncCompletedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      return left(
        NetworkFailure(
          message: 'Sync failed. Please retry.',
          cause: error,
        ),
      );
    }
  }
}

abstract interface class ISyncPushGateway {
  Future<PushResult> pushTransactions(List<Transaction> transactions);
}

abstract interface class ISyncPullGateway {
  Future<PullResult> pullChanges({required DateTime since});
}

class PushResult {
  const PushResult({
    required this.accepted,
    required this.rejected,
  });

  final List<Transaction> accepted;
  final List<RejectedSyncItem> rejected;
}

class RejectedSyncItem {
  const RejectedSyncItem({
    required this.transaction,
    required this.reason,
  });

  final Transaction transaction;
  final String reason;
}

class PullResult {
  const PullResult({
    required this.transactions,
  });

  final List<Transaction> transactions;
}

class SyncResult {
  const SyncResult({
    required this.pushedAcceptedCount,
    required this.pushedRejectedCount,
    required this.pulledCount,
    required this.syncCompletedAt,
  });

  final int pushedAcceptedCount;
  final int pushedRejectedCount;
  final int pulledCount;
  final DateTime syncCompletedAt;
}
