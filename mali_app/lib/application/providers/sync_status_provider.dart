import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/sync_providers.dart';

/// When the last successful sync finished, or null if this device never synced.
final lastSyncTimeProvider = FutureProvider.autoDispose<DateTime?>((ref) async {
  final since = await ref.watch(lastSyncStoreProvider).readSince();
  return since.millisecondsSinceEpoch == 0 ? null : since.toLocal();
});
