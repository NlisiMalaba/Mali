class ApiConfig {
  const ApiConfig._();

  /// Production API by default so release APKs hit the live backend.
  /// Override for local Docker with:
  /// `--dart-define=MALI_API_BASE_URL=http://10.0.2.2:8082`
  static const String baseUrl = String.fromEnvironment(
    'MALI_API_BASE_URL',
    defaultValue: 'https://mali-api.nlisimalaba.co.zw',
  );
}
