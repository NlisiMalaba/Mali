import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LastSyncStore {
  const LastSyncStore({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _lastSyncKey = 'last_sync_at';

  final FlutterSecureStorage _secureStorage;

  Future<DateTime> readSince() async {
    final raw = await _secureStorage.read(key: _lastSyncKey);
    if (raw == null || raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.parse(raw);
  }

  Future<void> writeSince(DateTime value) {
    return _secureStorage.write(
      key: _lastSyncKey,
      value: value.toUtc().toIso8601String(),
    );
  }
}
