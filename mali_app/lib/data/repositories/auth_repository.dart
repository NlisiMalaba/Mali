import 'package:dio/dio.dart';
import 'package:mali_app/core/auth/auth_token_store.dart';
import 'package:mali_app/core/auth/auth_user_store.dart';
import 'package:mali_app/core/auth/jwt_utils.dart';
import 'package:mali_app/data/remote/auth_refresh_gateway.dart';
import 'package:mali_app/data/remote/dto/auth_dto.dart';
import 'package:mali_app/data/remote/mappers/auth_user_mapper.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/repositories/auth_repository.dart';

class AuthRepository implements IAuthRepository {
  const AuthRepository({
    required Dio dio,
    required IAuthTokenStore tokenStore,
    required IAuthUserStore userStore,
  })  : _dio = dio,
        _tokenStore = tokenStore,
        _userStore = userStore;

  static const String registerPath = '/v1/auth/register';
  static const String loginPath = '/v1/auth/login';
  static const String logoutPath = '/v1/auth/logout';

  final Dio _dio;
  final IAuthTokenStore _tokenStore;
  final IAuthUserStore _userStore;

  @override
  Future<User?> loadPersistedSession() async {
    final accessToken = await _tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final storedUser = await _userStore.readUser();
    if (storedUser == null) {
      await _tokenStore.clear();
      return null;
    }

    final subject = readJwtSubject(accessToken);
    if (subject != null && subject != storedUser.id) {
      await _clearSession();
      return null;
    }

    return storedUser;
  }

  @override
  Future<User> login(LoginInput input) async {
    final deviceId = await _tokenStore.readOrCreateDeviceId();
    final response = await _dio.post<Map<String, dynamic>>(
      loginPath,
      data: AuthLoginRequestDto(
        password: input.password,
        deviceId: deviceId,
        email: input.email,
        phone: input.phone,
      ).toJson(),
    );

    final accessToken = response.data?['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Login response did not include access_token.',
      );
    }

    final refreshToken = AuthRefreshGateway.readRefreshTokenFromHeaders(
      response.headers,
    );

    await _tokenStore.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final user = await _resolveUserAfterLogin(
      accessToken: accessToken,
      email: input.email,
      phone: input.phone,
    );
    await _userStore.saveUser(user);
    return user;
  }

  @override
  Future<User> register(RegisterInput input) async {
    final response = await _dio.post<Map<String, dynamic>>(
      registerPath,
      data: AuthRegisterRequestDto(
        name: input.name,
        password: input.password,
        email: input.email,
        phone: input.phone,
      ).toJson(),
    );

    final payload = response.data;
    final userJson = payload?['user'];
    if (userJson is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Register response did not include user.',
      );
    }

    final user = AuthUserMapper.toDomain(UserProfileDto.fromJson(userJson));
    await _userStore.saveUser(user);

    return login(
      LoginInput(
        password: input.password,
        email: input.email,
        phone: input.phone,
      ),
    );
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _dio.post<Map<String, dynamic>>(
          logoutPath,
          data: AuthLogoutRequestDto(refreshToken: refreshToken).toJson(),
        );
      } on DioException {
        // Clear local session even when the remote logout call fails.
      }
    }

    await _clearSession();
  }

  Future<User> _resolveUserAfterLogin({
    required String accessToken,
    String? email,
    String? phone,
  }) async {
    final storedUser = await _userStore.readUser();
    final subject = readJwtSubject(accessToken);
    if (storedUser != null && (subject == null || storedUser.id == subject)) {
      return storedUser.copyWith(
        email: email ?? storedUser.email,
        phone: phone ?? storedUser.phone,
      );
    }

    if (subject == null) {
      throw DioException(
        requestOptions: RequestOptions(path: loginPath),
        message: 'Access token did not include a user subject.',
      );
    }

    return User(
      id: subject,
      email: email,
      phone: phone,
      name: storedUser?.name ?? _defaultName(email, phone),
      createdAt: storedUser?.createdAt ?? DateTime.now().toUtc(),
    );
  }

  String _defaultName(String? email, String? phone) {
    if (email != null && email.isNotEmpty) {
      final localPart = email.split('@').first;
      if (localPart.isNotEmpty) {
        return localPart;
      }
    }
    if (phone != null && phone.isNotEmpty) {
      return phone;
    }
    return 'User';
  }

  Future<void> _clearSession() async {
    await Future.wait<void>([
      _tokenStore.clear(),
      _userStore.clearUser(),
    ]);
  }
}
