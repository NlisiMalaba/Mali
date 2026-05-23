import 'package:dio/dio.dart';
import 'package:mali_app/data/remote/dto/sync_dto.dart';

abstract interface class ISyncPushGateway {
  Future<SyncPushResponseDto> pushChanges(List<SyncChangeRequestDto> changes);
}

class SyncPushGateway implements ISyncPushGateway {
  const SyncPushGateway({
    required Dio dio,
  }) : _dio = dio;

  static const String _syncPushPath = '/v1/sync/push';

  final Dio _dio;

  @override
  Future<SyncPushResponseDto> pushChanges(List<SyncChangeRequestDto> changes) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _syncPushPath,
      data: SyncPushRequestDto(changes: changes).toJson(),
    );

    final payload = response.data;
    if (payload == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Sync push response was empty.',
      );
    }

    return SyncPushResponseDto.fromJson(payload);
  }
}
