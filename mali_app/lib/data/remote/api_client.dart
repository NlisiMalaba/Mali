import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mali_app/core/auth/auth_session_events.dart';
import 'package:mali_app/core/auth/auth_token_store.dart';
import 'package:mali_app/core/config/api_config.dart';
import 'package:mali_app/data/remote/auth_interceptor.dart';
import 'package:mali_app/data/remote/auth_refresh_gateway.dart';
import 'package:mali_app/data/remote/retry_interceptor.dart';

/// Configured HTTP client for the Mali API.
class ApiClient {
  ApiClient({
    Dio? dio,
    IAuthTokenStore? tokenStore,
    IAuthRefreshGateway? refreshGateway,
    AuthSessionEvents? sessionEvents,
  }) : _dio = dio ??
            _createDio(
              tokenStore: tokenStore ?? const SecureAuthTokenStore(),
              refreshGateway: refreshGateway,
              sessionEvents: sessionEvents ?? AuthSessionEvents.instance,
            );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  final Dio _dio;

  Dio get dio => _dio;

  static Dio _createDio({
    required IAuthTokenStore tokenStore,
    IAuthRefreshGateway? refreshGateway,
    required AuthSessionEvents sessionEvents,
  }) {
    final client = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );

    client.interceptors.add(
      AuthInterceptor(
        dio: client,
        tokenStore: tokenStore,
        refreshGateway: refreshGateway ?? AuthRefreshGateway(dio: refreshDio),
        sessionEvents: sessionEvents,
      ),
    );

    if (kDebugMode) {
      client.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }

    client.interceptors.add(
      RetryInterceptor(dio: client),
    );

    return client;
  }
}
