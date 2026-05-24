import 'package:mali_app/data/remote/dto/auth_dto.dart';
import 'package:mali_app/domain/entities/user.dart';

abstract final class AuthUserMapper {
  static User toDomain(UserProfileDto dto) {
    return User(
      id: dto.id,
      email: dto.email,
      phone: dto.phone,
      name: dto.name,
      createdAt: DateTime.parse(dto.createdAt),
    );
  }
}
