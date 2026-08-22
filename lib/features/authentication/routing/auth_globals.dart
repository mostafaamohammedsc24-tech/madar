import 'package:flutter/material.dart';

import '../presentation/providers/user_auth_notifier.dart';
import '../../office/presentation/providers/office_auth_notifier.dart';
import '../../legal/presentation/providers/legal_auth_notifier.dart';

/// Bridges auth notifiers to GoRouter refreshListenable.
class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(UserAuthNotifier notifier) : _notifier = notifier {
    _notifier.addListener(notifyListeners);
  }

  final UserAuthNotifier _notifier;
  OfficeAuthNotifier? _office;
  LegalAuthNotifier? _legal;

  UserAuthNotifier get notifier => _notifier;

  void attachOffice(OfficeAuthNotifier office) {
    if (_office == office) return;
    _office?.removeListener(notifyListeners);
    _office = office;
    _office!.addListener(notifyListeners);
  }

  void attachLegal(LegalAuthNotifier legal) {
    if (_legal == legal) return;
    _legal?.removeListener(notifyListeners);
    _legal = legal;
    _legal!.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _notifier.removeListener(notifyListeners);
    _office?.removeListener(notifyListeners);
    _legal?.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Global user auth instances wired into routing.
final userAuthNotifier = UserAuthNotifier();
final authRouterRefresh = AuthRouterRefresh(userAuthNotifier);
