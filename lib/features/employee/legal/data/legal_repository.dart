import '../../../../services/supabase_service.dart';
import '../../core/data/employee_repository.dart';
import '../../core/domain/employee_permissions.dart';

class LegalRepository {
  LegalRepository(this._employeeRepo, {SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final EmployeeRepository _employeeRepo;
  final SupabaseService _supabase;

  String? get _token => _employeeRepo.sessionToken;

  Future<List<Map<String, dynamic>>> listContracts({String? status}) async {
    if (!_employeeRepo.can(EmployeePermission.contractCreate) &&
        !_employeeRepo.can(EmployeePermission.contractEdit)) {
      return [];
    }
    try {
      var q = _supabase.client.from('legal_contracts').select();
      if (status != null) q = q.eq('status', status);
      final rows = await q.order('updated_at', ascending: false).limit(60);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listTemplates() async {
    try {
      final rows = await _supabase.client
          .from('legal_contract_templates')
          .select()
          .eq('active', true)
          .order('code');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<String?> createContractFromTemplate({
    required String templateId,
    String? transactionId,
    Map<String, dynamic>? variables,
  }) async {
    if (!_employeeRepo.can(EmployeePermission.contractCreate)) return null;
    try {
      final templates = await listTemplates();
      final tpl = templates.cast<Map<String, dynamic>?>().firstWhere(
            (t) => t?['id']?.toString() == templateId,
            orElse: () => null,
          );
      if (tpl == null) return null;
      var body = tpl['body_template']?.toString() ?? '';
      final vars = {
        'date': DateTime.now().toIso8601String().split('T').first,
        ...?variables,
      };
      vars.forEach((k, v) {
        body = body.replaceAll('{{$k}}', v?.toString() ?? '');
      });
      final row = await _supabase.client
          .from('legal_contracts')
          .insert({
            'template_id': templateId,
            'transaction_id': transactionId,
            'body_text': body,
            'variables': vars,
            'created_by_employee_id': _employeeRepo.currentEmployee?.id,
            'status': 'draft',
            'version_label': 'Draft',
          })
          .select()
          .single();
      return row['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveDraft(String contractId, String body, {String? label}) async {
    if (_token == null) return false;
    try {
      final result = await _supabase.client.rpc(
        'contract_save_draft',
        params: {
          'p_session_token': _token,
          'p_contract_id': contractId,
          'p_body_text': body,
          'p_version_label': label,
        },
      );
      return result is Map && result['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listTransactionSteps(
    String transactionId,
  ) async {
    try {
      final rows = await _supabase.client
          .from('legal_transaction_steps')
          .select()
          .eq('transaction_id', transactionId)
          .order('step_order');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listOwnershipTransfers() async {
    if (!_employeeRepo.can(EmployeePermission.legalOwnershipTransfer) &&
        !_employeeRepo.can(EmployeePermission.legalTransactionManage)) {
      return [];
    }
    try {
      final rows = await _supabase.client
          .from('legal_ownership_transfers')
          .select()
          .order('created_at', ascending: false)
          .limit(40);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listManagedTransactions() async {
    if (!_employeeRepo.can(EmployeePermission.legalTransactionManage) &&
        !_employeeRepo.can(EmployeePermission.transactionRead)) {
      return [];
    }
    try {
      final rows = await _supabase.client
          .from('transactions')
          .select('id, transaction_number, status, created_at')
          .order('created_at', ascending: false)
          .limit(40);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }
}
