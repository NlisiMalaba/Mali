import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/providers/pin_lock_providers.dart';

final pinLockLifecycleListenerProvider = Provider<void>((ref) {
  final observer = _PinLockLifecycleObserver(ref);
  final binding = WidgetsBinding.instance;
  binding.addObserver(observer);
  ref.onDispose(() => binding.removeObserver(observer));
});

class _PinLockLifecycleObserver extends WidgetsBindingObserver {
  _PinLockLifecycleObserver(this._ref);

  final Ref _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _ref.read(pinLockControllerProvider.notifier).lockIfEnabled();
      case AppLifecycleState.resumed:
      case AppLifecycleState.detached:
        break;
    }
  }
}
