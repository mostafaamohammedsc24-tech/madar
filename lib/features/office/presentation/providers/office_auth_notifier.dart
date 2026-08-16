import 'package:flutter/foundation.dart';

import '../../data/repositories/office_repository.dart';
import '../../domain/models/office_models.dart';

enum OfficeAuthStatus { initializing, unauthenticated, authenticated }

class OfficeAuthNotifier extends ChangeNotifier {
  OfficeAuthNotifier({OfficeRepository? repository})
      : _repo = repository ?? OfficeRepository();

  final OfficeRepository _repo;

  OfficeAuthStatus _status = OfficeAuthStatus.initializing;
  String? _message;
  bool _busy = false;

  OfficeAuthStatus get status => _status;
  String? get message => _message;
  bool get isBusy => _busy;
  bool get isAuthenticated =>
      _status == OfficeAuthStatus.authenticated && _repo.isAuthenticated;
  OfficeAccount? get office => _repo.currentOffice;
  OfficeRepository get repository => _repo;

  Future<void> initialize() async {
    _busy = true;
    notifyListeners();
    await _repo.restoreSession();
    _status = _repo.isAuthenticated
        ? OfficeAuthStatus.authenticated
        : OfficeAuthStatus.unauthenticated;
    _busy = false;
    notifyListeners();
  }

  Future<bool> login({
    required String officeCode,
    required String secretCode,
  }) async {
    _busy = true;
    _message = null;
    notifyListeners();
    final result = await _repo.login(
      officeCode: officeCode,
      secretCode: secretCode,
    );
    if (result.success && result.session != null) {
      _status = OfficeAuthStatus.authenticated;
      _busy = false;
      notifyListeners();
      return true;
    }
    _status = OfficeAuthStatus.unauthenticated;
    _message = result.message ?? 'invalid_credentials';
    _busy = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _repo.clearSession();
    _status = OfficeAuthStatus.unauthenticated;
    _message = null;
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }
}
