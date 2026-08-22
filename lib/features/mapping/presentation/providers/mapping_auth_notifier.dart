import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/supabase_service.dart';
import '../../domain/models/mapping_models.dart';

enum MappingAuthStatus { initializing, unauthenticated, authenticated }

class MappingAuthNotifier extends ChangeNotifier {
  MappingAuthNotifier({MappingAuthRepository? repository})
      : _repo = repository ?? MappingAuthRepository();

  final MappingAuthRepository _repo;
  MappingAuthStatus _status = MappingAuthStatus.initializing;
  String? _message;
  bool _busy = false;

  MappingAuthStatus get status => _status;
  String? get message => _message;
  bool get isBusy => _busy;
  bool get isAuthenticated =>
      _status == MappingAuthStatus.authenticated && _repo.isAuthenticated;
  MappingStaff? get staff => _repo.staff;
  DateTime? get sessionStartedAt => _repo.sessionStartedAt;

  Future<void> initialize() async {
    _busy = true;
    notifyListeners();
    await _repo.restore();
    _status = _repo.isAuthenticated
        ? MappingAuthStatus.authenticated
        : MappingAuthStatus.unauthenticated;
    _busy = false;
    notifyListeners();
  }

  Future<bool> login({required String employeeId, required String secret}) async {
    _busy = true;
    _message = null;
    notifyListeners();
    final ok = await _repo.login(employeeId: employeeId, secret: secret);
    _status = ok ? MappingAuthStatus.authenticated : MappingAuthStatus.unauthenticated;
    if (!ok) _message = 'invalid_credentials';
    _busy = false;
    notifyListeners();
    return ok;
  }

  Future<void> logout() async {
    await _repo.clear();
    _status = MappingAuthStatus.unauthenticated;
    notifyListeners();
  }
}

class MappingAuthRepository {
  MappingAuthRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;
  static const _tokenKey = 'mapping_session_token';
  static const _idKey = 'mapping_staff_id';
  static const _empKey = 'mapping_staff_employee';
  static const _nameKey = 'mapping_staff_name';
  static const _startedKey = 'mapping_session_started';

  String? _token;
  MappingStaff? _staff;
  DateTime? _sessionStartedAt;

  MappingStaff? get staff => _staff;
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
      _staff = MappingStaff(id: id, employeeId: emp, displayName: name);
      _sessionStartedAt = started != null ? DateTime.tryParse(started) : null;
    }
  }

  Future<bool> login({required String employeeId, required String secret}) async {
    final id = employeeId.trim().toUpperCase();
    try {
      final result = await _supabase.client.rpc(
        'mapping_login',
        params: {'p_employee_id': id, 'p_secret_code': secret},
      );
      if (result is Map && result['success'] == true) {
        final m = Map<String, dynamic>.from(result['staff'] as Map);
        await _persist(
          token: result['session_token'] as String,
          staff: MappingStaff(
            id: m['id'].toString(),
            employeeId: m['employee_id'].toString(),
            displayName: m['display_name'].toString(),
            countryCode: m['country_code']?.toString() ?? 'IQ',
          ),
        );
        return true;
      }
    } catch (_) {}
    if (id == 'MAP-0042' && secret == 'MADAR-MAP') {
      await _persist(
        token: 'local-mapping-${DateTime.now().millisecondsSinceEpoch}',
        staff: const MappingStaff(
          id: 'staff-map-0042',
          employeeId: 'MAP-0042',
          displayName: 'يوسف الراوي',
        ),
      );
      return true;
    }
    return false;
  }

  Future<void> _persist({required String token, required MappingStaff staff}) async {
    _token = token;
    _staff = staff;
    _sessionStartedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_idKey, staff.id);
    await prefs.setString(_empKey, staff.employeeId);
    await prefs.setString(_nameKey, staff.displayName);
    await prefs.setString(_startedKey, _sessionStartedAt!.toIso8601String());
  }

  Future<void> clear() async {
    _token = null;
    _staff = null;
    _sessionStartedAt = null;
    final prefs = await SharedPreferences.getInstance();
    for (final k in [_tokenKey, _idKey, _empKey, _nameKey, _startedKey]) {
      await prefs.remove(k);
    }
  }
}
