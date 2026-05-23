import 'package:mali_app/data/remote/dto/transaction_dto.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';

class RemoteTransactionMapper {
  const RemoteTransactionMapper._();

  static const String defaultSource = 'mobile';

  static CreateTransactionRequestDto toCreateRequest(Transaction transaction) {
    return CreateTransactionRequestDto(
      walletId: transaction.walletId,
      categoryId: transaction.categoryId,
      type: transaction.type,
      amount: transaction.amount,
      currency: transaction.currencyCode,
      notes: transaction.notes ?? transaction.title,
      source: defaultSource,
      transactedAt: transaction.transactionDate.toUtc().toIso8601String(),
      syncId: transaction.syncId,
      exchangeRate: transaction.exchangeRate,
    );
  }

  static Map<String, dynamic> toListQueryParams(TransactionQuery query) {
    final params = <String, dynamic>{
      'limit': query.limit,
    };

    if (query.walletId != null) {
      params['wallet_id'] = query.walletId;
    }
    if (query.categoryId != null) {
      params['category_id'] = query.categoryId;
    }
    if (query.dateFrom != null) {
      params['date_from'] = query.dateFrom!.toUtc().toIso8601String();
    }
    if (query.dateTo != null) {
      params['date_to'] = query.dateTo!.toUtc().toIso8601String();
    }
    if (query.type != null) {
      params['type'] = query.type;
    }
    if (query.cursor != null) {
      params['cursor_id'] = query.cursor!.transactionId;
      params['cursor_transacted_at'] =
          query.cursor!.transactionDate.toUtc().toIso8601String();
    }

    return params;
  }

  static Transaction toDomain(TransactionDto dto) {
    final createdAt = DateTime.parse(dto.createdAt);
    final transactedAt = DateTime.parse(dto.transactedAt);

    return Transaction(
      id: dto.id,
      userId: dto.userId,
      walletId: dto.walletId,
      categoryId: dto.categoryId,
      syncId: dto.syncId,
      type: dto.type,
      amount: dto.amount,
      currencyCode: dto.currency,
      exchangeRate: dto.exchangeRate,
      title: dto.notes ?? dto.source,
      notes: dto.notes,
      transactionDate: transactedAt,
      isSynced: true,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  static List<Transaction> toDomainList(List<TransactionDto> dtos) {
    return dtos.map(toDomain).toList(growable: false);
  }

  static TransactionCursor? toDomainCursor(TransactionCursorDto? dto) {
    if (dto == null) {
      return null;
    }
    return TransactionCursor(
      transactionDate: DateTime.parse(dto.transactedAt),
      transactionId: dto.id,
    );
  }
}

class RemoteTransactionListResult {
  const RemoteTransactionListResult({
    required this.transactions,
    this.nextCursor,
  });

  final List<Transaction> transactions;
  final TransactionCursor? nextCursor;
}
