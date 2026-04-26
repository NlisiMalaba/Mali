class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.goalId,
    this.walletId,
    this.transactionId,
    required this.amount,
    required this.currencyCode,
    this.note,
    required this.contributionDate,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  static const Object _unset = Object();

  final String id;
  final String goalId;
  final String? walletId;
  final String? transactionId;
  final String amount;
  final String currencyCode;
  final String? note;
  final DateTime contributionDate;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  GoalContribution copyWith({
    String? id,
    String? goalId,
    Object? walletId = _unset,
    Object? transactionId = _unset,
    String? amount,
    String? currencyCode,
    Object? note = _unset,
    DateTime? contributionDate,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) {
    return GoalContribution(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      walletId: identical(walletId, _unset) ? this.walletId : walletId as String?,
      transactionId: identical(transactionId, _unset) ? this.transactionId : transactionId as String?,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      note: identical(note, _unset) ? this.note : note as String?,
      contributionDate: contributionDate ?? this.contributionDate,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalContribution &&
        other.id == id &&
        other.goalId == goalId &&
        other.walletId == walletId &&
        other.transactionId == transactionId &&
        other.amount == amount &&
        other.currencyCode == currencyCode &&
        other.note == note &&
        other.contributionDate == contributionDate &&
        other.isSynced == isSynced &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        goalId,
        walletId,
        transactionId,
        amount,
        currencyCode,
        note,
        contributionDate,
        isSynced,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
