import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists recently used wallet ids.
class RecentWalletStore {
  RecentWalletStore({this.maxRecent = 8});

  static const _fileName = 'recent_wallets.json';

  final int maxRecent;

  Future<List<String>> readAll() async {
    final file = await _file();
    if (!await file.exists()) {
      return const [];
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        return const [];
      }
      return decoded.whereType<String>().toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeAll(List<String> walletIds) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(walletIds));
  }

  List<String> recordUsage({
    required List<String> current,
    required String walletId,
  }) {
    final next = List<String>.from(current)..remove(walletId);
    next.insert(0, walletId);
    return next.take(maxRecent).toList(growable: false);
  }

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}
