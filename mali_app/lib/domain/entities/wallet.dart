class Wallet {
  const Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.currencyCode,
    required this.balance,
    required this.isArchived,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  static const Object _unset = Object();

  final String id;
  final String userId;
  final String name;
  final String currencyCode;
  final String balance;
  final bool isArchived;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    String? currencyCode,
    String? balance,
    bool? isArchived,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      currencyCode: currencyCode ?? this.currencyCode,
      balance: balance ?? this.balance,
      isArchived: isArchived ?? this.isArchived,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wallet &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.currencyCode == currencyCode &&
        other.balance == balance &&
        other.isArchived == isArchived &&
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
        currencyCode,
        balance,
        isArchived,
        isSynced,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
