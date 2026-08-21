import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../services/bank_seed.dart';
import '../../../../../services/twilio_verify_service.dart';
import '../../../core/domain/employee_permissions.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../theme/bank_tokens.dart';

/// Verification workspace: identity OTP → deposit → auto receipt.
class BankTransactionDetailScreen extends StatefulWidget {
  const BankTransactionDetailScreen({super.key, required this.transaction});

  final Map<String, dynamic> transaction;

  @override
  State<BankTransactionDetailScreen> createState() =>
      _BankTransactionDetailScreenState();
}

class _BankTransactionDetailScreenState
    extends State<BankTransactionDetailScreen> {
  final _otpCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _twilio = TwilioVerifyService();

  late Map<String, dynamic> _tx;
  String? _maskedPhone;
  String? _phoneE164;
  bool _viaTwilio = false;
  bool _otpSent = false;
  bool _verified = false;
  bool _busy = false;
  String? _otpStateLabel;
  String? _lastReceipt;
  String? _error;
  bool _depositDone = false;

  @override
  void initState() {
    super.initState();
    _tx = Map<String, dynamic>.from(widget.transaction);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<EmployeeAuthNotifier>();
      if (auth.repository.isBankSeedSession) {
        final fresh = BankSeed.transactionById(_tx['id']?.toString() ?? '') ??
            BankSeed.findTransaction(_tx['id']?.toString() ?? '');
        if (fresh != null) {
          setState(() {
            _tx = fresh;
            _verified = fresh['buyer_identity_verified'] == true;
            _depositDone = fresh['financial_status'] == 'deposit_confirmed';
            _lastReceipt = fresh['receipt_number']?.toString();
            final remaining = _remaining;
            _amountCtrl.text =
                remaining > 0 ? remaining.round().toString() : '';
          });
        }
        BankSeed.audit(
          action: 'view_transaction',
          result: 'ok',
          transactionId: _tx['id']?.toString(),
        );
      } else {
        setState(() {
          _verified = _tx['buyer_identity_verified'] == true;
          _depositDone = _tx['financial_status'] == 'deposit_confirmed';
          _lastReceipt = _tx['receipt_number']?.toString();
          final remaining = _remaining;
          _amountCtrl.text =
              remaining > 0 ? remaining.round().toString() : '';
        });
      }
    });
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  double get _required =>
      (_tx['required_escrow_amount'] as num?)?.toDouble() ?? 0;
  double get _deposited =>
      (_tx['deposited_escrow_amount'] as num?)?.toDouble() ?? 0;
  double get _remaining => (_required - _deposited).clamp(0, double.infinity);

  void _refreshFromSeed() {
    final auth = context.read<EmployeeAuthNotifier>();
    if (!auth.repository.isBankSeedSession) return;
    final fresh = BankSeed.transactionById(_tx['id'].toString());
    if (fresh != null) {
      setState(() {
        _tx = fresh;
        _verified = fresh['buyer_identity_verified'] == true;
        _depositDone = fresh['financial_status'] == 'deposit_confirmed';
        _lastReceipt = fresh['receipt_number']?.toString();
      });
    }
  }

  Future<void> _sendOtp() async {
    final auth = context.read<EmployeeAuthNotifier>();
    setState(() {
      _busy = true;
      _error = null;
    });
    if (auth.repository.isBankSeedSession) {
      final res = BankSeed.requestOtp(_tx['id'].toString());
      if (!mounted) return;
      setState(() {
        _busy = false;
        _otpSent = res.success;
        _maskedPhone = res.phoneMasked;
        _otpStateLabel = res.success ? 'تم الإرسال · بانتظار المشتري' : null;
        _error = res.success ? null : res.message;
      });
      return;
    }
    final res = await auth.repository.requestBuyerOtp(_tx['id'].toString());
    var twilioOk = false;
    if (res.success) {
      final phone =
          res.phoneE164 ?? _tx['buyer_phone']?.toString();
      if (phone != null && phone.startsWith('+')) {
        final sms = await _twilio.sendSms(phone);
        twilioOk = sms.success;
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _otpSent = res.success;
      _maskedPhone = res.phoneMasked;
      _phoneE164 = res.phoneE164 ?? _tx['buyer_phone']?.toString();
      _viaTwilio = twilioOk || res.delivery == 'twilio_verify';
      _otpStateLabel =
          res.success ? 'تم الإرسال · بانتظار المشتري' : null;
      _error = res.success ? null : (res.message ?? 'تعذر إرسال الرمز');
    });
  }

  Future<void> _verifyOtp() async {
    final auth = context.read<EmployeeAuthNotifier>();
    final code = _otpCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    if (auth.repository.isBankSeedSession) {
      final res = BankSeed.verifyOtp(
        transactionId: _tx['id'].toString(),
        otp: code,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _verified = res.success;
        _otpStateLabel = res.success ? 'تم التحقق' : 'رمز غير صحيح';
        _error = res.success ? null : res.message;
      });
      if (res.success) _refreshFromSeed();
      return;
    }
    var success = false;
    String? message;
    final phone = _phoneE164;
    if (_viaTwilio && phone != null && phone.startsWith('+')) {
      final check = await _twilio.checkCode(phoneE164: phone, code: code);
      if (check.success) {
        final marked = await auth.repository.markBuyerVerifiedViaTwilio(
          _tx['id'].toString(),
        );
        success = marked.success;
        message = marked.message;
      } else {
        message = check.message ?? 'رمز غير صحيح';
      }
    } else {
      final res = await auth.repository.verifyBuyerOtp(
        transactionId: _tx['id'].toString(),
        otp: code,
      );
      success = res.success;
      message = res.message;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _verified = success;
      _otpStateLabel = success ? 'تم التحقق' : 'فشل التحقق';
      _error = success ? null : (message ?? 'فشل التحقق');
    });
  }

  Future<void> _confirmDeposit() async {
    final auth = context.read<EmployeeAuthNotifier>();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'أدخل مبلغاً صالحاً');
      return;
    }
    if (_refCtrl.text.trim().isEmpty) {
      setState(() => _error = 'أدخل رقم المرجع البنكي');
      return;
    }
    if (amount > _remaining + 0.01) {
      setState(() => _error =
          'المبلغ يتجاوز المطلوب. يتطلب تفويضاً إضافياً وفق سياسة مدار المالية.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإيداع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المعاملة: #${_tx['transaction_number']}'),
            Text('المشتري: ${_tx['buyer_name'] ?? _tx['buyer_phone']}'),
            Text('المطلوب: ${_fmt(_required)} د.ع'),
            Text('المبلغ المودع: ${_fmt(amount)} د.ع'),
            Text('المتبقي بعد التأكيد: ${_fmt(_remaining - amount)} د.ع'),
            const SizedBox(height: 12),
            const Text(
              'هل تؤكد استلام وتسجيل هذا الإيداع في حساب الضمان؟',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    if (auth.repository.isBankSeedSession) {
      final res = BankSeed.confirmDeposit(
        transactionId: _tx['id'].toString(),
        actualAmount: amount,
        referenceNumber: _refCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (res.success) {
          _lastReceipt = res.receiptNumber;
          _depositDone = res.status == 'deposit_confirmed';
        }
        _error = res.success ? null : res.message;
      });
      if (res.success) {
        _refreshFromSeed();
        if (res.receiptNumber != null) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('تم تأكيد الإيداع'),
              content: Text(
                res.status == 'deposit_confirmed'
                    ? 'جاري إصدار الإيصال الرسمي.\nرقم الإيصال: ${res.receiptNumber}'
                    : 'إيداع جزئي مسجّل.\nالإيصال: ${res.receiptNumber}\nالحالة: بانتظار المتبقي',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إغلاق'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push(
                      '/employee/bank/receipt/${res.receiptNumber}',
                    );
                  },
                  child: const Text('عرض الإيصال'),
                ),
              ],
            ),
          );
        }
      }
      return;
    }

    final allowPartial = auth.can(EmployeePermission.bankPartialDeposit) &&
        amount < _remaining;
    final res = await auth.repository.confirmDeposit(
      transactionId: _tx['id'].toString(),
      actualAmount: amount,
      referenceNumber: _refCtrl.text.trim(),
      depositDate: DateTime.now(),
      allowPartial: allowPartial,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _depositDone = res.success && res.status == 'confirmed';
      _error = res.success ? null : (res.message ?? 'تعذر تأكيد الإيداع');
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<EmployeeAuthNotifier>();
    final number = _tx['transaction_number']?.toString() ?? '—';
    final status = _tx['financial_status']?.toString() ?? '';
    final wide = MediaQuery.sizeOf(context).width >= 960;

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_forward),
            ),
            const Expanded(
              child: Text(
                'تفاصيل المعاملة',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        _HeroCard(
          number: number,
          status: _statusAr(status),
          requiredAmount: _required,
          propertyId: _tx['property_id']?.toString(),
          propertyTitle: _tx['property_title']?.toString(),
        ),
        const SizedBox(height: 14),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _mainColumn(auth)),
              const SizedBox(width: 14),
              Expanded(flex: 2, child: _summaryColumn()),
            ],
          )
        else ...[
          _mainColumn(auth),
          const SizedBox(height: 14),
          _summaryColumn(),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: BankTokens.background,
      body: body,
    );
  }

  Widget _mainColumn(EmployeeAuthNotifier auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (auth.can(EmployeePermission.bankVerify)) _identityCard(),
        const SizedBox(height: 14),
        _breakdownCard(),
        const SizedBox(height: 14),
        _escrowCard(),
        const SizedBox(height: 14),
        if (auth.can(EmployeePermission.bankDepositConfirm)) _depositCard(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(
              color: BankTokens.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 14),
        _timelineCard(),
      ],
    );
  }

  Widget _summaryColumn() {
    return Column(
      children: [
        _PartyCard(
          title: 'المشتري',
          name: _tx['buyer_name']?.toString() ?? '—',
          id: _tx['buyer_id']?.toString(),
          phone: _tx['buyer_phone']?.toString(),
          verified: _verified,
        ),
        const SizedBox(height: 12),
        _PartyCard(
          title: 'البائع',
          name: _tx['seller_name']?.toString() ?? '—',
          id: _tx['seller_id']?.toString(),
          phone: _tx['seller_phone']?.toString(),
          verified: false,
          showVerified: false,
        ),
        const SizedBox(height: 12),
        _StagesCard(stages: _tx['stages'] as List? ?? const []),
        if (_lastReceipt != null) ...[
          const SizedBox(height: 12),
          Material(
            color: BankTokens.successSoft,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/employee/bank/receipt/$_lastReceipt'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: BankTokens.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'الإيصال · $_lastReceipt',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: BankTokens.success,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: BankTokens.success),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _identityCard() {
    return _Section(
      title: 'تحقق من هوية المشتري',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_verified)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BankTokens.successSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user, color: BankTokens.success),
                      SizedBox(width: 8),
                      Text(
                        'الهوية موثّقة',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: BankTokens.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تم التحقق من هوية المشتري لمعاملة #${_tx['transaction_number']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (_tx['identity_verified_at'] != null)
                    Text(
                      'الوقت: ${_tx['identity_verified_at']} · ${_tx['identity_verified_by'] ?? BankSeed.displayCode}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: BankTokens.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            )
          else ...[
            Text(
              'المشتري: ${_tx['buyer_name'] ?? '—'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('الهاتف المسجّل: ${_tx['buyer_phone'] ?? '—'}'),
            Text('معرف مدار: ${_tx['buyer_id'] ?? '—'}'),
            const SizedBox(height: 10),
            if (_otpStateLabel != null)
              Text(
                _otpStateLabel!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: BankTokens.primary,
                ),
              ),
            if (_maskedPhone != null)
              Text('أُرسل إلى: $_maskedPhone'),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: _busy ? null : _sendOtp,
              child: const Text('إرسال رمز التحقق'),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'أدخل رمز التحقق من المشتري',
                  border: OutlineInputBorder(),
                  helperText: 'لا يُعرض الرمز لموظف البنك',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _verifyOtp,
                style: FilledButton.styleFrom(
                  backgroundColor: BankTokens.primary,
                ),
                child: const Text('تأكيد الرمز'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _breakdownCard() {
    return _Section(
      title: 'التفصيل المالي',
      child: Column(
        children: [
          _MoneyRow('سعر العقار', _tx['property_price']),
          _MoneyRow('ضرائب المشتري', _tx['buyer_taxes']),
          _MoneyRow('رسوم مدار', _tx['madar_fees']),
          _MoneyRow('رسوم البنك', _tx['bank_fees']),
          const Divider(height: 20),
          _MoneyRow('المبلغ المطلوب', _required, bold: true),
          _MoneyRow('المودع', _deposited),
          _MoneyRow('المتبقي', _remaining, highlight: true),
        ],
      ),
    );
  }

  Widget _escrowCard() {
    return _Section(
      title: 'حساب الضمان',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tx['escrow_account_label']?.toString() ?? 'حساب ضمان مدار',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text('المرجع: ${_tx['escrow_reference'] ?? '—'}'),
          Text('حالة الإيداع: ${_statusAr(_tx['financial_status']?.toString() ?? '')}'),
          const SizedBox(height: 8),
          Text(
            _tx['release_condition']?.toString() ??
                'تبقى الأموال خاضعة لشروط الضمان وتُحرَّر وفق سير العمل المعتمد.',
            style: const TextStyle(
              fontSize: 12,
              color: BankTokens.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (_tx['is_agricultural'] == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BankTokens.warningSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'عقار زراعي — شرط التحرير يحدده تكوين المعاملة في الخلفية.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BankTokens.warning,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _depositCard() {
    if (_depositDone) {
      return _Section(
        title: 'الإيداع',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.task_alt, color: BankTokens.success),
                SizedBox(width: 8),
                Text(
                  'تم تأكيد الإيداع',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: BankTokens.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _lastReceipt != null
                  ? 'الإيصال: $_lastReceipt'
                  : 'الإيداع مسجّل مسبقاً.',
            ),
            const SizedBox(height: 8),
            const Text(
              'لا يمكن تأكيد نفس الإيداع مرتين.',
              style: TextStyle(
                fontSize: 12,
                color: BankTokens.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return _Section(
      title: 'تأكيد الإيداع',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_verified)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'يجب إكمال التحقق من هوية المشتري قبل تأكيد الإيداع.',
                style: TextStyle(
                  color: BankTokens.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          TextField(
            controller: _amountCtrl,
            enabled: _verified && !_busy,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'المبلغ المودع فعلياً (د.ع)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _refCtrl,
            enabled: _verified && !_busy,
            decoration: const InputDecoration(
              labelText: 'رقم المرجع البنكي',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: (_busy || !_verified) ? null : _confirmDeposit,
            style: FilledButton.styleFrom(
              backgroundColor: BankTokens.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              'تأكيد الإيداع',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineCard() {
    final auth = context.read<EmployeeAuthNotifier>();
    final events = auth.repository.isBankSeedSession
        ? BankSeed.timeline(_tx['id'].toString())
        : const <Map<String, dynamic>>[];
    if (events.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'الجدول الزمني',
      child: Column(
        children: [
          for (final e in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      e['time']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BankTokens.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Icon(Icons.circle, size: 8, color: BankTokens.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e['title']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          e['detail']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: BankTokens.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _statusAr(String s) {
    switch (s) {
      case 'awaiting_deposit':
        return 'بانتظار الإيداع';
      case 'awaiting_remaining':
        return 'بانتظار المتبقي';
      case 'deposit_confirmed':
        return 'تم تأكيد الإيداع';
      default:
        return s.replaceAll('_', ' ');
    }
  }

  String _fmt(num n) {
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.number,
    required this.status,
    required this.requiredAmount,
    this.propertyId,
    this.propertyTitle,
  });

  final String number;
  final String status;
  final double requiredAmount;
  final String? propertyId;
  final String? propertyTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BankTokens.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'رقم المعاملة',
                style: TextStyle(color: Color(0xFFA5BDFF), fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '#$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'المبلغ المطلوب للإيداع',
            style: TextStyle(color: Color(0xFFA5BDFF), fontSize: 12),
          ),
          Text(
            '${_fmt(requiredAmount)} د.ع',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (propertyId != null) ...[
            const SizedBox(height: 8),
            Text(
              'العقار: ${propertyTitle ?? ''} · $propertyId',
              style: const TextStyle(color: Color(0xFFD6E0FF), fontSize: 12),
            ),
          ],
        ],
      ),
    );
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BankTokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BankTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.value, {this.bold = false, this.highlight = false});

  final String label;
  final dynamic value;
  final bool bold;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final n = (value is num) ? value : num.tryParse('$value') ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold || highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? BankTokens.primary : BankTokens.onSurface,
              ),
            ),
          ),
          Text(
            '${_HeroCard._fmt(n)} د.ع',
            style: TextStyle(
              fontWeight: bold || highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? BankTokens.primary : BankTokens.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({
    required this.title,
    required this.name,
    this.id,
    this.phone,
    this.verified = false,
    this.showVerified = true,
  });

  final String title;
  final String name;
  final String? id;
  final String? phone;
  final bool verified;
  final bool showVerified;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BankTokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BankTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BankTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (id != null) Text('ID: $id', style: const TextStyle(fontSize: 12)),
          if (phone != null)
            Text(phone!, style: const TextStyle(fontSize: 12)),
          if (showVerified) ...[
            const SizedBox(height: 6),
            Text(
              verified ? 'موثّق' : 'غير مؤكد',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: verified ? BankTokens.success : BankTokens.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StagesCard extends StatelessWidget {
  const _StagesCard({required this.stages});

  final List stages;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BankTokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BankTokens.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مراحل المعاملة',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < stages.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    () {
                      final st = (stages[i] as Map)['state']?.toString();
                      if (st == 'done') return Icons.check_circle;
                      if (st == 'current') return Icons.radio_button_checked;
                      return Icons.radio_button_unchecked;
                    }(),
                    size: 18,
                    color: () {
                      final st = (stages[i] as Map)['state']?.toString();
                      if (st == 'done') return BankTokens.success;
                      if (st == 'current') return BankTokens.primary;
                      return BankTokens.outline;
                    }(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(i + 1).toString().padLeft(2, '0')} ${(stages[i] as Map)['label']}',
                    style: TextStyle(
                      fontWeight:
                          (stages[i] as Map)['state'] == 'current'
                              ? FontWeight.w800
                              : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
