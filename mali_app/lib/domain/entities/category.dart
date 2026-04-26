class Category {
  const Category({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorHex,
    required this.isSystem,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  static const Object _unset = Object();

  final String id;
  final String? userId;
  final String name;
  final String type;
  final String iconKey;
  final String colorHex;
  final bool isSystem;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Category copyWith({
    String? id,
    Object? userId = _unset,
    String? name,
    String? type,
    String? iconKey,
    String? colorHex,
    bool? isSystem,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) {
    return Category(
      id: id ?? this.id,
      userId: identical(userId, _unset) ? this.userId : userId as String?,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      isSystem: isSystem ?? this.isSystem,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.type == type &&
        other.iconKey == iconKey &&
        other.colorHex == colorHex &&
        other.isSystem == isSystem &&
        other.isArchived == isArchived &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        name,
        type,
        iconKey,
        colorHex,
        isSystem,
        isArchived,
        createdAt,
        updatedAt,
        deletedAt,
      );
}
