import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/supabase_service.dart';
import '../../domain/models/legal_models.dart';

class LegalAuthNotifier extends ChangeNotifier {
  LegalAuthNotifier({LegalAuthRepository? repository})
      : _repo = repository ?? LegalAuthRepository();

  final LegalAuthRepository _repo;
  LegalAuthStatus _status = LegalAuthStatus.initializing;
  String? _message;
  bool _busy = false;

  LegalAuthStatus get status => _status;
  String? get message => _message;
  bool get isBusy => _busy;
  bool get isAuthenticated =>
      _status == LegalAuthStatus.authenticated && _repo.isAuthenticated;
  LegalStaff? get staff => _repo.staff;
  DateTime? get sessionStartedAt => _repo.sessionStartedAt;

  Future<void> initialize() async {
    _busy = true;
    notifyListeners();
    await _repo.restore();
    _status = _repo.isAuthenticated
        ? LegalAuthStatus.authenticated
        : LegalAuthStatus.unauthenticated;
    _busy = false;
    notifyListeners();
  }

  Future<bool> login({required String employeeId, required String secret}) async {
    _busy = true;
    _message = null;
    notifyListeners();
    final result = await _repo.login(employeeId: employeeId, secret: secret);
    _status = result
        ? LegalAuthStatus.authenticated
        : LegalAuthStatus.unauthenticated;
    if (!result) _message = 'invalid_credentials';
    _busy = false;
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    await _repo.clear();
    _status = LegalAuthStatus.unauthenticated;
    notifyListeners();
  }
}

enum LegalAuthStatus { initializing, unauthenticated, authenticated }

class LegalAuthRepository {
  LegalAuthRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;
  static const _tokenKey = 'legal_session_token';
  static const _idKey = 'legal_staff_id';
  static const _empKey = 'legal_staff_employee';
  static const _nameKey = 'legal_staff_name';
  static const _roleKey = 'legal_staff_role';
  static const _startedKey = 'legal_session_started';

  String? _token;
  LegalStaff? _staff;
  DateTime? _sessionStartedAt;

  String? get token => _token;
  LegalStaff? get staff => _staff;
  DateTime? get sessionStartedAt => _sessionStartedAt;
  bool get isAuthenticated => _token != null && _staff != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final id = prefs.getString(_idKey);
    final emp = prefs.getString(_empKey);
    final name = prefs.getString(_nameKey);
    final started = prefs.getString(_startedKey);
    if (_token != null && id != null && emp != null && name != null) {
      _staff = LegalStaff(
        id: id,
        employeeId: emp,
        displayName: name,
        role: prefs.getString(_roleKey) ?? 'contract_lawyer',
      );
      _sessionStartedAt = started != null ? DateTime.tryParse(started) : null;
    }
  }

  Future<bool> login({
    required String employeeId,
    required String secret,
  }) async {
    final id = employeeId.trim().toUpperCase();
    try {
      final result = await _supabase.client.rpc(
        'legal_login',
        params: {'p_employee_id': id, 'p_secret_code': secret},
      );
      if (result is Map && result['success'] == true) {
        final staffMap = Map<String, dynamic>.from(result['staff'] as Map);
        await _persist(
          token: result['session_token'] as String,
          staff: LegalStaff(
            id: staffMap['id'].toString(),
            employeeId: staffMap['employee_id'].toString(),
            displayName: staffMap['display_name'].toString(),
            role: staffMap['role']?.toString() ?? 'contract_lawyer',
            countryCode: staffMap['country_code']?.toString() ?? 'IQ',
          ),
        );
        return true;
      }
    } catch (_) {
      // Offline / no backend: local legal-ops credentials for assigned workspace.
    }

    if (_localCredentialOk(id, secret)) {
      await _persist(
        token: 'local-${DateTime.now().millisecondsSinceEpoch}',
        staff: const LegalStaff(
          id: 'staff-law-0042',
          employeeId: 'LAW-0042',
          displayName: 'سارة العبيدي',
          role: 'contract_lawyer',
          countryCode: 'IQ',
        ),
      );
      return true;
    }
    return false;
  }

  bool _localCredentialOk(String id, String secret) {
    return id == 'LAW-0042' && secret == 'MADAR-LEGAL';
  }

  Future<void> _persist({
    required String token,
    required LegalStaff staff,
  }) async {
    _token = token;
    _staff = staff;
    _sessionStartedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_idKey, staff.id);
    await prefs.setString(_empKey, staff.employeeId);
    await prefs.setString(_nameKey, staff.displayName);
    await prefs.setString(_roleKey, staff.role);
    await prefs.setString(_startedKey, _sessionStartedAt!.toIso8601String());
  }

  Future<void> clear() async {
    if (_token != null) {
      try {
        await _supabase.client.rpc(
          'legal_logout',
          params: {'p_session_token': _token},
        );
      } catch (_) {}
    }
    _token = null;
    _staff = null;
    _sessionStartedAt = null;
    final prefs = await SharedPreferences.getInstance();
    for (final k in [_tokenKey, _idKey, _empKey, _nameKey, _roleKey, _startedKey]) {
      await prefs.remove(k);
    }
  }
}
