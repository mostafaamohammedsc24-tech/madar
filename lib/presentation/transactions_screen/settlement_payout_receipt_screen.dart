import '../../core/app_export.dart';
import '../../core/layout/directional_layout.dart';

/// Settlement Payout Receipt Screen
/// Shows full fee breakdown and funds released to seller after deal closure
class SettlementPayoutReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const SettlementPayoutReceiptScreen({super.key, required this.transaction});

  @override
  State<SettlementPayoutReceiptScreen> createState() =>
      _SettlementPayoutReceiptScreenState();
}

class _SettlementPayoutReceiptScreenState
    extends State<SettlementPayoutReceiptScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _stampController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _stampScale;
  late Animation<double> _stampOpacity;

  double get _totalAmount =>
      (widget.transaction['total_amount'] as num?)?.toDouble() ?? 185000000.0;

  // Fee structure
  double get _brokerage => _totalAmount * 0.01; // 1% from seller
  double get _buyerBrokerage =>
      _totalAmount * 0.01; // 1% from buyer (already collected)
  static const double _serviceFee = 300000.0; // per party
  double get _taxAmount => _totalAmount * 0.025; // 2.5% tax estimate
  double get _bankFee => 150000.0; // bank escrow service fee
  double get _totalDeductions =>
      _brokerage + _serviceFee + _taxAmount + _bankFee;
  double get _netSellerPayout => _totalAmount - _totalDeductions;

  String get _receiptNumber {
    final ref = widget.transaction['reference_number'] as String? ?? '2026-001';
    return 'SETTLE-$ref';
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _stampScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.elasticOut),
    );
    _stampOpacity = CurvedAnimation(
      parent: _stampController,
      curve: Curves.easeIn,
    );

    _entranceController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _stampController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _stampController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(3)} مليون د.ع';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} ألف د.ع';
    }
    return '${amount.toStringAsFixed(0)} د.ع';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const DirectionalBackIcon(color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'وصل التسوية النهائية',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareReceipt,
            tooltip: 'مشاركة',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadReceipt,
            tooltip: 'تحميل',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSuccessBanner(theme),
                const SizedBox(height: 16),
                _buildReceiptCard(theme),
                const SizedBox(height: 16),
                _buildFeeBreakdownCard(theme),
                const SizedBox(height: 16),
                _buildPayoutCard(theme),
                const SizedBox(height: 16),
                _buildPartiesCard(theme),
                const SizedBox(height: 16),
                _buildDocumentsCard(theme),
                const SizedBox(height: 24),
                _buildActionButtons(theme),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Success Banner ───────────────────────────────────────────────────────

  Widget _buildSuccessBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تمت الصفقة بنجاح 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.transaction['reference_number'] as String? ??
                      'MADAR-2026-001',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'تم تحويل المستحقات للبائع',
                    style: TextStyle(
                      color: Colors.white.withAlpha(230),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ScaleTransition(
            scale: _stampScale,
            child: FadeTransition(
              opacity: _stampOpacity,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(80),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Receipt Header Card ──────────────────────────────────────────────────

  Widget _buildReceiptCard(ThemeData theme) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وصل التسوية المالية',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _receiptNumber,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
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
                  color: Colors.green.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withAlpha(50)),
                ),
                child: const Text(
                  'مكتمل',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _buildMetaRow('تاريخ الإصدار', '${now.day}/${now.month}/${now.year}'),
          _buildMetaRow(
            'الوقت',
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          ),
          _buildMetaRow(
            'نوع الصفقة',
            _getTransactionTypeLabel(
              widget.transaction['transaction_type'] as String? ?? 'sale',
            ),
          ),
          _buildMetaRow(
            'العقار',
            widget.transaction['property_address_snapshot'] as String? ??
                'شارع النضال، الكرادة، بغداد',
          ),
        ],
      ),
    );
  }

  // ─── Fee Breakdown Card ───────────────────────────────────────────────────

  Widget _buildFeeBreakdownCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calculate, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'تفصيل الرسوم والمستحقات',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Total amount (incoming)
                _buildFeeLineItem(
                  theme,
                  icon: Icons.home_work,
                  label: 'قيمة العقار الإجمالية',
                  amount: _totalAmount,
                  color: theme.colorScheme.onSurface,
                  isPositive: true,
                  isBold: true,
                ),
                const SizedBox(height: 12),
                _buildSectionLabel(theme, 'المستحقات المخصومة'),
                const SizedBox(height: 8),

                // Deductions
                _buildFeeLineItem(
                  theme,
                  icon: Icons.percent,
                  label: 'عمولة المكاتبة (1%)',
                  sublabel: 'من البائع',
                  amount: _brokerage,
                  color: Colors.orange,
                  isPositive: false,
                ),
                const SizedBox(height: 6),
                _buildFeeLineItem(
                  theme,
                  icon: Icons.miscellaneous_services,
                  label: 'رسوم الخدمات الإلكترونية',
                  sublabel: '300,000 د.ع',
                  amount: _serviceFee,
                  color: Colors.orange,
                  isPositive: false,
                ),
                const SizedBox(height: 6),
                _buildFeeLineItem(
                  theme,
                  icon: Icons.account_balance,
                  label: 'الضرائب العقارية',
                  sublabel: '2.5% تقديري',
                  amount: _taxAmount,
                  color: const Color(0xFFD32F2F),
                  isPositive: false,
                ),
                const SizedBox(height: 6),
                _buildFeeLineItem(
                  theme,
                  icon: Icons.savings,
                  label: 'رسوم خدمة الضمان المصرفي',
                  sublabel: 'مصرف بغداد',
                  amount: _bankFee,
                  color: const Color(0xFF1565C0),
                  isPositive: false,
                ),
                const SizedBox(height: 12),

                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        theme.dividerColor,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Total deductions
                _buildFeeLineItem(
                  theme,
                  icon: Icons.remove_circle,
                  label: 'إجمالي المخصومات',
                  amount: _totalDeductions,
                  color: const Color(0xFFD32F2F),
                  isPositive: false,
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeLineItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    String? sublabel,
    required double amount,
    required Color color,
    required bool isPositive,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
        ),
        Text(
          '${isPositive ? '+' : '-'} ${_formatAmount(amount)}',
          style: TextStyle(
            fontSize: isBold ? 13 : 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Net Payout Card ──────────────────────────────────────────────────────

  Widget _buildPayoutCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
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
                      'صافي المبلغ المحوَّل للبائع',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatAmount(_netSellerPayout),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم تحويل المبلغ إلى حساب البائع: ${widget.transaction['seller_name'] as String? ?? 'البائع'} — ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Parties Card ─────────────────────────────────────────────────────────

  Widget _buildPartiesCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'أطراف الصفقة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPartyRow(
            theme,
            icon: Icons.person,
            role: 'البائع',
            name: widget.transaction['seller_name'] as String? ?? 'البائع',
            detail: 'استلم: ${_formatAmount(_netSellerPayout)}',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildPartyRow(
            theme,
            icon: Icons.person_outline,
            role: 'المشتري',
            name: widget.transaction['buyer_name'] as String? ?? 'المشتري',
            detail:
                'أودع: ${_formatAmount(_totalAmount + _buyerBrokerage + _serviceFee)}',
            color: AppTheme.primary,
          ),
          const SizedBox(height: 8),
          _buildPartyRow(
            theme,
            icon: Icons.gavel,
            role: 'المحامي المشرف',
            name: 'أ. كريم الجبوري',
            detail: 'أغلق الصفقة رسمياً',
            color: const Color(0xFF7B1FA2),
          ),
          const SizedBox(height: 8),
          _buildPartyRow(
            theme,
            icon: Icons.account_balance,
            role: 'موظف المصرف',
            name: 'م. سامر العبيدي',
            detail: 'أكّد تحرير الأموال',
            color: const Color(0xFF1565C0),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyRow(
    ThemeData theme, {
    required IconData icon,
    required String role,
    required String name,
    required String detail,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          detail,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Documents Card ───────────────────────────────────────────────────────

  Widget _buildDocumentsCard(ThemeData theme) {
    final docs = [
      _DocItem(
        icon: Icons.picture_as_pdf,
        label: 'عقد البيع الموقع',
        filename:
            'contract_${widget.transaction['reference_number'] ?? '001'}.pdf',
        color: const Color(0xFFD32F2F),
      ),
      _DocItem(
        icon: Icons.home_work,
        label: 'سند الملكية الجديد',
        filename: 'deed_${widget.transaction['reference_number'] ?? '001'}.pdf',
        color: Colors.green,
      ),
      _DocItem(
        icon: Icons.receipt_long,
        label: 'وصل التسوية المالية',
        filename:
            'settlement_${widget.transaction['reference_number'] ?? '001'}.pdf',
        color: AppTheme.primary,
      ),
      _DocItem(
        icon: Icons.savings,
        label: 'وصل الإيداع الضماني',
        filename:
            'escrow_${widget.transaction['reference_number'] ?? '001'}.pdf',
        color: const Color(0xFF1565C0),
      ),
      _DocItem(
        icon: Icons.verified,
        label: 'شهادة إتمام الصفقة',
        filename:
            'certificate_${widget.transaction['reference_number'] ?? '001'}.pdf',
        color: const Color(0xFF7B1FA2),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_special, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'وثائق الصفقة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _downloadAll,
                icon: const Icon(Icons.download_for_offline, size: 14),
                label: const Text('تحميل الكل', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...docs.map((doc) => _buildDocRow(theme, doc)),
        ],
      ),
    );
  }

  Widget _buildDocRow(ThemeData theme, _DocItem doc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: doc.color.withAlpha(15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(doc.icon, color: doc.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  doc.filename,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.download, color: doc.color, size: 18),
            onPressed: () => _downloadDoc(doc.label),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ───────────────────────────────────────────────────────

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _downloadReceipt,
            icon: const Icon(Icons.download, size: 18),
            label: const Text(
              'تحميل وصل التسوية الكامل',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _shareReceipt,
            icon: const Icon(Icons.share, size: 18),
            label: const Text(
              'مشاركة الوصل',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(color: Colors.green),
              foregroundColor: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'sale':
        return 'بيع عقاري';
      case 'rent':
        return 'إيجار';
      case 'agricultural':
        return 'بيع زراعي';
      default:
        return type;
    }
  }

  void _downloadReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('جاري تحميل وصل التسوية الكامل...'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('جاري مشاركة الوصل...'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _downloadAll() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('جاري تحميل جميع الوثائق...'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _downloadDoc(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري تحميل: $label'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _DocItem {
  final IconData icon;
  final String label;
  final String filename;
  final Color color;

  const _DocItem({
    required this.icon,
    required this.label,
    required this.filename,
    required this.color,
  });
}
