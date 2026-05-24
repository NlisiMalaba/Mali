import 'dart:async';

sealed class AuthSessionEvent {
  const AuthSessionEvent();
}

final class AuthSessionExpired extends AuthSessionEvent {
  const AuthSessionExpired();
}

/// Broadcasts auth session changes for app-wide handling (e.g. redirect to login).
class AuthSessionEvents {
  AuthSessionEvents._();

  static final AuthSessionEvents instance = AuthSessionEvents._();

  final StreamController<AuthSessionEvent> _controller =
      StreamController<AuthSessionEvent>.broadcast();

  Stream<AuthSessionEvent> get stream => _controller.stream;

  void emitSessionExpired() {
    if (!_controller.isClosed) {
      _controller.add(const AuthSessionExpired());
    }
  }
}
