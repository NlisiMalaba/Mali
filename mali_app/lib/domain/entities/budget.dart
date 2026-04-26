class Budget {
  const Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.currencyCode,
    required this.amount,
    required this.spentAmount,
    required this.month,
    required this.year,
    required this.rolloverEnabled,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  static const Object _unset = Object();

  final String id;
  final String userId;
  final String categoryId;
  final String currencyCode;
  final String amount;
  final String spentAmount;
  final int month;
  final int year;
  final bool rolloverEnabled;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? currencyCode,
    String? amount,
    String? spentAmount,
    int? month,
    int? year,
    bool? rolloverEnabled,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      currencyCode: currencyCode ?? this.currencyCode,
      amount: amount ?? this.amount,
      spentAmount: spentAmount ?? this.spentAmount,
      month: month ?? this.month,
      year: year ?? this.year,
      rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.id == id &&
        other.userId == userId &&
        other.categoryId == categoryId &&
        other.currencyCode == currencyCode &&
        other.amount == amount &&
        other.spentAmount == spentAmount &&
        other.month == month &&
        other.year == year &&
        other.rolloverEnabled == rolloverEnabled &&
        other.isSynced == isSynced &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        categoryId,
        currencyCode,
        amount,
        spentAmount,
        month,
        year,
        rolloverEnabled,
        isSynced,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
