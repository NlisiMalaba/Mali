import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/connectivity_provider.dart';
import 'package:mali_app/application/providers/sync_providers.dart';

final connectivitySyncListenerProvider = Provider<void>((ref) {
  ref.listen(connectivityProvider, (previous, next) {
    next.whenData((isOnline) {
      final wasOnline = previous?.value ?? false;
      if (!wasOnline && isOnline) {
        final auth = ref.read(authProvider);
        if (!auth.hasValue || auth.value == null) {
          return;
        }

        unawaited(
          ref.read(backgroundSyncServiceProvider).runSyncIfOnline(),
        );
      }
    });
  });
});
