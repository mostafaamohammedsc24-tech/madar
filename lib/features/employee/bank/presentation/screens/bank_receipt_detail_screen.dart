import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../services/bank_seed.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../theme/bank_tokens.dart';

/// Official Madar deposit receipt preview (immutable display).
class BankReceiptDetailScreen extends StatefulWidget {
  const BankReceiptDetailScreen({
    super.key,
    required this.receiptNumber,
    this.receipt,
  });

  final String receiptNumber;
  final Map<String, dynamic>? receipt;

  @override
  State<BankReceiptDetailScreen> createState() =>
      _BankReceiptDetailScreenState();
}

class _BankReceiptDetailScreenState extends State<BankReceiptDetailScreen> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<EmployeeAuthNotifier>();
      var data = widget.receipt;
      if (data == null && auth.repository.isBankSeedSession) {
        data = BankSeed.receiptByNumber(widget.receiptNumber);
      }
      data ??= {
        'receipt_number': widget.receiptNumber,
        'status': 'issued',
      };
      if (auth.repository.isBankSeedSession) {
        BankSeed.audit(
          action: 'view_receipt',
          result: 'ok',
          transactionId: data['transaction_id']?.toString(),
        );
      }
      setState(() => _data = data);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: BankTokens.background,
      appBar: AppBar(
        title: const Text('إيصال رسمي'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'طباعة',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاهز للطباعة من المتصفح')),
              );
            },
            icon: const Icon(Icons.print_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BankTokens.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BankTokens.outlineVariant),
              boxShadow: BankTokens.microDepth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'MADAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: BankTokens.primary,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  'منصة التكنولوجيا العقارية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: BankTokens.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'إيصال إيداع ضمان',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const Divider(height: 28),
                _row('رقم الإيصال', data['receipt_number']?.toString() ?? '—'),
                _row(
                  'رقم المعاملة',
                  '#${data['transaction_number'] ?? '—'}',
                ),
                _row('التاريخ', data['deposit_date']?.toString() ?? '—'),
                _row(
                  'الوقت',
                  (data['created_at']?.toString() ?? '—')
                      .split('T')
                      .last
                      .split('.')
                      .first,
                ),
                const SizedBox(height: 12),
                _row('المشتري', data['buyer_name']?.toString() ?? '—'),
                _row('البائع', data['seller_name']?.toString() ?? '—'),
                _row('العقار', data['property_title']?.toString() ?? '—'),
                _row('معرف العقار', data['property_id']?.toString() ?? '—'),
                _row('المكتب', data['office_name']?.toString() ?? '—'),
                const Divider(height: 28),
                const Text(
                  'التفاصيل المالية',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _row('المبلغ الأساسي', _money(data['property_price'])),
                _row('الضرائب', _money(data['buyer_taxes'])),
                _row('رسوم مدار', _money(data['madar_fees'])),
                _row('رسوم بنكية', _money(data['bank_fees'])),
                _row('مبلغ الإيداع', _money(data['amount']), bold: true),
                const Divider(height: 28),
                _row(
                  'مرجع الضمان',
                  data['escrow_reference']?.toString() ?? '—',
                ),
                _row(
                  'المرجع البنكي',
                  data['reference_number']?.toString() ?? '—',
                ),
                _row(
                  'حالة التحقق',
                  data['verification_status']?.toString() == 'verified'
                      ? 'موثّق'
                      : (data['status']?.toString() ?? '—'),
                ),
                _row(
                  'موظف البنك المعتمد',
                  '${data['bank_employee'] ?? '—'} · ${data['bank_employee_id'] ?? ''}',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BankTokens.surfaceLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'هذا الإيصال رقمي وغير قابل للتعديل. أي تصحيح يتم عبر سجل تصحيح/عكس وفق سير العمل المالي.',
                    style: TextStyle(
                      fontSize: 12,
                      color: BankTokens.onSurfaceVariant,
                      height: 1.4,
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

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: BankTokens.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: bold ? 15 : 13,
                color: bold ? BankTokens.primary : BankTokens.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(dynamic v) {
    if (v == null) return '—';
    final n = (v is num) ? v : num.tryParse('$v') ?? 0;
    final s = n.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      if (idx > 1 && idx % 3 == 1) buf.write(',');
    }
    return '${buf.toString()} د.ع';
  }
}
