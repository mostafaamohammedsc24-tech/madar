import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../theme/bank_tokens.dart';

class BankTransactionsScreen extends StatefulWidget {
  const BankTransactionsScreen({super.key});

  @override
  State<BankTransactionsScreen> createState() => _BankTransactionsScreenState();
}

class _BankTransactionsScreenState extends State<BankTransactionsScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

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
    final repo = context.read<EmployeeAuthNotifier>().repository;
    setState(() => _loading = true);
    final list = await repo.listTransactions(query: _search.text);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'المعاملات',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'رقم المعاملة، العقار، هاتف المشتري…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: BankTokens.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Text(
                                'لا توجد معاملات.',
                                style: TextStyle(
                                  color: BankTokens.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final t = _items[i];
                            final status =
                                t['financial_status']?.toString() ?? '';
                            return Material(
                              color: BankTokens.card,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: BankTokens.outlineVariant,
                                  ),
                                ),
                                title: Text(
                                  '#${t['transaction_number'] ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${t['buyer_name'] ?? t['buyer_phone'] ?? '—'} · ${_statusAr(status)}\n'
                                  'المطلوب: ${_fmt(t['required_escrow_amount'])} د.ع',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_left),
                                onTap: () => context.push(
                                  '/employee/bank/transaction/${t['id']}',
                                  extra: t,
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  String _statusAr(String s) {
    switch (s) {
      case 'awaiting_deposit':
        return 'بانتظار الإيداع';
      case 'awaiting_remaining':
        return 'بانتظار المتبقي';
      case 'deposit_confirmed':
        return 'مؤكد';
      default:
        return s.replaceAll('_', ' ');
    }
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
