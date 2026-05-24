class AuthRegisterRequestDto {
  const AuthRegisterRequestDto({
    required this.name,
    required this.password,
    this.email,
    this.phone,
  });

  final String name;
  final String password;
  final String? email;
  final String? phone;

  Map<String, dynamic> toJson() => {
        'name': name,
        'password': password,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };
}

class AuthLoginRequestDto {
  const AuthLoginRequestDto({
    required this.password,
    required this.deviceId,
    this.email,
    this.phone,
  });

  final String password;
  final String deviceId;
  final String? email;
  final String? phone;

  Map<String, dynamic> toJson() => {
        'password': password,
        'device_id': deviceId,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };
}

class AuthLogoutRequestDto {
  const AuthLogoutRequestDto({
    required this.refreshToken,
  });

  final String refreshToken;

  Map<String, dynamic> toJson() => {
        'refresh_token': refreshToken,
      };
}

class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.name,
    required this.createdAt,
    this.email,
    this.phone,
  });

  final String id;
  final String? email;
  final String? phone;
  final String name;
  final String createdAt;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class AuthRefreshRequestDto {
  const AuthRefreshRequestDto({
    required this.refreshToken,
    required this.deviceId,
  });

  final String refreshToken;
  final String deviceId;

  Map<String, dynamic> toJson() => {
        'refresh_token': refreshToken,
        'device_id': deviceId,
      };
}

class AuthRefreshResponseDto {
  const AuthRefreshResponseDto({
    required this.accessToken,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
}
