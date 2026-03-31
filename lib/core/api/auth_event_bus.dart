import 'dart:async';

/// Global event bus for auth state changes (e.g., forced logout).
class AuthEventBus {
  AuthEventBus._();
  static final instance = AuthEventBus._();

  final _controller = StreamController<AuthEvent>.broadcast();

  Stream<AuthEvent> get stream => _controller.stream;

  void emit(AuthEvent event) => _controller.add(event);
}

enum AuthEvent { forceLogout }
