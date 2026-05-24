import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists recently used category ids grouped by transaction type.
class RecentCategoryStore {
  RecentCategoryStore({this.maxRecentPerType = 8});

  static const _fileName = 'recent_categories.json';

  final int maxRecentPerType;

  Future<Map<String, List<String>>> readAll() async {
    final file = await _file();
    if (!await file.exists()) {
      return {};
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      return decoded.map((type, ids) {
        if (ids is! List) {
          return MapEntry(type, const <String>[]);
        }
        return MapEntry(
          type,
          ids.whereType<String>().toList(growable: false),
        );
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> writeAll(Map<String, List<String>> data) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(data));
  }

  List<String> recordUsage({
    required Map<String, List<String>> current,
    required String type,
    required String categoryId,
  }) {
    final existing = List<String>.from(current[type] ?? const []);
    existing.remove(categoryId);
    existing.insert(0, categoryId);

    final next = Map<String, List<String>>.from(current);
    next[type] = existing.take(maxRecentPerType).toList(growable: false);
    return next[type]!;
  }

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}
