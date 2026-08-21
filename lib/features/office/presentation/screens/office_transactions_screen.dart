import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

class OfficeTransactionsScreen extends StatefulWidget {
  const OfficeTransactionsScreen({super.key});

  @override
  State<OfficeTransactionsScreen> createState() =>
      _OfficeTransactionsScreenState();
}

class _OfficeTransactionsScreenState extends State<OfficeTransactionsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<OfficeAuthNotifier>().repository;
    setState(() => _loading = true);
    final list = await repo.listOfficeTransactions();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/office/create-transaction'),
        icon: const Icon(Icons.qr_code_2),
        label: Text(loc.officeCreateTransaction),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          loc.officeNavTransactions,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.officeNoTransactions,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'أنشئ معاملة عند توفر بائع ومشترٍ موثّقين.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: _items.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  loc.officeNavTransactions,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    context.push('/office/history'),
                                icon: const Icon(Icons.history),
                                tooltip: loc.officeSalesHistory,
                              ),
                            ],
                          );
                        }
                        final t = _items[i - 1];
                        final number = t['transaction_number']?.toString() ??
                            t['reference_number']?.toString() ??
                            '—';
                        final state = (t['lifecycle_state'] as String? ??
                                t['status'] as String? ??
                                '')
                            .replaceAll('_', ' ');
                        final type = t['transaction_type']?.toString() ?? '';
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          title: Text(number),
                          subtitle: Text('$type · $state'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(
                            '/office/transaction/${t['id']}',
                            extra: t,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
