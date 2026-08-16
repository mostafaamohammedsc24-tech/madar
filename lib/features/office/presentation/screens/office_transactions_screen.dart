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
      appBar: AppBar(
        title: Text(loc.officeNavTransactions),
        actions: [
          IconButton(
            onPressed: () => context.push('/office/history'),
            icon: const Icon(Icons.history),
            tooltip: loc.officeSalesHistory,
          ),
        ],
      ),
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
                      children: [
                        const SizedBox(height: 100),
                        Center(child: Text(loc.officeNoTransactions)),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final t = _items[i];
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
