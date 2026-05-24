import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/core/auth/auth_session_events.dart';

final authSessionListenerProvider = Provider<void>((ref) {
  final subscription = AuthSessionEvents.instance.stream.listen((event) {
    if (event is AuthSessionExpired) {
      ref.read(authProvider.notifier).logout();
    }
  });

  ref.onDispose(subscription.cancel);
});
