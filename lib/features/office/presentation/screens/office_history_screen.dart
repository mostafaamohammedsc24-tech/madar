import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

class OfficeHistoryScreen extends StatefulWidget {
  const OfficeHistoryScreen({super.key});

  @override
  State<OfficeHistoryScreen> createState() => _OfficeHistoryScreenState();
}

class _OfficeHistoryScreenState extends State<OfficeHistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  String _range = 'this_month';

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
      _all = list;
      _loading = false;
    });
    _apply();
  }

  void _apply() {
    final now = DateTime.now();
    DateTime? start;
    if (_range == 'this_month') {
      start = DateTime(now.year, now.month, 1);
    } else if (_range == 'last_month') {
      start = DateTime(now.year, now.month - 1, 1);
    } else if (_range == 'this_year') {
      start = DateTime(now.year, 1, 1);
    }

    setState(() {
      _filtered = _all.where((t) {
        final created = DateTime.tryParse(t['created_at']?.toString() ?? '');
        if (start != null && created != null && created.isBefore(start)) {
          return false;
        }
        if (_range == 'last_month' && created != null) {
          final end = DateTime(now.year, now.month, 1);
          if (!created.isBefore(end)) return false;
        }
        final type = (t['transaction_type'] as String? ?? '').toLowerCase();
        if (_typeFilter != 'all' && type != _typeFilter) return false;
        final state = (t['lifecycle_state'] as String? ??
                t['status'] as String? ??
                '')
            .toLowerCase();
        if (_statusFilter == 'completed' && state != 'completed') return false;
        if (_statusFilter == 'pending' &&
            (state == 'completed' || state == 'cancelled')) {
          return false;
        }
        if (_statusFilter == 'cancelled' && state != 'cancelled') return false;
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: Text(loc.officeSalesHistory)),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                for (final f in [
                  ('this_month', loc.officeFilterThisMonth),
                  ('last_month', loc.officeFilterLastMonth),
                  ('this_year', loc.officeFilterThisYear),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(f.$2),
                      selected: _range == f.$1,
                      onSelected: (_) {
                        _range = f.$1;
                        _apply();
                      },
                    ),
                  ),
                for (final f in [
                  ('all', loc.officeFilterAll),
                  ('sale', loc.officeFilterSale),
                  ('rent', loc.officeFilterRent),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: FilterChip(
                      label: Text(f.$2),
                      selected: _typeFilter == f.$1,
                      onSelected: (_) {
                        _typeFilter = f.$1;
                        _apply();
                      },
                    ),
                  ),
                for (final f in [
                  ('all', loc.officeFilterAll),
                  ('completed', loc.officeStatCompleted),
                  ('pending', loc.officeStatInProgress),
                  ('cancelled', loc.officeCancelled),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: FilterChip(
                      label: Text(f.$2),
                      selected: _statusFilter == f.$1,
                      onSelected: (_) {
                        _statusFilter = f.$1;
                        _apply();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(child: Text(loc.officeNoTransactions)),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final t = _filtered[i];
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                title: Text(
                                  t['transaction_number']?.toString() ?? '—',
                                ),
                                subtitle: Text(
                                  '${t['transaction_type'] ?? ''} · '
                                  '${t['lifecycle_state'] ?? t['status'] ?? ''}\n'
                                  '${t['buyer_phone'] ?? ''} / ${t['seller_phone'] ?? ''}',
                                ),
                                isThreeLine: true,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
