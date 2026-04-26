class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    required this.currencyCode,
    this.targetDate,
    required this.priorityOrder,
    required this.isCompleted,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  static const Object _unset = Object();

  final String id;
  final String userId;
  final String name;
  final String? emoji;
  final String targetAmount;
  final String currentAmount;
  final String currencyCode;
  final DateTime? targetDate;
  final int priorityOrder;
  final bool isCompleted;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? name,
    Object? emoji = _unset,
    String? targetAmount,
    String? currentAmount,
    String? currencyCode,
    Object? targetDate = _unset,
    int? priorityOrder,
    bool? isCompleted,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      emoji: identical(emoji, _unset) ? this.emoji : emoji as String?,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      targetDate: identical(targetDate, _unset) ? this.targetDate : targetDate as DateTime?,
      priorityOrder: priorityOrder ?? this.priorityOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavingsGoal &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.emoji == emoji &&
        other.targetAmount == targetAmount &&
        other.currentAmount == currentAmount &&
        other.currencyCode == currencyCode &&
        other.targetDate == targetDate &&
        other.priorityOrder == priorityOrder &&
        other.isCompleted == isCompleted &&
        other.isSynced == isSynced &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        name,
        emoji,
        targetAmount,
        currentAmount,
        currencyCode,
        targetDate,
        priorityOrder,
        isCompleted,
        isSynced,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
