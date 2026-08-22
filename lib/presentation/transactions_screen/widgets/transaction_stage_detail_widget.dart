import '../../../core/app_export.dart';
import '../../../core/layout/directional_layout.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/electronic_signature_pad.dart';
import '../../transactions_screen/settlement_payout_receipt_screen.dart';
import './escrow_bank_confirmation_widget.dart';

class TransactionStageDetailWidget extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final List<Map<String, dynamic>> stages;
  final int currentStage;
  final int selectedStageIndex;
  final VoidCallback onActionComplete;

  const TransactionStageDetailWidget({
    super.key,
    required this.transaction,
    required this.stages,
    required this.currentStage,
    required this.selectedStageIndex,
    required this.onActionComplete,
  });

  @override
  State<TransactionStageDetailWidget> createState() =>
      _TransactionStageDetailWidgetState();
}

class _TransactionStageDetailWidgetState
    extends State<TransactionStageDetailWidget>
    with SingleTickerProviderStateMixin {
  bool _isActing = false;
  bool _hasSigned = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Map<String, dynamic> get _selectedStage =>
      widget.stages.isNotEmpty &&
          widget.selectedStageIndex < widget.stages.length
      ? widget.stages[widget.selectedStageIndex]
      : {};

  String get _stageStatus => _selectedStage['status'] as String? ?? 'pending';
  bool get _isCurrentStage => widget.selectedStageIndex == widget.currentStage;
  bool get _isCompleted => _stageStatus == 'completed';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.stages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStageHeader(theme),
          const SizedBox(height: 16),
          _buildStageContent(theme),
          const SizedBox(height: 16),
          if (_isCurrentStage && !_isCompleted) _buildActionArea(theme),
        ],
      ),
    );
  }

  Widget _buildStageHeader(ThemeData theme) {
    final iconName = _selectedStage['icon'] as String? ?? 'info';
    final title = _selectedStage['title'] as String? ?? '';
    final completedAt = _selectedStage['completed_at'] as String?;

    Color stageColor = _isCompleted
        ? AppTheme.success
        : _isCurrentStage
        ? AppTheme.primary
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [stageColor.withAlpha(25), stageColor.withAlpha(8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stageColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: stageColor.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isCompleted ? Icons.check_circle : _getIcon(iconName),
              color: stageColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المرحلة ${widget.selectedStageIndex + 1} من 6',
                  style: TextStyle(
                    fontSize: 11,
                    color: stageColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (completedAt != null)
                  Text(
                    'اكتملت: ${_formatDate(completedAt)}',
                    style: TextStyle(fontSize: 12, color: AppTheme.success),
                  ),
              ],
            ),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label;
    Color color;
    switch (_stageStatus) {
      case 'completed':
        label = 'مكتملة';
        color = AppTheme.success;
        break;
      case 'in_progress':
        label = 'جارية';
        color = AppTheme.primary;
        break;
      default:
        label = 'قادمة';
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStageContent(ThemeData theme) {
    switch (widget.selectedStageIndex) {
      case 0:
        return _buildIdentityVerificationContent(theme);
      case 1:
        return _buildDocumentsContent(theme);
      case 2:
        return _buildContractContent(theme);
      case 3:
        return _buildEscrowContent(theme);
      case 4:
        return _buildOwnershipTransferContent(theme);
      case 5:
        return _buildSettlementContent(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── STAGE 1: Identity Verification ──────────────────────────────────────

  Widget _buildIdentityVerificationContent(ThemeData theme) {
    return Column(
      children: [
        _buildInfoCard(
          theme,
          title: 'التحقق من هوية الطرفين',
          items: [
            _InfoItem(
              icon: Icons.person,
              label: 'البائع',
              value: widget.transaction['seller_name'] as String? ?? 'البائع',
              status: _isCompleted ? 'verified' : 'pending',
            ),
            _InfoItem(
              icon: Icons.person_outline,
              label: 'المشتري',
              value: widget.transaction['buyer_name'] as String? ?? 'المشتري',
              status: _isCompleted ? 'verified' : 'pending',
            ),
            _InfoItem(
              icon: Icons.face_retouching_natural,
              label: 'التحقق البيومتري',
              value: _isCompleted ? 'تم التحقق من الوجه' : 'مطلوب',
              status: _isCompleted ? 'verified' : 'pending',
            ),
            _InfoItem(
              icon: Icons.badge,
              label: 'الهوية الوطنية',
              value: _isCompleted ? 'تم التحقق' : 'مطلوب رفع الهوية',
              status: _isCompleted ? 'verified' : 'pending',
            ),
          ],
          note:
              'يتم التحقق من هوية كلا الطرفين باستخدام الهوية الوطنية والتحقق البيومتري قبل بدء أي إجراء',
        ),
        const SizedBox(height: 12),
        _buildNotificationChannelCard(
          theme,
          channels: [
            _NotifChannel(
              icon: Icons.gavel,
              label: 'المحامي',
              name: 'أ. كريم الجبوري',
              status: 'تم الإشعار بالصفقة الجديدة',
              color: const Color(0xFF7B1FA2),
            ),
          ],
          stageLabel: 'مرحلة التحقق من الهوية',
        ),
      ],
    );
  }

  // ─── STAGE 2: Documents Upload ────────────────────────────────────────────

  Widget _buildDocumentsContent(ThemeData theme) {
    return Column(
      children: [
        _buildInfoCard(
          theme,
          title: 'المستمسكات المطلوبة',
          items: [
            _InfoItem(
              icon: Icons.badge,
              label: 'الهوية الوطنية',
              value: 'مطلوب من الطرفين',
              status: _isCompleted ? 'verified' : 'pending',
            ),
            _InfoItem(
              icon: Icons.home_work,
              label: 'سند الملكية الأصلي',
              value: 'مطلوب من البائع',
              status: _isCompleted ? 'verified' : 'pending',
            ),
            _InfoItem(
              icon: Icons.account_balance,
              label: 'إثبات مصدر المال',
              value: 'مطلوب من المشتري',
              status: _isCompleted ? 'verified' : 'pending',
            ),
            _InfoItem(
              icon: Icons.receipt_long,
              label: 'إيصال دفع الضرائب',
              value: 'مطلوب من البائع',
              status: _isCompleted ? 'verified' : 'pending',
            ),
          ],
          note: 'يحدد المحامي المستمسكات الإضافية حسب نوع العقار والموقع',
        ),
        const SizedBox(height: 12),
        _buildDocumentUploadArea(theme),
        const SizedBox(height: 12),
        _buildNotificationChannelCard(
          theme,
          channels: [
            _NotifChannel(
              icon: Icons.gavel,
              label: 'المحامي',
              name: 'أ. كريم الجبوري',
              status: 'تم استلام المستمسكات للمراجعة',
              color: const Color(0xFF7B1FA2),
            ),
          ],
          stageLabel: 'مرحلة رفع المستمسكات',
        ),
      ],
    );
  }

  Widget _buildDocumentUploadArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withAlpha(40),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'رفع المستمسكات',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUploadButton(
                  theme,
                  icon: Icons.badge,
                  label: 'الهوية الوطنية',
                  isUploaded: _isCompleted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUploadButton(
                  theme,
                  icon: Icons.home_work,
                  label: 'سند الملكية',
                  isUploaded: _isCompleted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildUploadButton(
                  theme,
                  icon: Icons.account_balance,
                  label: 'إثبات المال',
                  isUploaded: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUploadButton(
                  theme,
                  icon: Icons.receipt_long,
                  label: 'إيصال الضرائب',
                  isUploaded: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool isUploaded,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جاري فتح معرض الصور لرفع: $label'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isUploaded
              ? AppTheme.success.withAlpha(15)
              : AppTheme.primary.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded
                ? AppTheme.success.withAlpha(60)
                : AppTheme.primary.withAlpha(30),
          ),
        ),
        child: Column(
          children: [
            Icon(
              isUploaded ? Icons.check_circle : icon,
              color: isUploaded ? AppTheme.success : AppTheme.primary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isUploaded ? AppTheme.success : AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              isUploaded ? 'تم الرفع' : 'اضغط للرفع',
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STAGE 3: Contract & Signature ────────────────────────────────────────

  Widget _buildContractContent(ThemeData theme) {
    final amount = widget.transaction['total_amount'] as double? ?? 0;
    return Column(
      children: [
        _buildInfoCard(
          theme,
          title: 'عقد البيع العقاري',
          items: [
            _InfoItem(
              icon: Icons.gavel,
              label: 'نوع العقد',
              value: 'عقد بيع عقاري رسمي',
              status: 'info',
            ),
            _InfoItem(
              icon: Icons.attach_money,
              label: 'قيمة العقد',
              value: _formatAmount(amount),
              status: 'info',
            ),
            _InfoItem(
              icon: Icons.location_on,
              label: 'العقار',
              value:
                  widget.transaction['property_address_snapshot'] as String? ??
                  'العقار',
              status: 'info',
            ),
            _InfoItem(
              icon: Icons.draw,
              label: 'التوقيع الإلكتروني',
              value: _isCompleted || _hasSigned
                  ? 'تم التوقيع من الطرفين'
                  : 'في انتظار التوقيع',
              status: _isCompleted || _hasSigned ? 'verified' : 'pending',
            ),
          ],
          note:
              'يتم إرسال العقد من المحامي كملف PDF للطرفين للمراجعة والتوقيع الإلكتروني',
        ),
        const SizedBox(height: 12),
        _buildContractPreviewCard(theme),
        const SizedBox(height: 12),
        if (!_isCompleted && !_hasSigned)
          ElectronicSignaturePad(
            onDone: () => setState(() => _hasSigned = true),
          ),
        const SizedBox(height: 12),
        _buildNotificationChannelCard(
          theme,
          channels: [
            _NotifChannel(
              icon: Icons.gavel,
              label: 'المحامي',
              name: 'أ. كريم الجبوري',
              status: _isCompleted
                  ? 'تم التوقيع من الطرفين - العقد مكتمل'
                  : 'في انتظار توقيع الطرفين',
              color: const Color(0xFF7B1FA2),
            ),
          ],
          stageLabel: 'مرحلة العقد والتوقيع',
        ),
      ],
    );
  }

  Widget _buildContractPreviewCard(ThemeData theme) {
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Color(0xFFD32F2F),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عقد البيع العقاري',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'MADAR-CONTRACT-${widget.transaction['reference_number'] ?? '2026-001'}.pdf',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('جاري تحميل العقد...'),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('تحميل', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContractLine(
                  'البائع:',
                  widget.transaction['seller_name'] as String? ?? 'البائع',
                ),
                _buildContractLine(
                  'المشتري:',
                  widget.transaction['buyer_name'] as String? ?? 'المشتري',
                ),
                _buildContractLine(
                  'العقار:',
                  widget.transaction['property_address_snapshot'] as String? ??
                      '—',
                ),
                _buildContractLine(
                  'المبلغ:',
                  _formatAmount(
                    widget.transaction['total_amount'] as double? ?? 0,
                  ),
                ),
                _buildContractLine(
                  'التاريخ:',
                  _formatDate(
                    widget.transaction['created_at'] as String? ?? '',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── STAGE 4: Escrow Deposit ──────────────────────────────────────────────

  Widget _buildEscrowContent(ThemeData theme) {
    if (_isCompleted) {
      // Show completed state
      return Column(
        children: [
          _buildInfoCard(
            theme,
            title: 'حساب الضمان - مصرف بغداد',
            items: [
              _InfoItem(
                icon: Icons.savings,
                label: 'حالة الإيداع',
                value: 'تم الإيداع والتأكيد ✓',
                status: 'verified',
              ),
              _InfoItem(
                icon: Icons.account_balance,
                label: 'الحساب',
                value: 'IQ29NBIQ0000000000001234',
                status: 'info',
              ),
              _InfoItem(
                icon: Icons.lock,
                label: 'الأموال',
                value: 'محفوظة في حساب الضمان',
                status: 'verified',
              ),
            ],
            note: 'سيتم تحرير الأموال فور صدور السند باسم المشتري',
          ),
          const SizedBox(height: 12),
          _buildNotificationChannelCard(
            theme,
            channels: [
              _NotifChannel(
                icon: Icons.account_balance,
                label: 'موظف المصرف',
                name: 'م. سامر العبيدي',
                status: 'تم تأكيد الإيداع في حساب الضمان',
                color: const Color(0xFF1565C0),
              ),
            ],
            stageLabel: 'مرحلة الإيداع الضماني',
          ),
        ],
      );
    }

    // Show full confirmation flow
    return EscrowBankConfirmationWidget(
      transaction: widget.transaction,
      onConfirmed: () {
        widget.onActionComplete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تأكيد الإيداع الضماني بنجاح ✓'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEscrowBankCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withAlpha(20),
            const Color(0xFF0D47A1).withAlpha(10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1565C0).withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF1565C0),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مصرف بغداد - حساب الضمان',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'رقم الحساب: IQ29NBIQ0000000000001234',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(60),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Color(0xFF1565C0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سيتم تحرير الأموال فور صدور السند باسم المشتري وتأكيد المحامي',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBankStatusChip(
                  icon: Icons.person,
                  label: 'المشتري',
                  status: _isCompleted ? 'أودع' : 'لم يودع',
                  isOk: _isCompleted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBankStatusChip(
                  icon: Icons.verified_user,
                  label: 'موظف المصرف',
                  status: _isCompleted ? 'أكّد' : 'ينتظر',
                  isOk: _isCompleted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankStatusChip({
    required IconData icon,
    required String label,
    required String status,
    required bool isOk,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isOk
            ? AppTheme.success.withAlpha(15)
            : Colors.grey.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOk
              ? AppTheme.success.withAlpha(60)
              : Colors.grey.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isOk ? AppTheme.success : Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOk ? AppTheme.success : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STAGE 5: Ownership Transfer ─────────────────────────────────────────

  Widget _buildOwnershipTransferContent(ThemeData theme) {
    return Column(
      children: [
        _buildInfoCard(
          theme,
          title: 'نقل الملكية',
          items: [
            _InfoItem(
              icon: Icons.account_balance,
              label: 'الجهة المختصة',
              value: 'دائرة التسجيل العقاري',
              status: 'info',
            ),
            _InfoItem(
              icon: Icons.person_pin,
              label: 'المحامي المشرف',
              value: 'يمشي بالإجراءات نيابة عنكم',
              status: 'info',
            ),
            _InfoItem(
              icon: Icons.receipt_long,
              label: 'تسديد الضرائب',
              value: _isCompleted ? 'تم التسديد' : 'جارٍ التسديد',
              status: _isCompleted ? 'verified' : 'pending',
            ),
            _InfoItem(
              icon: Icons.upload_file,
              label: 'رفع إثبات النقل',
              value: _isCompleted ? 'تم الرفع والتحقق' : 'في انتظار الإجراءات',
              status: _isCompleted ? 'verified' : 'pending',
            ),
          ],
          note: 'الإجراء حضوري حالياً - سيصبح إلكترونياً مع الاستثمار الحكومي',
        ),
        const SizedBox(height: 12),
        _buildOwnershipLoadingCard(theme),
        const SizedBox(height: 12),
        _buildNotificationChannelCard(
          theme,
          channels: [
            _NotifChannel(
              icon: Icons.gavel,
              label: 'المحامي',
              name: 'أ. كريم الجبوري',
              status: _isCompleted
                  ? 'تم إتمام إجراءات نقل الملكية'
                  : 'يجري إجراءات نقل الملكية',
              color: const Color(0xFF7B1FA2),
            ),
            _NotifChannel(
              icon: Icons.account_balance,
              label: 'موظف المصرف',
              name: 'م. سامر العبيدي',
              status: 'في انتظار صدور السند لتحرير الأموال',
              color: const Color(0xFF1565C0),
            ),
          ],
          stageLabel: 'مرحلة نقل الملكية',
        ),
      ],
    );
  }

  Widget _buildOwnershipLoadingCard(ThemeData theme) {
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
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gavel,
                    color: Color(0xFF7B1FA2),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المحامي يجري الإجراءات',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _isCompleted
                          ? 'تمت جميع الإجراءات بنجاح'
                          : 'يرجى الانتظار - سيتم إشعاركم عند الانتهاء',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (!_isCompleted)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF7B1FA2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildOwnershipStep('تسديد الضرائب العقارية', _isCompleted),
          _buildOwnershipStep('تقديم طلب نقل الملكية', _isCompleted),
          _buildOwnershipStep('مراجعة دائرة التسجيل', false),
          _buildOwnershipStep('استلام السند الجديد', false),
        ],
      ),
    );
  }

  Widget _buildOwnershipStep(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: done ? AppTheme.success : Colors.grey.withAlpha(100),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: done ? AppTheme.success : Colors.grey,
              fontWeight: done ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── STAGE 6: Settlement & Close ─────────────────────────────────────────

  Widget _buildSettlementContent(ThemeData theme) {
    final amount = widget.transaction['total_amount'] as double? ?? 0;
    final commission = amount * 0.01;
    const serviceFee = 300000.0;
    final netAmount = amount - commission - serviceFee;

    return Column(
      children: [
        _buildInfoCard(
          theme,
          title: 'التسوية النهائية وإغلاق الصفقة',
          items: [
            _InfoItem(
              icon: Icons.attach_money,
              label: 'المبلغ الإجمالي',
              value: _formatAmount(amount),
              status: 'info',
            ),
            _InfoItem(
              icon: Icons.remove_circle_outline,
              label: 'عمولة المكاتبة (1%)',
              value: _formatAmount(commission),
              status: 'info',
            ),
            _InfoItem(
              icon: Icons.remove_circle_outline,
              label: 'رسوم الخدمات',
              value: _formatAmount(serviceFee),
              status: 'info',
            ),
            _InfoItem(
              icon: Icons.account_balance_wallet,
              label: 'صافي البائع',
              value: _formatAmount(netAmount),
              status: _isCompleted ? 'verified' : 'pending',
            ),
          ],
          note: 'يتم إصدار وصل تلقائي شامل لجميع التفاصيل المالية',
        ),
        const SizedBox(height: 12),
        _buildSettlementDocumentsCard(theme),
        const SizedBox(height: 12),
        _buildNotificationChannelCard(
          theme,
          channels: [
            _NotifChannel(
              icon: Icons.account_balance,
              label: 'موظف المصرف',
              name: 'م. سامر العبيدي',
              status: _isCompleted
                  ? 'تم تحرير الأموال للبائع'
                  : 'في انتظار رفع السند لتحرير الأموال',
              color: const Color(0xFF1565C0),
            ),
            _NotifChannel(
              icon: Icons.gavel,
              label: 'المحامي',
              name: 'أ. كريم الجبوري',
              status: _isCompleted
                  ? 'تم إغلاق الصفقة رسمياً'
                  : 'يراجع السند ويؤكد اكتمال الصفقة',
              color: const Color(0xFF7B1FA2),
            ),
          ],
          stageLabel: 'مرحلة التسوية النهائية',
        ),
        if (_isCompleted) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettlementPayoutReceiptScreen(
                      transaction: widget.transaction,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text(
                'عرض وصل التسوية الكامل',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
      ],
    );
  }

  Widget _buildSettlementDocumentsCard(ThemeData theme) {
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
                'وثائق الصفقة المحفوظة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDocumentRow(
            theme,
            icon: Icons.picture_as_pdf,
            label: 'عقد البيع الموقع',
            color: const Color(0xFFD32F2F),
            isReady: _isCompleted,
          ),
          _buildDocumentRow(
            theme,
            icon: Icons.home_work,
            label: 'سند الملكية الجديد',
            color: AppTheme.success,
            isReady: _isCompleted,
          ),
          _buildDocumentRow(
            theme,
            icon: Icons.receipt_long,
            label: 'وصل التسوية المالية',
            color: AppTheme.primary,
            isReady: _isCompleted,
          ),
          _buildDocumentRow(
            theme,
            icon: Icons.verified,
            label: 'شهادة إتمام الصفقة',
            color: const Color(0xFF7B1FA2),
            isReady: _isCompleted,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isReady,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isReady)
            IconButton(
              icon: Icon(Icons.download, color: AppTheme.primary, size: 18),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('جاري تحميل: $label'),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'قريباً',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // ─── NOTIFICATION CHANNELS ────────────────────────────────────────────────

  Widget _buildNotificationChannelCard(
    ThemeData theme, {
    required List<_NotifChannel> channels,
    required String stageLabel,
  }) {
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
              Icon(
                Icons.notifications_active,
                color: AppTheme.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'قنوات الإشعار - $stageLabel',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...channels.map((ch) => _buildChannelRow(theme, ch)),
        ],
      ),
    );
  }

  Widget _buildChannelRow(ThemeData theme, _NotifChannel channel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: channel.color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(channel.icon, color: channel.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      channel.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: channel.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      channel.name,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  channel.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTION AREA ──────────────────────────────────────────────────────────

  Widget _buildActionArea(ThemeData theme) {
    if (widget.selectedStageIndex == 2 && !_hasSigned) {
      return const SizedBox.shrink(); // Signature area handles its own button
    }

    String label;
    IconData icon;
    switch (widget.selectedStageIndex) {
      case 0:
        label = 'تأكيد التحقق من الهوية';
        icon = Icons.verified_user;
        break;
      case 1:
        label = 'تأكيد رفع المستمسكات';
        icon = Icons.upload_file;
        break;
      case 2:
        label = 'إرسال للمحامي للمراجعة';
        icon = Icons.send;
        break;
      case 3:
        label = 'تأكيد الإيداع في حساب الضمان';
        icon = Icons.savings;
        break;
      case 4:
        label = 'رفع إثبات نقل الملكية';
        icon = Icons.upload;
        break;
      case 5:
        label = 'رفع السند وإغلاق الصفقة';
        icon = Icons.check_circle;
        break;
      default:
        label = 'متابعة';
        icon = Icons.arrow_forward;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isActing ? null : _handleAction,
        icon: _isActing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : DirectionalIcon(icon: icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _handleAction() async {
    setState(() => _isActing = true);
    try {
      final txId = widget.transaction['id'] as String?;
      if (txId != null && txId != 'demo_txn_001') {
        await SupabaseService.instance.updateTransactionStage(
          txId,
          widget.selectedStageIndex,
          'completed',
        );
        if (widget.selectedStageIndex < 5) {
          await SupabaseService.instance.updateTransactionCurrentStage(
            txId,
            widget.selectedStageIndex + 1,
          );
        }
      }
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _isActing = false);
        widget.onActionComplete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إكمال المرحلة ${widget.selectedStageIndex + 1} بنجاح ✓',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ، يرجى المحاولة مرة أخرى'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard(
    ThemeData theme, {
    required String title,
    required List<_InfoItem> items,
    String? note,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => _buildInfoRow(theme, item)),
          if (note != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, _InfoItem item) {
    Color statusColor;
    IconData statusIcon;
    switch (item.status) {
      case 'verified':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = AppTheme.primary;
        statusIcon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  item.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 16),
        ],
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'verified_user':
        return Icons.verified_user;
      case 'description':
        return Icons.description;
      case 'gavel':
        return Icons.gavel;
      case 'savings':
        return Icons.savings;
      case 'transfer_within_a_station':
        return Icons.transfer_within_a_station;
      case 'receipt':
        return Icons.receipt;
      default:
        return Icons.circle;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} مليون د.ع';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} ألف د.ع';
    }
    return '${amount.toStringAsFixed(0)} د.ع';
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final String status;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });
}

class _NotifChannel {
  final IconData icon;
  final String label;
  final String name;
  final String status;
  final Color color;

  const _NotifChannel({
    required this.icon,
    required this.label,
    required this.name,
    required this.status,
    required this.color,
  });
}
