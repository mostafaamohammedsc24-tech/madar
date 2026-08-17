import 'package:flutter/foundation.dart';

import '../../data/employee_repository.dart';
import '../../domain/employee_models.dart';

enum EmployeeAuthStatus { initializing, unauthenticated, authenticated }

class EmployeeAuthNotifier extends ChangeNotifier {
  EmployeeAuthNotifier({EmployeeRepository? repository})
      : _repo = repository ?? EmployeeRepository();

  final EmployeeRepository _repo;

  EmployeeAuthStatus _status = EmployeeAuthStatus.unauthenticated;
  String? _message;
  bool _busy = false;
  bool _sessionChecked = false;

  EmployeeAuthStatus get status => _status;
  String? get message => _message;
  bool get isBusy => _busy;
  bool get isAuthenticated =>
      _status == EmployeeAuthStatus.authenticated && _repo.isAuthenticated;
  EmployeeAccount? get employee => _repo.currentEmployee;
  EmployeeRepository get repository => _repo;

  bool can(String permission) => _repo.can(permission);

  /// Restores persisted session once per app launch (lazy — not at startup).
  Future<void> ensureInitialized() async {
    if (_sessionChecked) return;
    _sessionChecked = true;
    await initialize();
  }

  Future<void> initialize() async {
    _busy = true;
    notifyListeners();
    await _repo.restoreSession();
    _status = _repo.isAuthenticated
        ? EmployeeAuthStatus.authenticated
        : EmployeeAuthStatus.unauthenticated;
    _busy = false;
    notifyListeners();
  }

  Future<bool> login({
    required String employeeCode,
    required String secretCode,
  }) async {
    _busy = true;
    _message = null;
    notifyListeners();
    final result = await _repo.login(
      employeeCode: employeeCode,
      secretCode: secretCode,
    );
    if (result.success && result.session != null) {
      _status = EmployeeAuthStatus.authenticated;
      _busy = false;
      notifyListeners();
      return true;
    }
    _status = EmployeeAuthStatus.unauthenticated;
    _message = result.message ?? 'invalid_credentials';
    _busy = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _repo.clearSession();
    _status = EmployeeAuthStatus.unauthenticated;
    _message = null;
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }
}
