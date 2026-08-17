import '../../../../services/supabase_service.dart';
import '../../core/data/employee_repository.dart';
import '../../core/domain/employee_permissions.dart';

class OpsRepository {
  OpsRepository(this._employeeRepo, {SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final EmployeeRepository _employeeRepo;
  final SupabaseService _supabase;

  String? get _token => _employeeRepo.sessionToken;

  // ── Closing ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listClosingCases() async {
    if (!_employeeRepo.can(EmployeePermission.closingManage) &&
        !_employeeRepo.can(EmployeePermission.salesHandoff)) {
      return [];
    }
    try {
      final rows = await _supabase.client
          .from('closing_cases')
          .select()
          .order('updated_at', ascending: false)
          .limit(60);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<({bool success, String? code, String? message})> createClosingCase({
    required String buyerName,
    required String sellerName,
    required String propertyRef,
    String? priceText,
    String? leadId,
  }) async {
    if (_token == null) {
      return (success: false, code: null, message: 'unauthorized');
    }
    try {
      final result = await _supabase.client.rpc(
        'closing_create_case',
        params: {
          'p_session_token': _token,
          'p_buyer_name': buyerName,
          'p_seller_name': sellerName,
          'p_property_ref': propertyRef,
          'p_price_text': priceText,
          'p_lead_id': leadId,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          code: null,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
        );
      }
      return (
        success: true,
        code: result['case_code']?.toString(),
        message: null,
      );
    } catch (_) {
      return (success: false, code: null, message: 'unavailable');
    }
  }

  Future<bool> updateClosingStatus(String caseId, String status) async {
    try {
      await _supabase.client.from('closing_cases').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', caseId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Support ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listTickets({String? status}) async {
    if (!_employeeRepo.can(EmployeePermission.supportTickets)) return [];
    try {
      var q = _supabase.client.from('support_tickets').select();
      if (status != null) q = q.eq('status', status);
      final rows = await q.order('updated_at', ascending: false).limit(80);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<({bool success, String? code, String? message})> createTicket({
    required String subject,
    String priority = 'normal',
  }) async {
    if (_token == null) {
      return (success: false, code: null, message: 'unauthorized');
    }
    try {
      final result = await _supabase.client.rpc(
        'support_create_ticket',
        params: {
          'p_session_token': _token,
          'p_subject': subject,
          'p_priority': priority,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          code: null,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
        );
      }
      return (
        success: true,
        code: result['ticket_code']?.toString(),
        message: null,
      );
    } catch (_) {
      return (success: false, code: null, message: 'unavailable');
    }
  }

  Future<bool> updateTicketStatus(String id, String status) async {
    try {
      await _supabase.client.from('support_tickets').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Quality ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listQualityQueue() async {
    if (!_employeeRepo.can(EmployeePermission.qualityReview) &&
        !_employeeRepo.can(EmployeePermission.publishingReview)) {
      return [];
    }
    try {
      final rows = await _supabase.client
          .from('property_assets')
          .select()
          .inFilter('pipeline_status', [
            'data_review',
            'media_review',
            'engineering_review',
            'ready_for_publication',
          ])
          .order('updated_at', ascending: false)
          .limit(60);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<bool> submitQualityReview({
    required String propertyAssetId,
    required String decision,
    String? notes,
  }) async {
    if (_token == null) return false;
    try {
      final result = await _supabase.client.rpc(
        'quality_submit_review',
        params: {
          'p_session_token': _token,
          'p_property_asset_id': propertyAssetId,
          'p_decision': decision,
          'p_checklist': {
            'data': true,
            'photos': true,
            'three_d': true,
            'floor_plan': true,
            'location': true,
            'description': true,
            'tags': true,
          },
          'p_notes': notes,
        },
      );
      return result is Map && result['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── Compliance ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listComplianceCases() async {
    if (!_employeeRepo.can(EmployeePermission.complianceReview)) return [];
    try {
      final rows = await _supabase.client
          .from('compliance_cases')
          .select()
          .order('updated_at', ascending: false)
          .limit(60);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<({bool success, String? code, String? message})> createComplianceCase({
    required String subject,
    String risk = 'medium',
    String? notes,
  }) async {
    if (_token == null) {
      return (success: false, code: null, message: 'unauthorized');
    }
    try {
      final result = await _supabase.client.rpc(
        'compliance_create_case',
        params: {
          'p_session_token': _token,
          'p_subject': subject,
          'p_risk_level': risk,
          'p_notes': notes,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          code: null,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
        );
      }
      return (
        success: true,
        code: result['case_code']?.toString(),
        message: null,
      );
    } catch (_) {
      return (success: false, code: null, message: 'unavailable');
    }
  }

  // ── System admin / executive ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> loadSystemConfig(String key) async {
    if (!_employeeRepo.can(EmployeePermission.systemConfig) &&
        !_employeeRepo.can(EmployeePermission.executiveView)) {
      return null;
    }
    try {
      final row = await _supabase.client
          .from('system_config')
          .select()
          .eq('key', key)
          .maybeSingle();
      return row == null ? null : Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setTwilioEnabled({
    required bool enabled,
    String? serviceSid,
  }) async {
    if (_token == null) return false;
    try {
      final result = await _supabase.client.rpc(
        'system_set_twilio_enabled',
        params: {
          'p_session_token': _token,
          'p_enabled': enabled,
          'p_service_sid': serviceSid,
        },
      );
      return result is Map && result['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, int>> executiveSnapshot() async {
    if (!_employeeRepo.can(EmployeePermission.executiveView) &&
        !_employeeRepo.can(EmployeePermission.reportsView)) {
      return {};
    }
    final out = <String, int>{};
    try {
      final txs = await _supabase.client
          .from('transactions')
          .select('id')
          .limit(500);
      out['transactions'] = List.from(txs).length;
    } catch (_) {
      out['transactions'] = 0;
    }
    try {
      final props = await _supabase.client
          .from('property_assets')
          .select('id')
          .limit(500);
      out['properties'] = List.from(props).length;
    } catch (_) {
      out['properties'] = 0;
    }
    try {
      final offices = await _supabase.client.from('offices').select('id').limit(200);
      out['offices'] = List.from(offices).length;
    } catch (_) {
      out['offices'] = 0;
    }
    try {
      final emps = await _supabase.client
          .from('employees')
          .select('id')
          .eq('employment_status', 'active')
          .limit(500);
      out['employees'] = List.from(emps).length;
    } catch (_) {
      out['employees'] = 0;
    }
    return out;
  }
}
