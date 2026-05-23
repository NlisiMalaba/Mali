import 'package:mali_app/data/repositories/remote_transaction_repository.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/usecases/sync_usecase.dart';

class TransactionListSyncPushGateway implements ISyncPushGateway {
  const TransactionListSyncPushGateway({
    required IRemoteTransactionRepository remoteTransactionRepository,
  }) : _remoteTransactionRepository = remoteTransactionRepository;

  final IRemoteTransactionRepository _remoteTransactionRepository;

  @override
  Future<PushResult> pushTransactions(List<Transaction> transactions) async {
    final accepted = <Transaction>[];
    final rejected = <RejectedSyncItem>[];

    for (final transaction in transactions) {
      try {
        final created = await _remoteTransactionRepository.create(transaction);
        accepted.add(created);
      } catch (error) {
        rejected.add(
          RejectedSyncItem(
            transaction: transaction,
            reason: error.toString(),
          ),
        );
      }
    }

    return PushResult(
      accepted: accepted,
      rejected: rejected,
    );
  }
}
