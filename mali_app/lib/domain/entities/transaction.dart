class Transaction {
  const Transaction({
    required this.id,
    required this.userId,
    required this.walletId,
    this.categoryId,
    this.syncId,
    required this.type,
    required this.amount,
    required this.currencyCode,
    this.exchangeRate,
    required this.title,
    this.notes,
    required this.transactionDate,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  static const Object _unset = Object();

  final String id;
  final String userId;
  final String walletId;
  final String? categoryId;
  final String? syncId;
  final String type;
  final String amount;
  final String currencyCode;
  final String? exchangeRate;
  final String title;
  final String? notes;
  final DateTime transactionDate;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Transaction copyWith({
    String? id,
    String? userId,
    String? walletId,
    Object? categoryId = _unset,
    Object? syncId = _unset,
    String? type,
    String? amount,
    String? currencyCode,
    Object? exchangeRate = _unset,
    String? title,
    Object? notes = _unset,
    DateTime? transactionDate,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      categoryId: identical(categoryId, _unset) ? this.categoryId : categoryId as String?,
      syncId: identical(syncId, _unset) ? this.syncId : syncId as String?,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: identical(exchangeRate, _unset) ? this.exchangeRate : exchangeRate as String?,
      title: title ?? this.title,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      transactionDate: transactionDate ?? this.transactionDate,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.userId == userId &&
        other.walletId == walletId &&
        other.categoryId == categoryId &&
        other.syncId == syncId &&
        other.type == type &&
        other.amount == amount &&
        other.currencyCode == currencyCode &&
        other.exchangeRate == exchangeRate &&
        other.title == title &&
        other.notes == notes &&
        other.transactionDate == transactionDate &&
        other.isSynced == isSynced &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        walletId,
        categoryId,
        syncId,
        type,
        amount,
        currencyCode,
        exchangeRate,
        title,
        notes,
        transactionDate,
        isSynced,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
