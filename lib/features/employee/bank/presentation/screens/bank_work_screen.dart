import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../services/bank_seed.dart';
import '../../../core/domain/employee_models.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../theme/bank_tokens.dart';

/// Bank Work — verify transaction search + operational indicators.
class BankWorkScreen extends StatefulWidget {
  const BankWorkScreen({super.key});

  @override
  State<BankWorkScreen> createState() => _BankWorkScreenState();
}

class _BankWorkScreenState extends State<BankWorkScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  BankDashboardStats? _stats;
  List<Map<String, dynamic>> _queue = [];
  String? _searchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<EmployeeAuthNotifier>();
    setState(() => _loading = true);
    if (auth.repository.isBankSeedSession) {
      if (!mounted) return;
      setState(() {
        _stats = BankSeed.stats();
        _queue = BankSeed.transactions()
            .where((t) =>
                t['financial_status'] == 'awaiting_deposit' ||
                t['financial_status'] == 'awaiting_remaining')
            .toList();
        _loading = false;
      });
      return;
    }
    final stats = await auth.repository.bankDashboardStats();
    final txs = await auth.repository.listTransactions(limit: 40);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _queue = txs
          .where((t) {
            final s = t['financial_status']?.toString() ?? '';
            return s.contains('await') || s.contains('deposit');
          })
          .take(8)
          .toList();
      _loading = false;
    });
  }

  void _verifySearch() {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    final auth = context.read<EmployeeAuthNotifier>();
    Map<String, dynamic>? found;
    if (auth.repository.isBankSeedSession) {
      found = BankSeed.findTransaction(q);
      if (found != null) {
        BankSeed.audit(
          action: 'search_transaction',
          result: 'found',
          transactionId: found['id']?.toString(),
        );
      }
    }
    if (found == null) {
      setState(() => _searchError = 'لم يتم العثور على المعاملة.');
      return;
    }
    setState(() => _searchError = null);
    context.push(
      '/employee/bank/transaction/${found['id']}',
      extra: found,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _stats;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'مساحة العمل',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: BankTokens.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'تحقق من المعاملة، هوية المشتري، ثم سجّل الإيداع وأصدر الإيصال.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: BankTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
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
                  'تحقق من المعاملة',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: BankTokens.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'أدخل رقم المعاملة، العقار، أو هاتف المشتري',
                  style: TextStyle(
                    fontSize: 13,
                    color: BankTokens.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _verifySearch(),
                  decoration: InputDecoration(
                    hintText: 'مثال: 202600481 أو +964780…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: BankTokens.surfaceLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_searchError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _searchError!,
                    style: const TextStyle(
                      color: BankTokens.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _verifySearch,
                  style: FilledButton.styleFrom(
                    backgroundColor: BankTokens.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(
                    'فتح المعاملة',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'مؤشرات العمليات',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: BankTokens.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (s == null ||
              (s.pendingDeposits == 0 &&
                  s.awaitingOtp == 0 &&
                  s.completedDeposits == 0 &&
                  s.todaysDeposits == 0))
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BankTokens.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BankTokens.outlineVariant),
              ),
              child: const Text(
                'لا توجد عمليات بنكية معلّقة.',
                style: TextStyle(color: BankTokens.onSurfaceVariant),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(
                  label: 'قيد التحقق',
                  value: '${s.verificationRequired}',
                  icon: Icons.pending_actions,
                  color: BankTokens.warning,
                  soft: BankTokens.warningSoft,
                ),
                _StatChip(
                  label: 'بانتظار الإيداع',
                  value: '${s.pendingDeposits}',
                  icon: Icons.account_balance,
                  color: BankTokens.primary,
                  soft: const Color(0xFFE8EEF9),
                ),
                _StatChip(
                  label: 'إيداعات اليوم',
                  value: '${s.todaysDeposits}',
                  icon: Icons.today,
                  color: BankTokens.secondary,
                  soft: BankTokens.surfaceContainer,
                ),
                _StatChip(
                  label: 'مكتملة',
                  value: '${s.completedDeposits}',
                  icon: Icons.check_circle_outline,
                  color: BankTokens.success,
                  soft: BankTokens.successSoft,
                ),
              ],
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'إجراءات معلقة',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/employee/bank/transactions'),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          if (_queue.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'لا توجد معاملات تتطلب إجراءً الآن.',
                style: TextStyle(color: BankTokens.onSurfaceVariant),
              ),
            )
          else
            ..._queue.map((t) {
              final number = t['transaction_number']?.toString() ?? '—';
              final status = t['financial_status']?.toString() ?? '';
              final buyer = t['buyer_name']?.toString() ??
                  t['buyer_phone']?.toString() ??
                  '—';
              final amount = t['required_escrow_amount'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: BankTokens.card,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push(
                      '/employee/bank/transaction/${t['id']}',
                      extra: t,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: BankTokens.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EEF9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: BankTokens.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#$number',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '$buyer · ${_statusAr(status)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: BankTokens.onSurfaceVariant,
                                  ),
                                ),
                                if (amount != null)
                                  Text(
                                    _fmtMoney(amount),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: BankTokens.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left,
                              color: BankTokens.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
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
        return 'تم التأكيد';
      default:
        return s.replaceAll('_', ' ');
    }
  }

  String _fmtMoney(dynamic v) {
    final n = (v is num) ? v : num.tryParse(v.toString()) ?? 0;
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.soft,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 42) / 2;
    return SizedBox(
      width: w.clamp(140, 220),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BankTokens.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BankTokens.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: soft,
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
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: BankTokens.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
