import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/domain/employee_permissions.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class OmReportsScreen extends StatefulWidget {
  const OmReportsScreen({super.key});

  @override
  State<OmReportsScreen> createState() => _OmReportsScreenState();
}

class _OmReportsScreenState extends State<OmReportsScreen> {
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
    final list = await repo.listPropertyReports();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _requestPhoto(Map<String, dynamic> report) async {
    final loc = AppLocalizations.of(context);
    final auth = context.read<EmployeeAuthNotifier>();
    final office = report['offices'] as Map?;
    final tmpId =
        'TMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final ok = await auth.repository.createPhotographyRequest(
      temporaryPropertyId: tmpId,
      officeId: report['office_id']?.toString(),
      reportId: report['id']?.toString(),
      ownerPhone: report['owner_phone']?.toString(),
      locationText: report['address_text']?.toString(),
      propertyType: report['property_type']?.toString(),
      notes: 'From office report — ${office?['name'] ?? ''}',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '${loc.empPhotographyRequested}: $tmpId' : loc.empActionFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canPublish = context.watch<EmployeeAuthNotifier>().can(
      EmployeePermission.propertiesPublishRequest,
    );

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = _items[i];
                final office = r['offices'] as Map?;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  title: Text(r['address_text']?.toString() ?? loc.empPropertyReport),
                  subtitle: Text(
                    '${office?['name'] ?? ''} · ${r['status']} · '
                    '${r['property_type'] ?? ''} · ${r['owner_phone'] ?? ''}',
                  ),
                  trailing: canPublish
                      ? IconButton(
                          onPressed: () => _requestPhoto(r),
                          icon: const Icon(Icons.photo_camera_outlined),
                          tooltip: loc.empRequestPhotography,
                        )
                      : null,
                );
              },
            ),
          );
  }
}
