import '../../../../services/supabase_service.dart';
import '../../core/data/employee_repository.dart';
import '../../core/domain/employee_permissions.dart';

class HrRepository {
  HrRepository(this._employeeRepo, {SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final EmployeeRepository _employeeRepo;
  final SupabaseService _supabase;

  String? get _token => _employeeRepo.sessionToken;

  Future<List<Map<String, dynamic>>> listEmployees({String? status}) async {
    if (!_employeeRepo.can(EmployeePermission.hrView) &&
        !_employeeRepo.can(EmployeePermission.employeeEdit)) {
      return [];
    }
    try {
      var q = _supabase.client.from('employees').select(
            'id, employee_code, full_name, job_title, employment_status, '
            'phone, email, department_id, role_id, branch_code, joining_date',
          );
      if (status != null) q = q.eq('employment_status', status);
      final rows = await q.order('created_at', ascending: false).limit(120);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listDepartments() async {
    try {
      final rows = await _supabase.client
          .from('employee_departments')
          .select()
          .order('code');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listRoles() async {
    try {
      final rows = await _supabase.client
          .from('employee_roles')
          .select('id, code, name_en, name_ar, department_id')
          .order('code');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<({bool success, String? message, String? code, String? tempSecret})>
      createEmployee({
    required String fullName,
    required String departmentCode,
    required String roleCode,
    String? phone,
    String? email,
    String? jobTitle,
    String? branchCode,
    String? employmentType,
  }) async {
    if (_token == null) {
      return (
        success: false,
        message: 'unauthorized',
        code: null,
        tempSecret: null,
      );
    }
    try {
      final result = await _supabase.client.rpc(
        'hr_create_employee',
        params: {
          'p_session_token': _token,
          'p_full_name': fullName,
          'p_department_code': departmentCode,
          'p_role_code': roleCode,
          'p_phone': phone,
          'p_email': email,
          'p_job_title': jobTitle,
          'p_branch_code': branchCode,
          'p_employment_type': employmentType ?? 'full_time',
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
          code: null,
          tempSecret: null,
        );
      }
      return (
        success: true,
        message: null,
        code: result['employee_code']?.toString(),
        tempSecret: result['temporary_password']?.toString(),
      );
    } catch (_) {
      return (
        success: false,
        message: 'unavailable',
        code: null,
        tempSecret: null,
      );
    }
  }

  Future<Map<String, int>> directoryCounts() async {
    final all = await listEmployees();
    return {
      'total': all.length,
      'active': all.where((e) => e['employment_status'] == 'active').length,
      'suspended':
          all.where((e) => e['employment_status'] == 'suspended').length,
      'pending': all.where((e) => e['employment_status'] == 'probation').length,
    };
  }
}
