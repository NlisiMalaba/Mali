import 'package:dio/dio.dart';
import 'package:mali_app/application/providers/auth_store_providers.dart';
import 'package:mali_app/data/remote/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client_provider.g.dart';

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  return ApiClient(
    tokenStore: ref.watch(authTokenStoreProvider),
  );
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  return ref.watch(apiClientProvider).dio;
}
