import 'package:mali_app/application/providers/auth_repository_provider.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<User?> build() {
    return ref.read(authRepositoryProvider).loadPersistedSession();
  }

  Future<void> login(LoginInput input) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).login(input));
  }

  Future<void> register(RegisterInput input) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(input),
    );
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).logout();
      return null;
    });
  }
}
