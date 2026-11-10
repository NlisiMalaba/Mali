import 'dart:convert';
import 'dart:io';

import 'package:mali_app/domain/entities/app_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// Persists [AppPreferences] as JSON in the app documents directory.
///
/// File-based (not Riverpod-bound) so WorkManager background isolates can read
/// the same settings as the UI.
class AppPreferencesStore {
  const AppPreferencesStore();

  static const _fileName = 'app_preferences.json';

  Future<AppPreferences> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return const AppPreferences();
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return const AppPreferences();
      }
      return AppPreferences.fromJson(decoded);
    } catch (_) {
      return const AppPreferences();
    }
  }

  Future<void> write(AppPreferences preferences) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(preferences.toJson()));
  }

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}
