import '../features/employee/core/domain/employee_models.dart';
import '../features/employee/core/domain/employee_permissions.dart';

/// Local Bank Employee preview seed.
/// Credentials: [code] / [secret] — displays as BNK-0042.
abstract final class BankSeed {
  static const String code = 'BNK001';
  static const String displayCode = 'BNK-0042';
  static const String secret = '123456';
  static const String token = 'seed-bank-token';
  static const String employeeId = 'seed-bank-001';

  /// Demo OTP the buyer would provide (never shown in bank UI).
  static const String demoBuyerOtp = '482910';

  static final Map<String, List<Map<String, dynamic>>> _threads = {};
  static final List<Map<String, dynamic>> _audit = [];
  static final Map<String, _OtpState> _otp = {};

  static bool matches(String employeeCode, String secretCode) {
    final c = employeeCode.trim().toUpperCase().replaceAll(' ', '');
    return (c == code ||
            c == displayCode.replaceAll('-', '') ||
            c == displayCode) &&
        secretCode == secret;
  }

  static bool isSeedToken(String? t) => t == token;

  static EmployeeAccount account() {
    return EmployeeAccount(
      id: employeeId,
      employeeCode: displayCode,
      fullName: 'أحمد علي',
      jobTitle: 'Bank Operations Officer',
      countryCode: 'IQ',
      branchCode: 'BGH',
      employmentStatus: 'active',
      department: const EmployeeDepartment(
        id: 'dept-bank',
        code: 'bank',
        nameEn: 'Bank Operations',
        nameAr: 'عمليات البنك',
      ),
      role: const EmployeeRole(
        id: 'role-bank-officer',
        code: 'bank_officer',
        nameEn: 'Bank Officer',
        nameAr: 'موظف بنك',
      ),
      permissions: {
        EmployeePermission.bankVerify,
        EmployeePermission.bankDepositConfirm,
        EmployeePermission.bankReceiptCreate,
        EmployeePermission.bankPartialDeposit,
        EmployeePermission.transactionsView,
        EmployeePermission.transactionRead,
        EmployeePermission.messagesView,
        EmployeePermission.messagesSend,
        EmployeePermission.searchGlobal,
        EmployeePermission.auditView,
      },
    );
  }

  static EmployeeSession session() {
    return EmployeeSession(token: token, employee: account());
  }

  static BankDashboardStats stats() {
    final txs = transactions();
    final pending = txs
        .where((t) =>
            t['financial_status'] == 'awaiting_deposit' ||
            t['financial_status'] == 'awaiting_remaining')
        .length;
    final awaitingOtp =
        txs.where((t) => t['buyer_identity_verified'] != true).length;
    final completed =
        txs.where((t) => t['financial_status'] == 'deposit_confirmed').length;
    final todayReceipts = receipts()
        .where((r) {
          final d = DateTime.tryParse(r['created_at']?.toString() ?? '');
          if (d == null) return false;
          final n = DateTime.now();
          return d.year == n.year && d.month == n.month && d.day == n.day;
        })
        .length;
    return BankDashboardStats(
      pendingDeposits: pending,
      todaysDeposits: todayReceipts,
      completedDeposits: completed,
      awaitingOtp: awaitingOtp,
      verificationRequired: awaitingOtp,
      failedVerification: 0,
    );
  }

  static List<Map<String, dynamic>> _live = [];

