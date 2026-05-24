import 'package:mali_app/core/auth/auth_token_store.dart';
import 'package:mali_app/core/auth/auth_user_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_store_providers.g.dart';

@Riverpod(keepAlive: true)
IAuthTokenStore authTokenStore(Ref ref) {
  return const SecureAuthTokenStore();
}

@Riverpod(keepAlive: true)
IAuthUserStore authUserStore(Ref ref) {
  return const SecureAuthUserStore();
}
