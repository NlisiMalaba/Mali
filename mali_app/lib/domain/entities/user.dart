class User {
  const User({
    required this.id,
    required this.name,
    required this.createdAt,
    this.email,
    this.phone,
  });

  final String id;
  final String? email;
  final String? phone;
  final String name;
  final DateTime createdAt;

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? name,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
