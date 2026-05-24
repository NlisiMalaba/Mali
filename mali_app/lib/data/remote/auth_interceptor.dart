import 'package:dio/dio.dart';
import 'package:mali_app/core/auth/auth_session_events.dart';
import 'package:mali_app/core/auth/auth_token_store.dart';
import 'package:mali_app/data/remote/auth_refresh_gateway.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required IAuthTokenStore tokenStore,
    required IAuthRefreshGateway refreshGateway,
    required AuthSessionEvents sessionEvents,
  })  : _dio = dio,
        _tokenStore = tokenStore,
        _refreshGateway = refreshGateway,
        _sessionEvents = sessionEvents;

  static const String authRetriedExtraKey = 'auth_retried';
  static const String authorizationHeader = 'Authorization';

  final Dio _dio;
  final IAuthTokenStore _tokenStore;
  final IAuthRefreshGateway _refreshGateway;
  final AuthSessionEvents _sessionEvents;

  Future<void>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStore.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers[authorizationHeader] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response?.statusCode != 401 || !_shouldAttemptRefresh(err.requestOptions)) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.extra[authRetriedExtraKey] == true) {
      await _handleSessionExpired();
      handler.next(err);
      return;
    }

    try {
      await _refreshAccessToken();
      final retryResponse = await _retryRequest(err.requestOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await _handleSessionExpired();
      handler.next(err);
    }
  }

  bool _shouldAttemptRefresh(RequestOptions options) {
    if (options.extra[authRetriedExtraKey] == true) {
      return false;
    }

    final path = options.uri.path;
    if (path.startsWith('/v1/auth/')) {
      return false;
    }

    return true;
  }

  Future<void> _refreshAccessToken() {
    final inFlight = _refreshFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final refresh = _performRefresh();
    _refreshFuture = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    });
  }

  Future<void> _performRefresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: AuthRefreshGateway.refreshPath),
        message: 'No refresh token available.',
      );
    }

    final deviceId = await _tokenStore.readOrCreateDeviceId();
    final refreshed = await _refreshGateway.refresh(
      refreshToken: refreshToken,
      deviceId: deviceId,
    );

    await _tokenStore.saveSession(
      accessToken: refreshed.accessToken,
      refreshToken: refreshed.refreshToken,
    );
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    final accessToken = await _tokenStore.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers[authorizationHeader] = 'Bearer $accessToken';
    } else {
      headers.remove(authorizationHeader);
    }

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
      options: Options(
        method: requestOptions.method,
        headers: headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        followRedirects: requestOptions.followRedirects,
        validateStatus: requestOptions.validateStatus,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        extra: {
          ...requestOptions.extra,
          authRetriedExtraKey: true,
        },
      ),
    );
  }

  Future<void> _handleSessionExpired() async {
    await _tokenStore.clear();
    _sessionEvents.emitSessionExpired();
  }
}
