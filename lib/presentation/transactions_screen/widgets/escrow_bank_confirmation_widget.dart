import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

/// Full escrow bank confirmation flow for Stage 4
/// Steps: Amount Review → OTP Verification → Bank Confirmation → Receipt
class EscrowBankConfirmationWidget extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onConfirmed;

  const EscrowBankConfirmationWidget({
    super.key,
    required this.transaction,
    required this.onConfirmed,
  });

  @override
  State<EscrowBankConfirmationWidget> createState() =>
      _EscrowBankConfirmationWidgetState();
}

class _EscrowBankConfirmationWidgetState
    extends State<EscrowBankConfirmationWidget>
    with TickerProviderStateMixin {
  int _step = 0; // 0=review, 1=otp, 2=confirming, 3=receipt
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _receiptNumber;
  DateTime? _confirmedAt;

  late AnimationController _checkController;
  late Animation<double> _checkScale;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  double get _totalAmount =>
      (widget.transaction['total_amount'] as num?)?.toDouble() ?? 0;
  double get _commission => _totalAmount * 0.01;
  static const double _serviceFee = 300000.0;
  double get _escrowTotal =>
      _totalAmount + (_commission * 2) + (_serviceFee * 2);

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _checkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)} مليون د.ع';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} ألف د.ع';
    }
    return '${amount.toStringAsFixed(0)} د.ع';
  }

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    setState(() => _step = 1);
    // Simulate OTP send
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم إرسال رمز التحقق إلى رقمك المسجل'),
        backgroundColor: const Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _otpFocusNodes[0].requestFocus();
    });
  }

  Future<void> _verifyOtpAndConfirm() async {
    if (_otpValue.length < 6) return;
    setState(() {
      _step = 2;
      _isLoading = true;
    });

    // Simulate bank confirmation delay
    await Future.delayed(const Duration(milliseconds: 2200));

    final txId = widget.transaction['id'] as String?;
    if (txId != null && txId != 'demo_txn_001') {
      try {
        await SupabaseService.instance.updateTransactionStage(
          txId,
          3,
          'completed',
        );
        await SupabaseService.instance.updateTransactionCurrentStage(txId, 4);
      } catch (_) {}
    }

    final now = DateTime.now();
    final receipt =
        'ESCROW-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';

    if (mounted) {
      setState(() {
        _isLoading = false;
        _step = 3;
        _receiptNumber = receipt;
        _confirmedAt = now;
      });
      _checkController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: switch (_step) {
        0 => _buildReviewStep(theme),
        1 => _buildOtpStep(theme),
        2 => _buildConfirmingStep(theme),
        3 => _buildReceiptStep(theme),
        _ => const SizedBox.shrink(),
      },
    );
  }

  // ─── Step 0: Amount Review ────────────────────────────────────────────────

  Widget _buildReviewStep(ThemeData theme) {
    return Container(
      key: const ValueKey('review'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D47A1).withAlpha(18),
            const Color(0xFF1565C0).withAlpha(8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withAlpha(20),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تأكيد الإيداع الضماني',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                      const Text(
                        'مصرف بغداد — حساب الضمان',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withAlpha(60)),
                  ),
                  child: const Text(
                    'في الانتظار',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fee breakdown
                _buildFeeRow(
                  theme,
                  icon: Icons.home_work,
                  label: 'قيمة العقار',
                  amount: _totalAmount,
                  color: theme.colorScheme.onSurface,
                  isBold: true,
                ),
                const Divider(height: 20),
                _buildFeeRow(
                  theme,
                  icon: Icons.percent,
                  label: 'عمولة المكاتبة (1% × 2)',
                  amount: _commission * 2,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildFeeRow(
                  theme,
                  icon: Icons.miscellaneous_services,
                  label: 'رسوم الخدمات (300 ألف × 2)',
                  amount: _serviceFee * 2,
                  color: Colors.orange,
                ),
                const Divider(height: 20),
                _buildFeeRow(
                  theme,
                  icon: Icons.savings,
                  label: 'إجمالي الإيداع الضماني',
                  amount: _escrowTotal,
                  color: const Color(0xFF1565C0),
                  isBold: true,
                  isTotal: true,
                ),
                const SizedBox(height: 16),

                // Bank account info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1565C0).withAlpha(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildBankInfoRow(
                        'رقم الحساب',
                        'IQ29NBIQ0000000000001234',
                      ),
                      const SizedBox(height: 6),
                      _buildBankInfoRow('اسم الحساب', 'مدار العقارية - ضمان'),
                      const SizedBox(height: 6),
                      _buildBankInfoRow(
                        'رقم المرجع',
                        widget.transaction['reference_number'] as String? ??
                            'MADAR-2026-001',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Info note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيتم تحرير الأموال فور صدور سند الملكية باسم المشتري وتأكيد المحامي المشرف',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.amber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendOtp,
                    icon: const Icon(Icons.verified_user, size: 18),
                    label: const Text(
                      'تأكيد الإيداع — إرسال رمز التحقق',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    bool isBold = false,
    bool isTotal = false,
  }) {
    return Container(
      padding: isTotal
          ? const EdgeInsets.symmetric(vertical: 10, horizontal: 12)
          : EdgeInsets.zero,
      decoration: isTotal
          ? BoxDecoration(
              color: const Color(0xFF1565C0).withAlpha(12),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isBold ? theme.colorScheme.onSurface : Colors.grey,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Step 1: OTP Verification ─────────────────────────────────────────────

  Widget _buildOtpStep(ThemeData theme) {
    return Container(
      key: const ValueKey('otp'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withAlpha(50)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms, color: Color(0xFF1565C0), size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'رمز التحقق',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'أدخل الرمز المرسل إلى رقمك المسجل لتأكيد الإيداع',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // OTP boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return Container(
                width: 44,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                    80,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _otpFocusNodes[i].hasFocus
                        ? const Color(0xFF1565C0)
                        : theme.dividerColor,
                    width: _otpFocusNodes[i].hasFocus ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _otpControllers[i],
                  focusNode: _otpFocusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && i < 5) {
                      _otpFocusNodes[i + 1].requestFocus();
                    } else if (val.isEmpty && i > 0) {
                      _otpFocusNodes[i - 1].requestFocus();
                    }
                    setState(() {});
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Demo hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'رمز تجريبي: 123456',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = 0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('رجوع'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _otpValue.length == 6
                      ? _verifyOtpAndConfirm
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'تأكيد الإيداع',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Confirming ───────────────────────────────────────────────────

  Widget _buildConfirmingStep(ThemeData theme) {
    return Container(
      key: const ValueKey('confirming'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withAlpha(40)),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'جاري التحقق من الإيداع',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'يتحقق موظف المصرف من الإيداع في حساب الضمان...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildConfirmingStep_row('التحقق من رمز OTP', true),
          _buildConfirmingStep_row('مطابقة المبلغ مع الصفقة', true),
          _buildConfirmingStep_row('تأكيد موظف المصرف', false),
          _buildConfirmingStep_row('إصدار وصل الإيداع', false),
        ],
      ),
    );
  }

  Widget _buildConfirmingStep_row(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: done
                ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                : SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xFF1565C0).withAlpha(120),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: done ? Colors.green : Colors.grey,
              fontWeight: done ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Receipt ──────────────────────────────────────────────────────

  Widget _buildReceiptStep(ThemeData theme) {
    final now = _confirmedAt ?? DateTime.now();
    return Container(
      key: const ValueKey('receipt'),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Success header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                ScaleTransition(
                  scale: _checkScale,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تم تأكيد الإيداع ✓',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'وصل رقم: ${_receiptNumber ?? '—'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Receipt body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Dashed separator
                _buildDashedDivider(),
                const SizedBox(height: 12),

                _buildReceiptLine(
                  'رقم الصفقة',
                  widget.transaction['reference_number'] as String? ??
                      'MADAR-2026-001',
                ),
                _buildReceiptLine(
                  'تاريخ الإيداع',
                  '${now.day}/${now.month}/${now.year} — ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                ),
                _buildReceiptLine(
                  'المودِع',
                  widget.transaction['buyer_name'] as String? ?? 'المشتري',
                ),
                _buildReceiptLine('المستفيد', 'مدار العقارية — حساب الضمان'),
                const SizedBox(height: 8),
                _buildDashedDivider(),
                const SizedBox(height: 8),
                _buildReceiptLine('قيمة العقار', _formatAmount(_totalAmount)),
                _buildReceiptLine(
                  'عمولة المكاتبة',
                  _formatAmount(_commission * 2),
                  valueColor: Colors.orange,
                ),
                _buildReceiptLine(
                  'رسوم الخدمات',
                  _formatAmount(_serviceFee * 2),
                  valueColor: Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildDashedDivider(),
                const SizedBox(height: 8),
                _buildReceiptLine(
                  'إجمالي الإيداع',
                  _formatAmount(_escrowTotal),
                  isBold: true,
                  valueColor: const Color(0xFF1565C0),
                ),
                const SizedBox(height: 8),
                _buildDashedDivider(),
                const SizedBox(height: 12),

                // Status note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الأموال محفوظة في حساب الضمان وستُحرَّر فور صدور السند باسم المشتري',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('جاري تحميل وصل الإيداع...'),
                              backgroundColor: const Color(0xFF1565C0),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text(
                          'تحميل الوصل',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onConfirmed,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text(
                          'المتابعة',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptLine(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(right: dashSpace),
              color: Colors.grey.withAlpha(60),
            ),
          ),
        );
      },
    );
  }
}
