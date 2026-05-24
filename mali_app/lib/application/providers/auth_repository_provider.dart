import 'package:mali_app/application/providers/api_client_provider.dart';
import 'package:mali_app/application/providers/auth_store_providers.dart';
import 'package:mali_app/data/repositories/auth_repository.dart';
import 'package:mali_app/domain/repositories/auth_repository.dart' as domain;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository_provider.g.dart';

@Riverpod(keepAlive: true)
domain.IAuthRepository authRepository(Ref ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
    userStore: ref.watch(authUserStoreProvider),
  );
}
