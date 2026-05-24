import 'package:mali_app/domain/entities/user.dart';

class LoginInput {
  const LoginInput({
    required this.password,
    this.email,
    this.phone,
  });

  final String password;
  final String? email;
  final String? phone;
}

class RegisterInput {
  const RegisterInput({
    required this.name,
    required this.password,
    this.email,
    this.phone,
  });

  final String name;
  final String password;
  final String? email;
  final String? phone;
}

abstract interface class IAuthRepository {
  Future<User?> loadPersistedSession();

  Future<User> login(LoginInput input);

  Future<User> register(RegisterInput input);

  Future<void> logout();
}
