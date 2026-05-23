class CreateTransactionRequestDto {
  const CreateTransactionRequestDto({
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.currency,
    this.notes,
    required this.source,
    required this.transactedAt,
    this.syncId,
    this.exchangeRate,
  });

  final String walletId;
  final String? categoryId;
  final String type;
  final String amount;
  final String currency;
  final String? notes;
  final String source;
  final String transactedAt;
  final String? syncId;
  final String? exchangeRate;

  Map<String, dynamic> toJson() {
    return {
      'wallet_id': walletId,
      if (categoryId != null) 'category_id': categoryId,
      'type': type,
      'amount': amount,
      'currency': currency,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'source': source,
      'transacted_at': transactedAt,
      if (syncId != null) 'sync_id': syncId,
      if (exchangeRate != null && exchangeRate!.isNotEmpty) 'exchange_rate': exchangeRate,
    };
  }
}

class TransactionDto {
  const TransactionDto({
    required this.id,
    required this.userId,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.currency,
    this.notes,
    required this.source,
    required this.transactedAt,
    required this.createdAt,
    this.syncId,
    this.exchangeRate,
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) {
    return TransactionDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      walletId: json['wallet_id'] as String,
      categoryId: json['category_id'] as String?,
      type: json['type'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      notes: json['notes'] as String?,
      source: json['source'] as String,
      transactedAt: json['transacted_at'] as String,
      createdAt: json['created_at'] as String,
      syncId: json['sync_id'] as String?,
      exchangeRate: json['exchange_rate'] as String?,
    );
  }

  final String id;
  final String userId;
  final String walletId;
  final String? categoryId;
  final String type;
  final String amount;
  final String currency;
  final String? notes;
  final String source;
  final String transactedAt;
  final String createdAt;
  final String? syncId;
  final String? exchangeRate;
}

class TransactionListResponseDto {
  const TransactionListResponseDto({
    required this.transactions,
    this.nextCursor,
  });

  factory TransactionListResponseDto.fromJson(Map<String, dynamic> json) {
    final rawTransactions = json['transactions'] as List<dynamic>? ?? const [];
    final rawCursor = json['next_cursor'] as Map<String, dynamic>?;

    return TransactionListResponseDto(
      transactions: rawTransactions
          .map((item) => TransactionDto.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      nextCursor: rawCursor == null ? null : TransactionCursorDto.fromJson(rawCursor),
    );
  }

  final List<TransactionDto> transactions;
  final TransactionCursorDto? nextCursor;
}

class TransactionCursorDto {
  const TransactionCursorDto({
    required this.id,
    required this.transactedAt,
  });

  factory TransactionCursorDto.fromJson(Map<String, dynamic> json) {
    return TransactionCursorDto(
      id: json['id'] as String,
      transactedAt: json['transacted_at'] as String,
    );
  }

  final String id;
  final String transactedAt;
}
