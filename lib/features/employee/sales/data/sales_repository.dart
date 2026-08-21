import '../../../../services/supabase_service.dart';
import '../../core/data/employee_repository.dart';
import '../../core/domain/employee_permissions.dart';

class SalesRepository {
  SalesRepository(this._employeeRepo, {SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final EmployeeRepository _employeeRepo;
  final SupabaseService _supabase;

  String? get _token => _employeeRepo.sessionToken;
  String? get _employeeId => _employeeRepo.currentEmployee?.id;

  Future<List<Map<String, dynamic>>> listLeads({String? status}) async {
    try {
      var q = _supabase.client.from('sales_leads').select();
      if (_employeeId != null) {
        q = q.eq('assigned_employee_id', _employeeId!);
      }
      if (status != null) q = q.eq('status', status);
      final rows = await q.order('updated_at', ascending: false).limit(80);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listFollowUpsToday() async {
    if (_employeeId == null) return [];
    try {
      final start = DateTime.now();
      final dayStart = DateTime(start.year, start.month, start.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final rows = await _supabase.client
          .from('sales_follow_ups')
          .select('*, sales_leads(*)')
          .eq('employee_id', _employeeId!)
          .gte('due_at', dayStart.toIso8601String())
          .lt('due_at', dayEnd.toIso8601String())
          .order('due_at');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<({bool success, String? message, String? leadId, String? leadCode})>
      createLead({
    required String fullName,
    required String phone,
    required String leadType,
    String? budget,
    String? area,
    String? source,
    String? notes,
  }) async {
    if (_token == null) {
      return (success: false, message: 'unauthorized', leadId: null, leadCode: null);
    }
    if (!_employeeRepo.can(EmployeePermission.salesLeadsEdit)) {
      return (success: false, message: 'forbidden', leadId: null, leadCode: null);
    }
    try {
      final result = await _supabase.client.rpc(
        'sales_create_lead',
        params: {
          'p_session_token': _token,
          'p_full_name': fullName,
          'p_phone': phone,
          'p_lead_type': leadType,
          'p_budget_text': budget,
          'p_preferred_area': area,
          'p_source': source,
          'p_notes': notes,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
          leadId: null,
          leadCode: null,
        );
      }
      return (
        success: true,
        message: null,
        leadId: result['lead_id']?.toString(),
        leadCode: result['lead_code']?.toString(),
      );
    } catch (_) {
      return (success: false, message: 'unavailable', leadId: null, leadCode: null);
    }
  }

  Future<bool> updateLeadStatus(String leadId, String status) async {
    if (!_employeeRepo.can(EmployeePermission.salesLeadsEdit)) return false;
    try {
      await _supabase.client.from('sales_leads').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', leadId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, int>> homeCounts() async {
    final leads = await listLeads();
    final followUps = await listFollowUpsToday();
    final ready = leads.where((l) => l['status'] == 'ready_for_closing').length;
    final active = leads
        .where((l) => !const {'lost', 'converted'}.contains(l['status']))
        .length;
    return {
      'leads': leads.length,
      'followups': followUps.length,
      'active': active,
      'deals': ready,
    };
  }
}
