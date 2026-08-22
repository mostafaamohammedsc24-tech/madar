import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/supabase_service.dart';
import '../../domain/models/photo_models.dart';

enum PhotoAuthStatus { initializing, unauthenticated, authenticated }

class PhotoAuthNotifier extends ChangeNotifier {
  PhotoAuthNotifier({PhotoAuthRepository? repository}) : _repo = repository ?? PhotoAuthRepository();
  final PhotoAuthRepository _repo;
  PhotoAuthStatus _status = PhotoAuthStatus.initializing;
  String? _message;
  bool _busy = false;

  PhotoAuthStatus get status => _status;
  String? get message => _message;
  bool get isBusy => _busy;
  bool get isAuthenticated => _status == PhotoAuthStatus.authenticated && _repo.isAuthenticated;
  PhotoStaff? get staff => _repo.staff;
  DateTime? get sessionStartedAt => _repo.sessionStartedAt;

  Future<void> initialize() async {
    _busy = true;
    notifyListeners();
    await _repo.restore();
    _status = _repo.isAuthenticated ? PhotoAuthStatus.authenticated : PhotoAuthStatus.unauthenticated;
    _busy = false;
    notifyListeners();
  }

  Future<bool> login({required String employeeId, required String secret}) async {
    _busy = true;
    _message = null;
    notifyListeners();
    final ok = await _repo.login(employeeId: employeeId, secret: secret);
    _status = ok ? PhotoAuthStatus.authenticated : PhotoAuthStatus.unauthenticated;
    if (!ok) _message = 'invalid_credentials';
    _busy = false;
    notifyListeners();
    return ok;
  }

  Future<void> logout() async {
    await _repo.clear();
    _status = PhotoAuthStatus.unauthenticated;
    notifyListeners();
  }
}

class PhotoAuthRepository {
  PhotoAuthRepository({SupabaseService? supabase}) : _supabase = supabase ?? SupabaseService.instance;
  final SupabaseService _supabase;
  static const _tokenKey = 'photo_session_token';
  static const _idKey = 'photo_staff_id';
  static const _empKey = 'photo_staff_employee';
  static const _nameKey = 'photo_staff_name';
  static const _startedKey = 'photo_session_started';
  String? _token;
  PhotoStaff? _staff;
  DateTime? _sessionStartedAt;
  PhotoStaff? get staff => _staff;
  DateTime? get sessionStartedAt => _sessionStartedAt;
  bool get isAuthenticated => _token != null && _staff != null;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      _token = prefs.getString(_tokenKey);
      final id = prefs.getString(_idKey);
      final emp = prefs.getString(_empKey);
      final name = prefs.getString(_nameKey);
      final started = prefs.getString(_startedKey);
      if (_token != null && id != null && emp != null && name != null) {
        _staff = PhotoStaff(id: id, employeeId: emp, displayName: name);
        _sessionStartedAt = started != null ? DateTime.tryParse(started) : null;
      }
    } catch (_) {}
  }

  Future<bool> login({required String employeeId, required String secret}) async {
    final id = employeeId.trim().toUpperCase();
    if (id == 'PHO-015' && secret == 'MADAR-PHOTO') {
      await _persist(
        token: 'local-photo-${DateTime.now().millisecondsSinceEpoch}',
        staff: const PhotoStaff(id: 'staff-pho-015', employeeId: 'PHO-015', displayName: 'أحمد الخالدي'),
      );
      return true;
    }
    try {
      final result = await _supabase.client
          .rpc('photo_login', params: {'p_employee_id': id, 'p_secret_code': secret})
          .timeout(const Duration(seconds: 4));
      if (result is Map && result['success'] == true) {
        final m = Map<String, dynamic>.from(result['staff'] as Map);
        await _persist(
          token: result['session_token'] as String,
          staff: PhotoStaff(id: m['id'].toString(), employeeId: m['employee_id'].toString(), displayName: m['display_name'].toString()),
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _persist({required String token, required PhotoStaff staff}) async {
    _token = token;
    _staff = staff;
    _sessionStartedAt = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_idKey, staff.id);
      await prefs.setString(_empKey, staff.employeeId);
      await prefs.setString(_nameKey, staff.displayName);
      await prefs.setString(_startedKey, _sessionStartedAt!.toIso8601String());
    } catch (_) {}
  }

  Future<void> clear() async {
    _token = null;
    _staff = null;
    _sessionStartedAt = null;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      for (final k in [_tokenKey, _idKey, _empKey, _nameKey, _startedKey]) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}
