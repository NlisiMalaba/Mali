import 'package:dio/dio.dart';

/// Retries transient network failures with exponential backoff.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = maxRetryAttempts,
    List<Duration>? backoffDurations,
  })  : _dio = dio,
        _backoffDurations = backoffDurations ?? retryBackoffDurations;

  static const int maxRetryAttempts = 3;
  static const String retryCountExtraKey = 'retry_count';

  static const List<Duration> retryBackoffDurations = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  final Dio _dio;
  final int maxRetries;
  final List<Duration> _backoffDurations;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final retryCount = (err.requestOptions.extra[retryCountExtraKey] as int?) ?? 0;
    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    final delayIndex = retryCount.clamp(0, _backoffDurations.length - 1);
    await Future<void>.delayed(_backoffDurations[delayIndex]);

    final requestOptions = err.requestOptions;
    requestOptions.extra[retryCountExtraKey] = retryCount + 1;

    try {
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.badResponse) {
      return false;
    }

    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.badResponse ||
      DioExceptionType.cancel ||
      DioExceptionType.badCertificate ||
      DioExceptionType.unknown =>
        false,
    };
  }
}
