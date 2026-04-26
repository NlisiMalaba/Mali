import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus {
  authenticated,
  unauthenticated,
}

final authStatusProvider =
    NotifierProvider<AuthStatusNotifier, AuthStatus>(AuthStatusNotifier.new);

class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    return AuthStatus.unauthenticated;
  }

  void signIn() {
    state = AuthStatus.authenticated;
  }

  void signOut() {
    state = AuthStatus.unauthenticated;
  }
}
