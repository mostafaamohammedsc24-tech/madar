import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../providers/employee_auth_notifier.dart';

class EmployeeAuditScreen extends StatefulWidget {
  const EmployeeAuditScreen({super.key});

  @override
  State<EmployeeAuditScreen> createState() => _EmployeeAuditScreenState();
}

class _EmployeeAuditScreenState extends State<EmployeeAuditScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<EmployeeAuthNotifier>().repository;
    setState(() => _loading = true);
    final list = await repo.listAuditLogs();
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

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text(loc.empEmptyAudit)),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final a = _items[i];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        title: Text(a['action']?.toString() ?? ''),
                        subtitle: Text(
                          '${a['employee_code'] ?? ''} · '
                          '${a['entity_type'] ?? ''} ${a['entity_id'] ?? ''}\n'
                          '${a['reason'] ?? ''}\n'
                          '${a['created_at'] ?? ''}',
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
          );
  }
}
