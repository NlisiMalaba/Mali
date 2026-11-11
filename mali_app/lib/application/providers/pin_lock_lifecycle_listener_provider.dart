import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/app_preferences_provider.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';
import 'package:mali_app/domain/entities/app_preferences.dart';

final pinLockLifecycleListenerProvider = Provider<void>((ref) {
  final observer = _PinLockLifecycleObserver(ref);
  final binding = WidgetsBinding.instance;
  binding.addObserver(observer);
  ref.onDispose(() {
    observer.dispose();
    binding.removeObserver(observer);
  });
});

class _PinLockLifecycleObserver extends WidgetsBindingObserver {
  _PinLockLifecycleObserver(this._ref);

  final Ref _ref;
  Timer? _lockTimer;

  void dispose() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _scheduleLock();
      case AppLifecycleState.inactive:
        // Transient overlays (share sheets, app switcher peeks) should not
        // start a grace timer; only immediate lock reacts here.
        if (_grace == AppLockGrace.immediately) {
          _scheduleLock();
        }
      case AppLifecycleState.resumed:
        _cancelScheduledLock();
      case AppLifecycleState.detached:
        break;
    }
  }

  AppLockGrace get _grace => _ref.read(appPreferencesProvider).appLockGrace;

  void _scheduleLock() {
    _cancelScheduledLock();
    final delay = _grace.delay;
    if (delay == Duration.zero) {
      _ref.read(pinLockControllerProvider.notifier).lockIfEnabled();
      return;
    }
    _lockTimer = Timer(delay, () {
      _ref.read(pinLockControllerProvider.notifier).lockIfEnabled();
    });
  }

  void _cancelScheduledLock() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }
}
