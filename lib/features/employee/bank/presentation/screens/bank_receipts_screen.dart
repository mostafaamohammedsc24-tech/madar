import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../services/bank_seed.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../theme/bank_tokens.dart';

class BankReceiptsScreen extends StatefulWidget {
  const BankReceiptsScreen({super.key});

  @override
  State<BankReceiptsScreen> createState() => _BankReceiptsScreenState();
}

class _BankReceiptsScreenState extends State<BankReceiptsScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  String _filter = 'all';

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
    List<Map<String, dynamic>> list;
    if (auth.repository.isBankSeedSession) {
      list = BankSeed.receipts();
    } else {
      list = await auth.repository.listDepositReceipts();
    }
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _items;
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        final hay = [
          r['receipt_number'],
          r['transaction_number'],
          r['buyer_name'],
          r['property_id'],
          r['amount'],
        ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');
        return hay.contains(q);
      }).toList();
    }
    if (_filter == '7d') {
      final cut = DateTime.now().subtract(const Duration(days: 7));
      list = list.where((r) {
        final d = DateTime.tryParse(r['created_at']?.toString() ?? '');
        return d != null && d.isAfter(cut);
      }).toList();
    } else if (_filter == 'month') {
      final n = DateTime.now();
      list = list.where((r) {
        final d = DateTime.tryParse(r['created_at']?.toString() ?? '');
        return d != null && d.year == n.year && d.month == n.month;
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = _filtered;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'مركز الإيصالات',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'سجل التدقيق والإيصالات المالية',
            style: TextStyle(color: BankTokens.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'بحث برقم الإيصال أو المعاملة…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: BankTokens.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: BankTokens.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final f in [
                ('all', 'كل الإيصالات'),
                ('7d', 'آخر 7 أيام'),
                ('month', 'الشهر الحالي'),
              ])
                ChoiceChip(
                  label: Text(f.$2),
                  selected: _filter == f.$1,
                  onSelected: (_) => setState(() => _filter = f.$1),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'لا توجد إيصالات للعرض.',
                  style: TextStyle(color: BankTokens.onSurfaceVariant),
                ),
              ),
            )
          else
            ...list.map((r) {
              final number = r['receipt_number']?.toString() ?? '—';
              final amount = r['amount'];
              final tx = r['transaction_number']?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: BankTokens.card,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push(
                      '/employee/bank/receipt/$number',
                      extra: r,
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: BankTokens.successSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: BankTokens.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  number,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'TRX-$tx · ${r['buyer_name'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: BankTokens.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '${_fmt(amount)} ${r['currency'] ?? 'IQD'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: BankTokens.primary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.visibility_outlined,
                              color: BankTokens.onSurfaceVariant, size: 20),
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

  String _fmt(dynamic v) {
    final n = (v is num) ? v : num.tryParse('$v') ?? 0;
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
