import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/demo/demo_mode.dart';
import '../../../../services/app_demo_seed.dart';
import '../../../../services/supabase_service.dart';
import '../domain/employee_models.dart';
import '../domain/employee_permissions.dart';

class EmployeeRepository {
  EmployeeRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

  static const _tokenKey = 'employee_session_token';
  static const _prefPrefix = 'employee_session_';

  String? _token;
  EmployeeAccount? _employee;

  String? get sessionToken => _token;
  EmployeeAccount? get currentEmployee => _employee;
  bool get isAuthenticated =>
      _token != null && _token!.isNotEmpty && _employee != null;

  bool can(String permission) => _employee?.can(permission) ?? false;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final id = prefs.getString('${_prefPrefix}id');
    final code = prefs.getString('${_prefPrefix}code');
    final name = prefs.getString('${_prefPrefix}name');
    final deptCode = prefs.getString('${_prefPrefix}dept_code');
    final perms = prefs.getStringList('${_prefPrefix}perms') ?? [];
    if (_token != null && id != null && code != null && name != null) {
      _employee = EmployeeAccount(
        id: id,
        employeeCode: code,
        fullName: name,
        jobTitle: prefs.getString('${_prefPrefix}title'),
        countryCode: prefs.getString('${_prefPrefix}country') ?? 'IQ',
        branchCode: prefs.getString('${_prefPrefix}branch'),
        department: EmployeeDepartment(
          id: prefs.getString('${_prefPrefix}dept_id') ?? '',
          code: deptCode ?? '',
          nameEn: prefs.getString('${_prefPrefix}dept_name') ?? '',
          nameAr: prefs.getString('${_prefPrefix}dept_name_ar'),
        ),
        role: EmployeeRole(
          id: prefs.getString('${_prefPrefix}role_id') ?? '',
          code: prefs.getString('${_prefPrefix}role_code') ?? '',
          nameEn: prefs.getString('${_prefPrefix}role_name') ?? '',
        ),
        permissions: perms.toSet(),
      );
    }
  }

  Future<void> _persist(EmployeeSession session) async {
    _token = session.token;
    _employee = session.employee;
    final prefs = await SharedPreferences.getInstance();
    final e = session.employee;
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString('${_prefPrefix}id', e.id);
    await prefs.setString('${_prefPrefix}code', e.employeeCode);
    await prefs.setString('${_prefPrefix}name', e.fullName);
    if (e.jobTitle != null) {
      await prefs.setString('${_prefPrefix}title', e.jobTitle!);
    }
    await prefs.setString('${_prefPrefix}country', e.countryCode);
    if (e.branchCode != null) {
      await prefs.setString('${_prefPrefix}branch', e.branchCode!);
    }
    await prefs.setString('${_prefPrefix}dept_id', e.department.id);
    await prefs.setString('${_prefPrefix}dept_code', e.department.code);
    await prefs.setString('${_prefPrefix}dept_name', e.department.nameEn);
    if (e.department.nameAr != null) {
      await prefs.setString('${_prefPrefix}dept_name_ar', e.department.nameAr!);
    }
    await prefs.setString('${_prefPrefix}role_id', e.role.id);
    await prefs.setString('${_prefPrefix}role_code', e.role.code);
    await prefs.setString('${_prefPrefix}role_name', e.role.nameEn);
    await prefs.setStringList('${_prefPrefix}perms', e.permissions.toList());
  }

  Future<void> clearSession() async {
    if (_token != null) {
      try {
        await _supabase.client.rpc(
          'employee_logout',
          params: {'p_session_token': _token},
        );
      } catch (_) {}
    }
    _token = null;
    _employee = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    for (final k in [
      'id',
      'code',
      'name',
      'title',
      'country',
      'branch',
      'dept_id',
      'dept_code',
      'dept_name',
      'dept_name_ar',
      'role_id',
      'role_code',
      'role_name',
      'perms',
    ]) {
      await prefs.remove('$_prefPrefix$k');
    }
  }

  Future<({bool success, String? message, EmployeeSession? session})> login({
    required String employeeCode,
    required String secretCode,
  }) async {
    if (DemoMode.enabled &&
        employeeCode.trim().toUpperCase() == DemoMode.employeeCode &&
        secretCode == DemoMode.secret) {
      final session = EmployeeSession(
        token: 'demo-employee-token',
        employee: AppDemoSeed.employeeAccount(),
      );
      await _persist(session);
      return (success: true, message: null, session: session);
    }
    try {
      final result = await _supabase.client.rpc(
        'employee_login',
        params: {
          'p_employee_code': employeeCode.trim(),
          'p_secret_code': secretCode,
        },
      );
      if (result is! Map) {
        return (success: false, message: 'invalid_response', session: null);
      }
      final map = Map<String, dynamic>.from(result);
      if (map['success'] != true) {
        return (
          success: false,
          message: map['message']?.toString() ?? 'invalid_credentials',
          session: null,
        );
      }
      final employeeMap = Map<String, dynamic>.from(map['employee'] as Map);
      final perms = map['permissions'] as List? ?? [];
      final session = EmployeeSession(
        token: map['session_token'] as String,
        employee: EmployeeAccount.fromLoginMap(employeeMap, perms),
        expiresAt: map['expires_at'] != null
            ? DateTime.tryParse(map['expires_at'].toString())
            : null,
      );
      await _persist(session);
      return (success: true, message: null, session: session);
    } catch (_) {
      return (success: false, message: 'login_unavailable', session: null);
    }
  }

  // ── Shared queries ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listTransactions({
    String? financialStatus,
    String? query,
    int limit = 80,
  }) async {
    if (!can(EmployeePermission.transactionsView) &&
        !can(EmployeePermission.financialView) &&
        !can(EmployeePermission.bankVerify)) {
      return [];
    }
    try {
      final t = query?.trim();
      final queryFilter = (t != null && t.isNotEmpty)
          ? 'transaction_number.ilike.%$t%,buyer_phone.ilike.%$t%,seller_phone.ilike.%$t%'
          : null;
      final table = _supabase.client.from('transactions');
      late final dynamic built;
      if (financialStatus != null && queryFilter != null) {
        built = table
            .select()
            .eq('financial_status', financialStatus)
            .or(queryFilter);
      } else if (financialStatus != null) {
        built = table.select().eq('financial_status', financialStatus);
      } else if (queryFilter != null) {
        built = table.select().or(queryFilter);
      } else {
        built = table.select();
      }
      final rows =
          await built.order('updated_at', ascending: false).limit(limit);
      final list = List<Map<String, dynamic>>.from(rows);
      if (list.isEmpty && DemoMode.enabled) {
        return AppDemoSeed.officeTransactions();
      }
      return list;
    } catch (_) {
      return DemoMode.enabled ? AppDemoSeed.officeTransactions() : [];
    }
  }

  Future<List<Map<String, dynamic>>> listNotifications() async {
    if (DemoMode.enabled) return AppDemoSeed.employeeNotifications();
    if (_employee == null) return [];
    try {
      final rows = await _supabase.client
          .from('employee_notifications')
          .select()
          .eq('employee_id', _employee!.id)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _supabase.client.from('employee_notifications').update({
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> listAuditLogs({int limit = 50}) async {
    if (!can(EmployeePermission.auditView)) return [];
    try {
      final rows = await _supabase.client
          .from('employee_audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> globalSearch(String query) async {
    if (!can(EmployeePermission.searchGlobal) || query.trim().isEmpty) {
      return [];
    }
    final results = <Map<String, dynamic>>[];
    final t = query.trim();

    if (can(EmployeePermission.transactionsView) ||
        can(EmployeePermission.financialView) ||
        can(EmployeePermission.bankVerify)) {
      final txs = await listTransactions(query: t, limit: 10);
      for (final tx in txs) {
        results.add({
          'type': 'transaction',
          'id': tx['id'],
          'title': tx['transaction_number'] ?? tx['id'],
          'subtitle': tx['financial_status'] ?? tx['lifecycle_state'],
          'raw': tx,
        });
      }
    }

    if (can(EmployeePermission.officesView)) {
      try {
        final offices = await _supabase.client
            .from('offices')
            .select()
            .or('office_code.ilike.%$t%,name.ilike.%$t%')
            .limit(10);
        for (final o in List<Map<String, dynamic>>.from(offices)) {
          results.add({
            'type': 'office',
            'id': o['id'],
            'title': o['name'],
            'subtitle': o['office_code'],
            'raw': o,
          });
        }
      } catch (_) {}
    }

    if (can(EmployeePermission.propertyRead) ||
        can(EmployeePermission.publishingView) ||
        can(EmployeePermission.propertiesView)) {
      try {
        final assets = await _supabase.client
            .from('property_assets')
            .select('id, public_property_id, pipeline_status, city')
            .or('public_property_id.eq.$t,city.ilike.%$t%')
            .limit(10);
        for (final a in List<Map<String, dynamic>>.from(assets)) {
          results.add({
            'type': 'property',
            'id': a['id'],
            'title': '#${a['public_property_id']}',
            'subtitle': a['pipeline_status'],
            'raw': a,
          });
        }
      } catch (_) {}
    }

    if (can(EmployeePermission.hrView) ||
        can(EmployeePermission.employeeEdit)) {
      try {
        final emps = await _supabase.client
            .from('employees')
            .select('id, employee_code, full_name, employment_status')
            .or('employee_code.ilike.%$t%,full_name.ilike.%$t%,phone.ilike.%$t%')
            .limit(10);
        for (final e in List<Map<String, dynamic>>.from(emps)) {
          results.add({
            'type': 'employee',
            'id': e['id'],
            'title': e['full_name'],
            'subtitle': e['employee_code'],
            'raw': e,
          });
        }
      } catch (_) {}
    }

    if (can(EmployeePermission.salesLeadsView)) {
      try {
        final leads = await _supabase.client
            .from('sales_leads')
            .select('id, lead_code, full_name, status, phone')
            .or('lead_code.ilike.%$t%,full_name.ilike.%$t%,phone.ilike.%$t%')
            .limit(10);
        for (final l in List<Map<String, dynamic>>.from(leads)) {
          results.add({
            'type': 'lead',
            'id': l['id'],
            'title': l['full_name'],
            'subtitle': '${l['lead_code']} · ${l['status']}',
            'raw': l,
          });
        }
      } catch (_) {}
    }

    return results;
  }

  // ── Finance ───────────────────────────────────────────────────────────────

  Future<FinanceDashboardStats> financeDashboardStats({
    DateTime? from,
    DateTime? to,
  }) async {
    if (!can(EmployeePermission.financialView)) {
      return const FinanceDashboardStats(
        pendingDeposits: 0,
        confirmedDeposits: 0,
        unpaid: 0,
        overdue: 0,
        awaitingSettlement: 0,
        officeAmountsDue: 0,
        companyRevenue: 0,
        pendingTransfers: 0,
        todaysOps: 0,
      );
    }
    try {
      final rows = await _supabase.client
          .from('transactions')
          .select(
            'id, financial_status, company_fees, office_commission_amount, sale_price, updated_at, created_at',
          );
      final list = List<Map<String, dynamic>>.from(rows);
      var pending = 0, confirmed = 0, unpaid = 0, overdue = 0, settle = 0, today = 0;
      var revenue = 0.0, officeDue = 0.0;
      final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      for (final t in list) {
        final fs = (t['financial_status'] as String? ?? '').toLowerCase();
        final created = DateTime.tryParse(t['created_at']?.toString() ?? '');
        if (created != null && !created.isBefore(todayStart)) today++;
        if (from != null && created != null && created.isBefore(from)) continue;
        if (to != null && created != null && created.isAfter(to)) continue;

        if (fs == 'awaiting_deposit' || fs == 'amount_determined') pending++;
        if (fs == 'deposit_confirmed' || fs == 'fully_deposited') confirmed++;
        if (fs == 'awaiting_calculation' || fs == 'awaiting_deposit') unpaid++;
        if (fs == 'overdue') overdue++;
        if (fs == 'awaiting_settlement' || fs == 'ready_for_release') settle++;
        revenue += (t['company_fees'] as num?)?.toDouble() ?? 0;
        officeDue += (t['office_commission_amount'] as num?)?.toDouble() ?? 0;
      }

      // Settlements outstanding
      var pendingTransfers = 0;
      try {
        final settlements = await _supabase.client
            .from('office_settlements')
            .select('id, status')
            .inFilter('status', ['prepared', 'approved']);
        pendingTransfers = (settlements as List).length;
      } catch (_) {}

      return FinanceDashboardStats(
        pendingDeposits: pending,
        confirmedDeposits: confirmed,
        unpaid: unpaid,
        overdue: overdue,
        awaitingSettlement: settle,
        officeAmountsDue: officeDue,
        companyRevenue: revenue,
        pendingTransfers: pendingTransfers,
        todaysOps: today,
      );
    } catch (_) {
      return const FinanceDashboardStats(
        pendingDeposits: 0,
        confirmedDeposits: 0,
        unpaid: 0,
        overdue: 0,
        awaitingSettlement: 0,
        officeAmountsDue: 0,
        companyRevenue: 0,
        pendingTransfers: 0,
        todaysOps: 0,
      );
    }
  }

  Future<bool> updateTransactionFinancials({
    required String transactionId,
    double? requiredEscrow,
    double? companyFees,
    double? taxAmount,
    double? officeCommission,
    double? bankFees,
    double? sellerNet,
    String? financialStatus,
    String? reason,
  }) async {
    if (_token == null || !can(EmployeePermission.financialEdit)) return false;
    try {
      final result = await _supabase.client.rpc(
        'finance_update_transaction_amounts',
        params: {
          'p_session_token': _token,
          'p_transaction_id': transactionId,
          'p_required_escrow': requiredEscrow,
          'p_company_fees': companyFees,
          'p_tax_amount': taxAmount,
          'p_office_commission': officeCommission,
          'p_bank_fees': bankFees,
          'p_seller_net': sellerNet,
          'p_financial_status': financialStatus,
          'p_reason': reason,
        },
      );
      return result is Map && result['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listFeeDefinitions() async {
    if (!can(EmployeePermission.financialRules) &&
        !can(EmployeePermission.financialView)) {
      return [];
    }
    try {
      final rows = await _supabase.client
          .from('financial_fee_definitions')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listCommissionRules() async {
    if (!can(EmployeePermission.financialRules) &&
        !can(EmployeePermission.financialView) &&
        !can(EmployeePermission.officesView)) {
      return [];
    }
    try {
      final rows = await _supabase.client
          .from('office_commission_rules')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<bool> createPaymentRequest({
    required String transactionId,
    required double amount,
    String? reason,
    DateTime? deadline,
  }) async {
    if (_employee == null || !can(EmployeePermission.financialEdit)) {
      return false;
    }
    try {
      await _supabase.client.from('payment_requests').insert({
        'transaction_id': transactionId,
        'amount': amount,
        'reason': reason,
        'deadline': deadline?.toIso8601String().split('T').first,
        'created_by_employee_id': _employee!.id,
        'status': 'sent',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listOfficeSettlements() async {
    if (!can(EmployeePermission.financialSettlement) &&
        !can(EmployeePermission.financialView)) {
      return [];
    }
    try {
      final rows = await _supabase.client
          .from('office_settlements')
          .select('*, offices(name, office_code)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listOfficeAccounts() async {
    if (!can(EmployeePermission.financialView) &&
        !can(EmployeePermission.officesView)) {
      return [];
    }
    try {
      final offices = await _supabase.client.from('offices').select();
      final list = <Map<String, dynamic>>[];
      for (final o in List<Map<String, dynamic>>.from(offices)) {
        final txs = await _supabase.client
            .from('transactions')
            .select('id, lifecycle_state, office_commission_amount, company_fees')
            .eq('created_by_office_id', o['id']);
        final txList = List<Map<String, dynamic>>.from(txs);
        var commission = 0.0, company = 0.0, completed = 0;
        for (final t in txList) {
          commission += (t['office_commission_amount'] as num?)?.toDouble() ?? 0;
          company += (t['company_fees'] as num?)?.toDouble() ?? 0;
          if ((t['lifecycle_state'] as String?) == 'completed') completed++;
        }
        list.add({
          'office': o,
          'transactions': txList.length,
          'completed_sales': completed,
          'office_commission': commission,
          'company_share': company,
          'amount_due': commission,
        });
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  // ── Bank ──────────────────────────────────────────────────────────────────

  Future<BankDashboardStats> bankDashboardStats() async {
    if (!can(EmployeePermission.bankVerify) &&
        !can(EmployeePermission.bankDepositConfirm)) {
      return const BankDashboardStats(
        pendingDeposits: 0,
        todaysDeposits: 0,
        completedDeposits: 0,
        awaitingOtp: 0,
        verificationRequired: 0,
        failedVerification: 0,
      );
    }
    try {
      final txs = await _supabase.client
          .from('transactions')
          .select('id, financial_status, buyer_identity_verified, updated_at');
      final list = List<Map<String, dynamic>>.from(txs);
      final today = DateTime.now();
      final dayStart = DateTime(today.year, today.month, today.day);
      var pending = 0, todays = 0, completed = 0, verifyReq = 0;

      for (final t in list) {
        final fs = (t['financial_status'] as String? ?? '').toLowerCase();
        final updated = DateTime.tryParse(t['updated_at']?.toString() ?? '');
        if (fs == 'awaiting_deposit' || fs == 'amount_determined') pending++;
        if (fs == 'deposit_confirmed') {
          completed++;
          if (updated != null && !updated.isBefore(dayStart)) todays++;
        }
        if (t['buyer_identity_verified'] != true &&
            (fs == 'awaiting_deposit' || fs == 'amount_determined')) {
          verifyReq++;
        }
      }

      var awaitingOtp = 0;
      try {
        final otps = await _supabase.client
            .from('bank_buyer_otps')
            .select('id')
            .isFilter('verified_at', null)
            .gt('expires_at', DateTime.now().toIso8601String());
        awaitingOtp = (otps as List).length;
      } catch (_) {}

      return BankDashboardStats(
        pendingDeposits: pending,
        todaysDeposits: todays,
        completedDeposits: completed,
        awaitingOtp: awaitingOtp,
        verificationRequired: verifyReq,
        failedVerification: 0,
      );
    } catch (_) {
      return const BankDashboardStats(
        pendingDeposits: 0,
        todaysDeposits: 0,
        completedDeposits: 0,
        awaitingOtp: 0,
        verificationRequired: 0,
        failedVerification: 0,
      );
    }
  }

  Future<
      ({
        bool success,
        String? message,
        String? phoneMasked,
        String? phoneE164,
        String? delivery,
        String? debugOtp,
      })> requestBuyerOtp(String transactionId) async {
    if (_token == null) {
      return (
        success: false,
        message: 'unauthorized',
        phoneMasked: null,
        phoneE164: null,
        delivery: null,
        debugOtp: null,
      );
    }
    try {
      final result = await _supabase.client.rpc(
        'bank_request_buyer_otp',
        params: {
          'p_session_token': _token,
          'p_transaction_id': transactionId,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : null)?.toString(),
          phoneMasked: null,
          phoneE164: null,
          delivery: null,
          debugOtp: null,
        );
      }
      return (
        success: true,
        message: null,
        phoneMasked: result['phone_masked']?.toString(),
        phoneE164: result['phone_e164']?.toString(),
        delivery: result['delivery']?.toString(),
        debugOtp: result['debug_otp']?.toString(),
      );
    } catch (_) {
      return (
        success: false,
        message: 'unavailable',
        phoneMasked: null,
        phoneE164: null,
        delivery: null,
        debugOtp: null,
      );
    }
  }

  Future<({bool success, String? message})> markBuyerVerifiedViaTwilio(
    String transactionId,
  ) async {
    if (_token == null) return (success: false, message: 'unauthorized');
    try {
      final result = await _supabase.client.rpc(
        'bank_mark_buyer_verified_via_twilio',
        params: {
          'p_session_token': _token,
          'p_transaction_id': transactionId,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
        );
      }
      return (success: true, message: null);
    } catch (_) {
      return (success: false, message: 'unavailable');
    }
  }

  Future<({bool success, String? message})> verifyBuyerOtp({
    required String transactionId,
    required String otp,
  }) async {
    if (_token == null) return (success: false, message: 'unauthorized');
    try {
      final result = await _supabase.client.rpc(
        'bank_verify_buyer_otp',
        params: {
          'p_session_token': _token,
          'p_transaction_id': transactionId,
          'p_otp': otp,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
        );
      }
      return (success: true, message: null);
    } catch (_) {
      return (success: false, message: 'unavailable');
    }
  }

  Future<({bool success, String? message, String? receiptId, String? status})>
      confirmDeposit({
    required String transactionId,
    required double actualAmount,
    required String referenceNumber,
    required DateTime depositDate,
    bool allowPartial = false,
  }) async {
    if (_token == null) {
      return (success: false, message: 'unauthorized', receiptId: null, status: null);
    }
    try {
      final result = await _supabase.client.rpc(
        'bank_confirm_deposit',
        params: {
          'p_session_token': _token,
          'p_transaction_id': transactionId,
          'p_actual_amount': actualAmount,
          'p_reference_number': referenceNumber,
          'p_deposit_date': depositDate.toIso8601String().split('T').first,
          'p_allow_partial': allowPartial,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
          receiptId: null,
          status: null,
        );
      }
      return (
        success: true,
        message: null,
        receiptId: result['receipt_id']?.toString(),
        status: result['status']?.toString(),
      );
    } catch (_) {
      return (success: false, message: 'unavailable', receiptId: null, status: null);
    }
  }

  Future<List<Map<String, dynamic>>> listDepositReceipts() async {
    if (!can(EmployeePermission.bankReceiptCreate) &&
        !can(EmployeePermission.bankDepositConfirm)) {
      return [];
    }
    try {
      final rows = await _supabase.client
          .from('bank_deposit_receipts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  // ── Office Management ─────────────────────────────────────────────────────

  Future<OfficeMgmtDashboardStats> officeMgmtDashboardStats() async {
    if (!can(EmployeePermission.officesView)) {
      return const OfficeMgmtDashboardStats(
        activeOffices: 0,
        pendingRequests: 0,
        newPropertyReports: 0,
        awaitingPhotography: 0,
        activeOfficeTransactions: 0,
      );
    }
    try {
      final offices = await _supabase.client.from('offices').select('id, status');
      final oList = List<Map<String, dynamic>>.from(offices);
      final active =
          oList.where((o) => (o['status'] as String?) == 'active').length;
      final pending = oList
          .where(
            (o) =>
                (o['status'] as String?) == 'pending' ||
                (o['status'] as String?) == 'pending_verification' ||
                (o['status'] as String?) == 'draft',
          )
          .length;

      var reports = 0;
      try {
        final r = await _supabase.client
            .from('office_property_reports')
            .select('id')
            .eq('status', 'under_review');
        reports = (r as List).length;
      } catch (_) {}

      var photo = 0;
      try {
        final p = await _supabase.client
            .from('photography_requests')
            .select('id')
            .eq('status', 'waiting_for_photography');
        photo = (p as List).length;
      } catch (_) {}

      var activeTx = 0;
      try {
        final t = await _supabase.client
            .from('transactions')
            .select('id, lifecycle_state')
            .not('created_by_office_id', 'is', null);
        activeTx = List<Map<String, dynamic>>.from(t)
            .where((e) => (e['lifecycle_state'] as String?) != 'completed')
            .length;
      } catch (_) {}

      return OfficeMgmtDashboardStats(
        activeOffices: active,
        pendingRequests: pending,
        newPropertyReports: reports,
        awaitingPhotography: photo,
        activeOfficeTransactions: activeTx,
      );
    } catch (_) {
      return const OfficeMgmtDashboardStats(
        activeOffices: 0,
        pendingRequests: 0,
        newPropertyReports: 0,
        awaitingPhotography: 0,
        activeOfficeTransactions: 0,
      );
    }
  }

  Future<List<Map<String, dynamic>>> listOffices() async {
    if (!can(EmployeePermission.officesView)) return [];
    try {
      final rows = await _supabase.client
          .from('offices')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<({bool success, String? message, String? officeCode, String? secret})>
      createOffice({
    required String name,
    required String ownerFullName,
    required String ownerPhone,
    required String officePhone,
    String? email,
    required String countryCode,
    String? city,
    String? region,
    String? address,
    String? licenseNumber,
    String? officeType,
  }) async {
    if (_token == null) {
      return (success: false, message: 'unauthorized', officeCode: null, secret: null);
    }
    try {
      final result = await _supabase.client.rpc(
        'employee_create_office',
        params: {
          'p_session_token': _token,
          'p_name': name,
          'p_owner_full_name': ownerFullName,
          'p_owner_phone': ownerPhone,
          'p_office_phone': officePhone,
          'p_email': email,
          'p_country_code': countryCode,
          'p_city': city,
          'p_region': region,
          'p_address': address,
          'p_license_number': licenseNumber,
          'p_office_type': officeType ?? 'partner',
        },
      );
      if (result is! Map || result['success'] != true) {
        return (
          success: false,
          message: (result is Map ? result['message'] : 'failed')?.toString(),
          officeCode: null,
          secret: null,
        );
      }
      return (
        success: true,
        message: null,
        officeCode: result['office_code']?.toString(),
        secret: result['temporary_secret']?.toString(),
      );
    } catch (_) {
      return (success: false, message: 'unavailable', officeCode: null, secret: null);
    }
  }

  Future<bool> setOfficeStatus({
    required String officeId,
    required String status,
    String? reason,
  }) async {
    if (_token == null) return false;
    try {
      final result = await _supabase.client.rpc(
        'employee_set_office_status',
        params: {
          'p_session_token': _token,
          'p_office_id': officeId,
          'p_status': status,
          'p_reason': reason,
        },
      );
      return result is Map && result['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String? secret})> resetOfficeSecret(String officeId) async {
    if (_token == null) return (success: false, secret: null);
    try {
      final result = await _supabase.client.rpc(
        'employee_reset_office_secret',
        params: {
          'p_session_token': _token,
          'p_office_id': officeId,
        },
      );
      if (result is! Map || result['success'] != true) {
        return (success: false, secret: null);
      }
      return (success: true, secret: result['temporary_secret']?.toString());
    } catch (_) {
      return (success: false, secret: null);
    }
  }

  Future<List<Map<String, dynamic>>> listPropertyReports() async {
    if (!can(EmployeePermission.propertiesView)) return [];
    try {
      final rows = await _supabase.client
          .from('office_property_reports')
          .select('*, offices(name, office_code)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<bool> createPhotographyRequest({
    required String temporaryPropertyId,
    String? officeId,
    String? reportId,
    String? ownerPhone,
    String? locationText,
    String? propertyType,
    String? notes,
    String priority = 'normal',
  }) async {
    if (_employee == null ||
        !can(EmployeePermission.propertiesPublishRequest)) {
      return false;
    }
    try {
      await _supabase.client.from('photography_requests').insert({
        'temporary_property_id': temporaryPropertyId,
        'office_id': officeId,
        'report_id': reportId,
        'owner_phone': ownerPhone,
        'location_text': locationText,
        'property_type': propertyType,
        'notes': notes,
        'priority': priority,
        'status': 'waiting_for_photography',
        'created_by_employee_id': _employee!.id,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listPhotographyRequests() async {
    if (!can(EmployeePermission.propertiesView) &&
        !can(EmployeePermission.propertiesPublishRequest)) {
      return [];
    }
    try {
      final rows = await _supabase.client
          .from('photography_requests')
          .select('*, offices(name, office_code)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listOfficeConversations() async {
    if (!can(EmployeePermission.messagesView)) return [];
    try {
      final rows = await _supabase.client
          .from('office_conversations')
          .select('*, offices(name, office_code)')
          .order('last_message_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }
}
