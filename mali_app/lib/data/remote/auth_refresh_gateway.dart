import 'package:dio/dio.dart';
import 'package:mali_app/data/remote/dto/auth_dto.dart';

abstract interface class IAuthRefreshGateway {
  Future<AuthRefreshResponseDto> refresh({
    required String refreshToken,
    required String deviceId,
  });
}

class AuthRefreshGateway implements IAuthRefreshGateway {
  const AuthRefreshGateway({
    required Dio dio,
  }) : _dio = dio;

  static const String refreshPath = '/v1/auth/refresh';
  static const String refreshTokenCookieName = 'refresh_token';

  final Dio _dio;

  @override
  Future<AuthRefreshResponseDto> refresh({
    required String refreshToken,
    required String deviceId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      refreshPath,
      data: AuthRefreshRequestDto(
        refreshToken: refreshToken,
        deviceId: deviceId,
      ).toJson(),
    );

    final payload = response.data;
    final accessToken = payload?['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Refresh response did not include access_token.',
      );
    }

    final refreshFromBody = payload?['refresh_token'] as String?;
    final refreshFromCookie = readRefreshTokenFromHeaders(response.headers);

    return AuthRefreshResponseDto(
      accessToken: accessToken,
      refreshToken: refreshFromBody ?? refreshFromCookie,
    );
  }

  static String? readRefreshTokenFromHeaders(Headers headers) {
    final setCookie = headers.map['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) {
      return null;
    }

    const prefix = '$refreshTokenCookieName=';
    for (final cookie in setCookie) {
      final valuePart = cookie.split(';').first.trim();
      if (valuePart.startsWith(prefix)) {
        return Uri.decodeComponent(valuePart.substring(prefix.length));
      }
    }

    return null;
  }
}
