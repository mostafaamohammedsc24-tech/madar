import 'package:flutter/material.dart';

import '../presentation/providers/user_auth_notifier.dart';

/// Bridges [UserAuthNotifier] to GoRouter refreshListenable.
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(UserAuthNotifier notifier) : _notifier = notifier {
    _notifier.addListener(notifyListeners);
  }

  final UserAuthNotifier _notifier;

  UserAuthNotifier get notifier => _notifier;

  @override
  void dispose() {
    _notifier.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Global user auth instances wired into routing.
final userAuthNotifier = UserAuthNotifier();
final authRouterRefresh = AuthRouterRefresh(userAuthNotifier);
