import 'package:dio/dio.dart';
import 'package:mali_app/data/remote/dto/transaction_dto.dart';
import 'package:mali_app/data/remote/mappers/remote_transaction_mapper.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';

abstract interface class IRemoteTransactionRepository {
  Future<Transaction> create(Transaction transaction);

  Future<RemoteTransactionListResult> list({
    required TransactionQuery query,
  });
}

class RemoteTransactionRepository implements IRemoteTransactionRepository {
  const RemoteTransactionRepository({
    required Dio dio,
  }) : _dio = dio;

  static const String _transactionsPath = '/v1/transactions';

  final Dio _dio;

  @override
  Future<Transaction> create(Transaction transaction) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _transactionsPath,
      data: RemoteTransactionMapper.toCreateRequest(transaction).toJson(),
    );

    final payload = response.data;
    if (payload == null || payload['transaction'] == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Transaction create response was empty.',
      );
    }

    final dto = TransactionDto.fromJson(payload['transaction'] as Map<String, dynamic>);
    return RemoteTransactionMapper.toDomain(dto);
  }

  @override
  Future<RemoteTransactionListResult> list({
    required TransactionQuery query,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _transactionsPath,
      queryParameters: RemoteTransactionMapper.toListQueryParams(query),
    );

    final payload = response.data;
    if (payload == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Transaction list response was empty.',
      );
    }

    final listDto = TransactionListResponseDto.fromJson(payload);
    return RemoteTransactionListResult(
      transactions: RemoteTransactionMapper.toDomainList(listDto.transactions),
      nextCursor: RemoteTransactionMapper.toDomainCursor(listDto.nextCursor),
    );
  }
}
