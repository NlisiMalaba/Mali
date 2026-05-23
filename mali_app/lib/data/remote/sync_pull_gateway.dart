import 'package:dio/dio.dart';
import 'package:mali_app/data/remote/dto/transaction_dto.dart';
import 'package:mali_app/data/remote/mappers/remote_transaction_mapper.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/usecases/sync_usecase.dart';

class SyncPullGateway implements ISyncPullGateway {
  const SyncPullGateway({
    required Dio dio,
  }) : _dio = dio;

  static const String _syncPullPath = '/v1/sync/pull';
  static const String _transactionsPath = '/v1/transactions';

  final Dio _dio;

  @override
  Future<PullResult> pullChanges({required DateTime since}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _syncPullPath,
      queryParameters: {
        'since': since.toUtc().toIso8601String(),
        'limit': 100,
      },
    );

    final payload = response.data;
    if (payload == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Sync pull response was empty.',
      );
    }

    final rawChanges = payload['changes'] as List<dynamic>? ?? const [];
    final transactions = <Transaction>[];

    for (final rawChange in rawChanges) {
      if (rawChange is! Map<String, dynamic>) {
        continue;
      }

      final entityType = rawChange['entity_type'] as String? ?? '';
      final operation = rawChange['operation'] as String? ?? '';
      final entityId = rawChange['entity_id'] as String?;

      if (entityType != 'transaction' || entityId == null || operation == 'delete') {
        continue;
      }

      final transaction = await _fetchTransaction(entityId);
      if (transaction != null) {
        transactions.add(transaction);
      }
    }

    return PullResult(transactions: transactions);
  }

  Future<Transaction?> _fetchTransaction(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_transactionsPath/$id');
      final payload = response.data;
      if (payload == null || payload['transaction'] == null) {
        return null;
      }

      final dto = TransactionDto.fromJson(payload['transaction'] as Map<String, dynamic>);
      return RemoteTransactionMapper.toDomain(dto);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}
