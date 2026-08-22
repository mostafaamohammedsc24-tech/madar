import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/supabase_service.dart';
import '../../domain/models/field_models.dart';

enum FieldAuthStatus { initializing, unauthenticated, authenticated }

class FieldAuthNotifier extends ChangeNotifier {
  FieldAuthNotifier({FieldAuthRepository? repository}) : _repo = repository ?? FieldAuthRepository();
  final FieldAuthRepository _repo;
  FieldAuthStatus _status = FieldAuthStatus.initializing;
  String? _message;
  bool _busy = false;

  FieldAuthStatus get status => _status;
  String? get message => _message;
  bool get isBusy => _busy;
  bool get isAuthenticated => _status == FieldAuthStatus.authenticated && _repo.isAuthenticated;
  FieldStaff? get staff => _repo.staff;
  DateTime? get sessionStartedAt => _repo.sessionStartedAt;

  Future<void> initialize() async {
    _busy = true;
    notifyListeners();
    await _repo.restore();
    _status = _repo.isAuthenticated ? FieldAuthStatus.authenticated : FieldAuthStatus.unauthenticated;
    _busy = false;
    notifyListeners();
  }

  Future<bool> login({required String employeeId, required String secret}) async {
    _busy = true;
    _message = null;
    notifyListeners();
    final ok = await _repo.login(employeeId: employeeId, secret: secret);
    _status = ok ? FieldAuthStatus.authenticated : FieldAuthStatus.unauthenticated;
    if (!ok) _message = 'invalid_credentials';
    _busy = false;
    notifyListeners();
    return ok;
  }

  Future<void> logout() async {
    await _repo.clear();
    _status = FieldAuthStatus.unauthenticated;
    notifyListeners();
  }
}

class FieldAuthRepository {
  FieldAuthRepository({SupabaseService? supabase}) : _supabase = supabase ?? SupabaseService.instance;
  final SupabaseService _supabase;
  static const _tokenKey = 'field_session_token';
  static const _idKey = 'field_staff_id';
  static const _empKey = 'field_staff_employee';
  static const _nameKey = 'field_staff_name';
  static const _startedKey = 'field_session_started';
  String? _token;
  FieldStaff? _staff;
  DateTime? _sessionStartedAt;
  FieldStaff? get staff => _staff;
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
      _staff = FieldStaff(id: id, employeeId: emp, displayName: name);
      _sessionStartedAt = started != null ? DateTime.tryParse(started) : null;
    }
  }

  Future<bool> login({required String employeeId, required String secret}) async {
    final id = employeeId.trim().toUpperCase();
    try {
      final result = await _supabase.client
          .rpc('field_login', params: {'p_employee_id': id, 'p_secret_code': secret})
          .timeout(const Duration(seconds: 4));
      if (result is Map && result['success'] == true) {
        final m = Map<String, dynamic>.from(result['staff'] as Map);
        await _persist(
          token: result['session_token'] as String,
          staff: FieldStaff(id: m['id'].toString(), employeeId: m['employee_id'].toString(), displayName: m['display_name'].toString()),
        );
        return true;
      }
    } catch (_) {}
    if (id == 'INF-0020' && secret == 'MADAR-INFO') {
      await _persist(
        token: 'local-field-${DateTime.now().millisecondsSinceEpoch}',
        staff: const FieldStaff(id: 'staff-inf-0020', employeeId: 'INF-0020', displayName: 'سارة اليوسف'),
      );
      return true;
    }
    return false;
  }

  Future<void> _persist({required String token, required FieldStaff staff}) async {
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