  static List<Map<String, dynamic>> transactions() {
    if (_live.isEmpty) {
      _live = [
        {
          'id': 'btx-1',
          'transaction_number': '202600481',
          'property_id': '4509-B',
          'property_title': 'فيلا سكنية — المنصور',
          'transaction_type': 'sale',
          'buyer_name': 'محمد العتيبي',
          'buyer_id': '88472910',
          'buyer_phone': '+9647801234567',
          'seller_name': 'شركة الأفق العقارية',
          'seller_id': '1009384',
          'seller_phone': '+9647709876543',
          'office_name': 'مركز مدار بغداد',
          'office_code': 'OFF-2048',
          'lifecycle_state': 'escrow_deposit',
          'financial_status': 'awaiting_deposit',
          'current_stage': 'escrow_deposit',
          'buyer_identity_verified': false,
          'property_price': 240000000,
          'buyer_taxes': 7500000,
          'seller_taxes': 0,
          'madar_fees': 2000000,
          'bank_fees': 500000,
          'other_charges': 0,
          'required_escrow_amount': 250000000,
          'deposited_escrow_amount': 0,
          'currency': 'IQD',
          'escrow_account_label': 'حساب ضمان مدار — بغداد',
          'escrow_reference': 'ESC-MADAR-BGH-0481',
          'release_condition':
              'تبقى الأموال خاضعة لشروط الضمان الخاصة بالمعاملة وتُحرَّر وفق سير العمل المعتمد.',
          'is_agricultural': false,
          'updated_at': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
          'stages': const [
            {'key': 'identity', 'label': 'التحقق من الهوية', 'state': 'done'},
            {'key': 'documents', 'label': 'المستندات', 'state': 'done'},
            {'key': 'contract', 'label': 'العقد', 'state': 'done'},
            {
              'key': 'escrow_deposit',
              'label': 'إيداع الضمان',
              'state': 'current'
            },
            {
              'key': 'ownership',
              'label': 'نقل الملكية',
              'state': 'waiting'
            },
            {'key': 'settlement', 'label': 'التسوية', 'state': 'waiting'},
          ],
        },
        {
          'id': 'btx-2',
          'transaction_number': '202600512',
          'property_id': '7812-A',
          'property_title': 'أرض زراعية — أبو غريب',
          'transaction_type': 'sale',
          'buyer_name': 'سارة الكندي',
          'buyer_id': '77221003',
          'buyer_phone': '+9647512345678',
          'seller_name': 'علي الجبوري',
          'seller_id': '55110022',
          'seller_phone': '+9647901122334',
          'office_name': 'مكتب مدار — الكرادة',
          'office_code': 'OFF001',
          'lifecycle_state': 'escrow_deposit',
          'financial_status': 'awaiting_remaining',
          'current_stage': 'escrow_deposit',
          'buyer_identity_verified': true,
          'property_price': 180000000,
          'buyer_taxes': 5000000,
          'seller_taxes': 0,
          'madar_fees': 1500000,
          'bank_fees': 500000,
          'other_charges': 0,
          'required_escrow_amount': 187000000,
          'deposited_escrow_amount': 100000000,
          'currency': 'IQD',
          'escrow_account_label': 'حساب ضمان مدار — بغداد',
          'escrow_reference': 'ESC-MADAR-BGH-0512',
          'release_condition':
              'تحرير الضمان خاضع لاستكمال شروط نقل الملكية الزراعية والموافقات المطلوبة.',
          'is_agricultural': true,
          'updated_at': DateTime.now()
              .subtract(const Duration(hours: 5))
              .toIso8601String(),
          'receipt_number': 'RC-2026-000171',
          'stages': const [
            {'key': 'identity', 'label': 'التحقق من الهوية', 'state': 'done'},
            {'key': 'documents', 'label': 'المستندات', 'state': 'done'},
            {'key': 'contract', 'label': 'العقد', 'state': 'done'},
            {
              'key': 'escrow_deposit',
              'label': 'إيداع الضمان',
              'state': 'current'
            },
            {
              'key': 'ownership',
              'label': 'نقل الملكية',
              'state': 'waiting'
            },
            {'key': 'settlement', 'label': 'التسوية', 'state': 'waiting'},
          ],
        },
        {
          'id': 'btx-3',
          'transaction_number': '202600398',
          'property_id': '2201-C',
          'property_title': 'شقة — الجادرية',
          'transaction_type': 'sale',
          'buyer_name': 'نور الساعدي',
          'buyer_id': '66110044',
          'buyer_phone': '+9647705556677',
          'seller_name': 'حسين العبودي',
          'seller_id': '33004411',
          'seller_phone': '+9647809988776',
          'office_name': 'مركز مدار بغداد',
          'office_code': 'OFF-2048',
          'lifecycle_state': 'ownership_transfer',
          'financial_status': 'deposit_confirmed',
          'current_stage': 'ownership',
          'buyer_identity_verified': true,
          'property_price': 95000000,
          'buyer_taxes': 3000000,
          'seller_taxes': 0,
          'madar_fees': 1000000,
          'bank_fees': 250000,
          'other_charges': 0,
          'required_escrow_amount': 99250000,
          'deposited_escrow_amount': 99250000,
          'currency': 'IQD',
          'escrow_account_label': 'حساب ضمان مدار — بغداد',
          'escrow_reference': 'ESC-MADAR-BGH-0398',
          'release_condition':
              'تبقى الأموال خاضعة لشروط الضمان الخاصة بالمعاملة وتُحرَّر وفق سير العمل المعتمد.',
          'is_agricultural': false,
          'updated_at': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'receipt_number': 'RC-2026-000184',
          'stages': const [
            {'key': 'identity', 'label': 'التحقق من الهوية', 'state': 'done'},
            {'key': 'documents', 'label': 'المستندات', 'state': 'done'},
            {'key': 'contract', 'label': 'العقد', 'state': 'done'},
            {
              'key': 'escrow_deposit',
              'label': 'إيداع الضمان',
              'state': 'done'
            },
            {
              'key': 'ownership',
              'label': 'نقل الملكية',
              'state': 'current'
            },
            {'key': 'settlement', 'label': 'التسوية', 'state': 'waiting'},
          ],
        },
      ];
    }
    return List<Map<String, dynamic>>.from(
      _live.map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static Map<String, dynamic>? findTransaction(String query) {
    final q = query.trim().toLowerCase().replaceAll('#', '');
    if (q.isEmpty) return null;
    for (final t in transactions()) {
      final hay = [
        t['id'],
        t['transaction_number'],
        t['property_id'],
        t['buyer_id'],
        t['buyer_phone'],
        t['seller_id'],
        t['seller_phone'],
        t['escrow_reference'],
        t['receipt_number'],
      ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');
      if (hay.contains(q) ||
          (t['buyer_phone']?.toString() ?? '')
              .replaceAll(RegExp(r'[^\d+]'), '')
              .contains(q.replaceAll(RegExp(r'[^\d+]'), ''))) {
        return Map<String, dynamic>.from(t);
      }
    }
    return null;
  }

  static Map<String, dynamic>? transactionById(String id) {
    for (final t in transactions()) {
      if (t['id'] == id || t['transaction_number']?.toString() == id) {
        return Map<String, dynamic>.from(t);
      }
    }
    return null;
  }

  static void _replace(Map<String, dynamic> updated) {
    final i = _live.indexWhere((t) => t['id'] == updated['id']);
    if (i >= 0) _live[i] = updated;
  }

  static void audit({
    required String action,
    required String result,
    String? transactionId,
  }) {
    _audit.insert(0, {
      'id': 'aud-${DateTime.now().millisecondsSinceEpoch}',
      'employee_id': displayCode,
      'employee_name': 'أحمد علي',
      'action': action,
      'result': result,
      'transaction_id': transactionId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static List<Map<String, dynamic>> auditLog() =>
      List<Map<String, dynamic>>.from(_audit);

  static ({bool success, String? message, String? phoneMasked}) requestOtp(
    String transactionId,
  ) {
    final t = transactionById(transactionId);
    if (t == null) {
      return (success: false, message: 'المعاملة غير موجودة', phoneMasked: null);
    }
    if (t['financial_status'] == 'deposit_confirmed') {
      return (
        success: false,
        message: 'تم تأكيد الإيداع مسبقاً',
        phoneMasked: null
      );
    }
    final phone = t['buyer_phone']?.toString() ?? '';
    _otp[transactionId] = _OtpState(
      code: demoBuyerOtp,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      attempts: 0,
      sentAt: DateTime.now(),
    );
    audit(
      action: 'request_otp',
      result: 'sent',
      transactionId: transactionId,
    );
    final masked = phone.length > 4
        ? '${phone.substring(0, 6)}••••${phone.substring(phone.length - 3)}'
        : '••••';
    return (success: true, message: 'تم إرسال رمز التحقق', phoneMasked: masked);
  }

  static ({bool success, String? message}) verifyOtp({
    required String transactionId,
    required String otp,
  }) {
    final state = _otp[transactionId];
    final t = transactionById(transactionId);
    if (t == null) {
      return (success: false, message: 'المعاملة غير موجودة');
    }
    if (state == null) {
      return (success: false, message: 'لم يتم إرسال رمز التحقق بعد');
    }
    if (DateTime.now().isAfter(state.expiresAt)) {
      return (success: false, message: 'انتهت صلاحية رمز التحقق');
    }
    if (state.attempts >= 5) {
      return (success: false, message: 'محاولات كثيرة جداً');
    }
    state.attempts++;
    if (otp.trim() != state.code) {
      audit(
        action: 'verify_otp',
        result: 'incorrect',
        transactionId: transactionId,
      );
      return (success: false, message: 'رمز التحقق غير صحيح');
    }
    t['buyer_identity_verified'] = true;
    t['identity_verified_at'] = DateTime.now().toIso8601String();
    t['identity_verified_by'] = displayCode;
    _replace(t);
    audit(
      action: 'verify_otp',
      result: 'verified',
      transactionId: transactionId,
    );
    return (success: true, message: 'تم التحقق من هوية المشتري');
  }

  static ({
    bool success,
    String? message,
    String? status,
    String? receiptNumber,
  }) confirmDeposit({
    required String transactionId,
    required double actualAmount,
    required String referenceNumber,
  }) {
    final t = transactionById(transactionId);
    if (t == null) {
      return (
        success: false,
        message: 'المعاملة غير موجودة',
        status: null,
        receiptNumber: null
      );
    }
    if (t['buyer_identity_verified'] != true) {
      return (
        success: false,
        message: 'يجب التحقق من هوية المشتري أولاً',
        status: null,
        receiptNumber: null
      );
    }
    if (t['financial_status'] == 'deposit_confirmed') {
      return (
        success: false,
        message: 'تم تأكيد الإيداع مسبقاً. الإيصال: ${t['receipt_number']}',
        status: 'already_confirmed',
        receiptNumber: t['receipt_number']?.toString()
      );
    }
    final required =
        (t['required_escrow_amount'] as num?)?.toDouble() ?? 0;
    final already =
        (t['deposited_escrow_amount'] as num?)?.toDouble() ?? 0;
    final remaining = required - already;
    if (actualAmount > remaining + 0.01) {
      return (
        success: false,
        message:
            'المبلغ يتجاوز المطلوب. يتطلب تفويضاً إضافياً وفق سياسة مدار المالية.',
        status: 'overpayment',
        receiptNumber: null
      );
    }
    final newDeposited = already + actualAmount;
    t['deposited_escrow_amount'] = newDeposited;
    t['last_deposit_reference'] = referenceNumber;
    t['last_deposit_at'] = DateTime.now().toIso8601String();
    t['last_deposit_by'] = displayCode;

    String status;
    String? receiptNumber;
    if (newDeposited + 0.01 >= required) {
      status = 'deposit_confirmed';
      t['financial_status'] = 'deposit_confirmed';
      t['lifecycle_state'] = 'ownership_transfer';
      t['current_stage'] = 'ownership';
      final stages = List<Map<String, dynamic>>.from(
        (t['stages'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ??
            [],
      );
      for (final s in stages) {
        if (s['key'] == 'escrow_deposit') s['state'] = 'done';
        if (s['key'] == 'ownership') s['state'] = 'current';
      }
      t['stages'] = stages;
      receiptNumber = _nextReceiptNumber();
      t['receipt_number'] = receiptNumber;
      _addReceipt(t, actualAmount, referenceNumber, receiptNumber);
    } else {
      status = 'awaiting_remaining';
      t['financial_status'] = 'awaiting_remaining';
      receiptNumber = _nextReceiptNumber();
      t['receipt_number'] = receiptNumber;
      _addReceipt(t, actualAmount, referenceNumber, receiptNumber);
    }
    _replace(t);
    audit(
      action: 'confirm_deposit',
      result: status,
      transactionId: transactionId,
    );
    return (
      success: true,
      message: status == 'deposit_confirmed'
          ? 'تم تأكيد الإيداع وإصدار الإيصال'
          : 'إيداع جزئي — بانتظار المتبقي',
      status: status,
      receiptNumber: receiptNumber,
    );
  }

  static int _receiptSeq = 184;

  static String _nextReceiptNumber() {
    _receiptSeq++;
    return 'RC-2026-${_receiptSeq.toString().padLeft(6, '0')}';
  }

  static final List<Map<String, dynamic>> _receipts = [];

  static void _addReceipt(
    Map<String, dynamic> t,
    double amount,
    String reference,
    String receiptNumber,
  ) {
    _receipts.insert(0, {
      'id': 'rc-${DateTime.now().millisecondsSinceEpoch}',
      'receipt_number': receiptNumber,
      'transaction_id': t['id'],
      'transaction_number': t['transaction_number'],
      'property_id': t['property_id'],
      'property_title': t['property_title'],
      'buyer_name': t['buyer_name'],
      'buyer_phone': t['buyer_phone'],
      'seller_name': t['seller_name'],
      'office_name': t['office_name'],
      'amount': amount,
      'currency': t['currency'] ?? 'IQD',
      'required_amount': t['required_escrow_amount'],
      'property_price': t['property_price'],
      'buyer_taxes': t['buyer_taxes'],
      'madar_fees': t['madar_fees'],
      'bank_fees': t['bank_fees'],
      'reference_number': reference,
      'escrow_reference': t['escrow_reference'],
      'deposit_date': DateTime.now().toIso8601String().split('T').first,
      'created_at': DateTime.now().toIso8601String(),
      'bank_employee': 'أحمد علي',
      'bank_employee_id': displayCode,
      'status': 'issued',
      'verification_status': 'verified',
    });
  }

  static List<Map<String, dynamic>> receipts() {
    final seeded = [
      if (_receipts.every((r) => r['receipt_number'] != 'RC-2026-000184'))
        {
          'id': 'rc-seed-184',
          'receipt_number': 'RC-2026-000184',
          'transaction_id': 'btx-3',
          'transaction_number': '202600398',
          'property_id': '2201-C',
          'property_title': 'شقة — الجادرية',
          'buyer_name': 'نور الساعدي',
          'buyer_phone': '+9647705556677',
          'seller_name': 'حسين العبودي',
          'office_name': 'مركز مدار بغداد',
          'amount': 99250000,
          'currency': 'IQD',
          'required_amount': 99250000,
          'property_price': 95000000,
          'buyer_taxes': 3000000,
          'madar_fees': 1000000,
          'bank_fees': 250000,
          'reference_number': 'BNK-REF-0398',
          'escrow_reference': 'ESC-MADAR-BGH-0398',
          'deposit_date': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String()
              .split('T')
              .first,
          'created_at': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'bank_employee': 'أحمد علي',
          'bank_employee_id': displayCode,
          'status': 'issued',
          'verification_status': 'verified',
        },
      if (_receipts.every((r) => r['receipt_number'] != 'RC-2026-000171'))
        {
          'id': 'rc-seed-171',
          'receipt_number': 'RC-2026-000171',
          'transaction_id': 'btx-2',
          'transaction_number': '202600512',
          'property_id': '7812-A',
          'property_title': 'أرض زراعية — أبو غريب',
          'buyer_name': 'سارة الكندي',
          'buyer_phone': '+9647512345678',
          'seller_name': 'علي الجبوري',
          'office_name': 'مكتب مدار — الكرادة',
          'amount': 100000000,
          'currency': 'IQD',
          'required_amount': 187000000,
          'property_price': 180000000,
          'buyer_taxes': 5000000,
          'madar_fees': 1500000,
          'bank_fees': 500000,
          'reference_number': 'BNK-REF-0512',
          'escrow_reference': 'ESC-MADAR-BGH-0512',
          'deposit_date': DateTime.now()
              .subtract(const Duration(hours: 6))
              .toIso8601String()
              .split('T')
              .first,
          'created_at': DateTime.now()
              .subtract(const Duration(hours: 6))
              .toIso8601String(),
          'bank_employee': 'أحمد علي',
          'bank_employee_id': displayCode,
          'status': 'issued',
          'verification_status': 'verified',
        },
    ];
    return [..._receipts, ...seeded];
  }

  static Map<String, dynamic>? receiptByNumber(String number) {
    for (final r in receipts()) {
      if (r['receipt_number'] == number || r['id'] == number) {
        return Map<String, dynamic>.from(r);
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> messages() {
    return [
      {
        'id': 'bnk-m1',
        'title': 'القسم المالي',
        'department_code': 'finance',
        'subtitle': 'بخصوص معاملة #202600481',
        'last_message_at': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      },
      {
        'id': 'bnk-m2',
        'title': 'الفريق القانوني',
        'department_code': 'legal',
        'subtitle': 'شروط تحرير الضمان الزراعية',
        'last_message_at': DateTime.now()
            .subtract(const Duration(hours: 4))
            .toIso8601String(),
      },
      {
        'id': 'bnk-m3',
        'title': 'فريق الإغلاق',
        'department_code': 'closing',
        'subtitle': 'معاملة #202600398 جاهزة للمرحلة التالية',
        'last_message_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
    ];
  }

  static List<Map<String, dynamic>> threadMessages(String conversationId) {
    return List<Map<String, dynamic>>.from(
      _threads.putIfAbsent(conversationId, () {
        if (conversationId == 'bnk-m1') {
          return [
            {
              'id': 't1',
              'sender_side': 'them',
              'sender_label': 'القسم المالي',
              'body':
                  'معاملة #202600481 بانتظار التحقق البنكي والإيداع.',
              'created_at': DateTime.now()
                  .subtract(const Duration(hours: 2))
                  .toIso8601String(),
            },
            {
              'id': 't2',
              'sender_side': 'me',
              'sender_label': 'موظف البنك',
              'body': 'سأبدأ التحقق من هوية المشتري الآن.',
              'created_at': DateTime.now()
                  .subtract(const Duration(hours: 1))
                  .toIso8601String(),
            },
          ];
        }
        return [
          {
            'id': 'e1',
            'sender_side': 'them',
            'sender_label': 'النظام',
            'body': 'محادثة مرتبطة بالعمليات البنكية.',
            'created_at': DateTime.now()
                .subtract(const Duration(hours: 3))
                .toIso8601String(),
          },
        ];
      }),
    );
  }

  static void sendThreadMessage(String conversationId, String body) {
    final list = _threads.putIfAbsent(conversationId, () => []);
    list.add({
      'id': 'local-${DateTime.now().millisecondsSinceEpoch}',
      'sender_side': 'me',
      'sender_label': 'موظف البنك',
      'body': body,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static List<Map<String, dynamic>> notifications() {
    return [
      {
        'id': 'bn-1',
        'title': 'معاملة بانتظار التحقق',
        'body': 'معاملة #202600481 جاهزة للتحقق البنكي',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 40))
            .toIso8601String(),
        'read': false,
      },
      {
        'id': 'bn-2',
        'title': 'تم إصدار إيصال',
        'body': 'RC-2026-000184 مرتبط بـ #202600398',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'read': true,
      },
    ];
  }

  static List<Map<String, dynamic>> timeline(String transactionId) {
    final t = transactionById(transactionId);
    if (t == null) return [];
    final events = <Map<String, dynamic>>[
      {
        'time': '09:15',
        'title': 'استلام المعاملة',
        'detail': 'بانتظار التحقق البنكي',
        'icon': 'pending',
      },
    ];
    if (t['buyer_identity_verified'] == true) {
      events.add({
        'time': '10:36',
        'title': 'تم التحقق من هوية المشتري',
        'detail': 'OTP · $displayCode',
        'icon': 'verified',
      });
    }
    final deposited =
        (t['deposited_escrow_amount'] as num?)?.toDouble() ?? 0;
    if (deposited > 0) {
      events.add({
        'time': '10:44',
        'title': 'تأكيد الإيداع',
        'detail':
            '${_fmt(deposited)} ${t['currency'] ?? 'IQD'} · $displayCode',
        'icon': 'deposit',
      });
    }
    if (t['receipt_number'] != null) {
      events.add({
        'time': '10:44',
        'title': 'إصدار الإيصال',
        'detail': t['receipt_number'].toString(),
        'icon': 'receipt',
      });
    }
    if (t['financial_status'] == 'deposit_confirmed') {
      events.add({
        'time': '10:45',
        'title': 'اكتمال المرحلة المالية',
        'detail': 'التالي: نقل الملكية',
        'icon': 'done',
      });
    }
    return events;
  }

  static String _fmt(num n) {
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      if (idx > 1 && idx % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

class _OtpState {
  _OtpState({
    required this.code,
    required this.expiresAt,
    required this.attempts,
    required this.sentAt,
  });

  final String code;
  final DateTime expiresAt;
  int attempts;
  final DateTime sentAt;
}
