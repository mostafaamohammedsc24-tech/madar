import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/domain/employee_permissions.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class OmOfficesScreen extends StatefulWidget {
  const OmOfficesScreen({super.key});

  @override
  State<OmOfficesScreen> createState() => _OmOfficesScreenState();
}

class _OmOfficesScreenState extends State<OmOfficesScreen> {
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
    final list = await repo.listOffices();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _activate(String id) async {
    final repo = context.read<EmployeeAuthNotifier>().repository;
    final ok = await repo.setOfficeStatus(officeId: id, status: 'active');
    if (!mounted) return;
    if (ok) _load();
  }

  Future<void> _suspend(String id) async {
    final repo = context.read<EmployeeAuthNotifier>().repository;
    final ok = await repo.setOfficeStatus(
      officeId: id,
      status: 'suspended',
      reason: 'Suspended by office management',
    );
    if (!mounted) return;
    if (ok) _load();
  }

  Future<void> _resetSecret(String id) async {
    final loc = AppLocalizations.of(context);
    final repo = context.read<EmployeeAuthNotifier>().repository;
    final res = await repo.resetOfficeSecret(id);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.empSecretReset),
        content: Text(
          res.success
              ? '${loc.empTemporarySecret}: ${res.secret}'
              : loc.empActionFailed,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.empClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = context.watch<EmployeeAuthNotifier>();

    return Scaffold(
      floatingActionButton: auth.can(EmployeePermission.officesCreate)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/employee/om/offices/create'),
              icon: const Icon(Icons.add),
              label: Text(loc.empAddOffice),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final o = _items[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    title: Text(o['name']?.toString() ?? ''),
                    subtitle: Text(
                      '${o['office_code']} · ${o['status']} · ${o['city'] ?? ''}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        final id = o['id'].toString();
                        if (v == 'activate') _activate(id);
                        if (v == 'suspend') _suspend(id);
                        if (v == 'reset') _resetSecret(id);
                      },
                      itemBuilder: (_) => [
                        if (auth.can(EmployeePermission.officesEdit))
                          PopupMenuItem(
                            value: 'activate',
                            child: Text(loc.empActivateOffice),
                          ),
                        if (auth.can(EmployeePermission.officesSuspend))
                          PopupMenuItem(
                            value: 'suspend',
                            child: Text(loc.empSuspendOffice),
                          ),
                        if (auth.can(EmployeePermission.officesCredentialsReset))
                          PopupMenuItem(
                            value: 'reset',
                            child: Text(loc.empResetSecret),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
