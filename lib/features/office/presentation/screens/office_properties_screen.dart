import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../services/supabase_service.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

class OfficePropertiesScreen extends StatefulWidget {
  const OfficePropertiesScreen({super.key});

  @override
  State<OfficePropertiesScreen> createState() => _OfficePropertiesScreenState();
}

class _OfficePropertiesScreenState extends State<OfficePropertiesScreen> {
  bool _loading = true;
  List<_OfficePropertyRow> _rows = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<OfficeAuthNotifier>();
    setState(() => _loading = true);
    final assigned = await auth.repository.loadOfficeAssignedProperties();
    final enriched = <_OfficePropertyRow>[];
    for (final row in assigned) {
      final propertyId = row['property_id']?.toString();
      Map<String, dynamic>? property;
      if (propertyId != null) {
        try {
          property = await SupabaseService.instance.getPropertyById(propertyId);
        } catch (_) {}
      }
      enriched.add(
        _OfficePropertyRow(
          assignment: row,
          property: property,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _rows = enriched;
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
        title: Text(loc.officeNavProperties),
        actions: [
          IconButton(
            onPressed: () => context.push('/office/report-property'),
            icon: const Icon(Icons.flag_outlined),
            tooltip: loc.officeReportProperty,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      loc.officeNoAssignedProperties,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final row = _rows[i];
                      final p = row.property;
                      final status = (row.assignment['status'] as String? ?? '')
                          .replaceAll('_', ' ');
                      final title = p?['title'] as String? ??
                          loc.officePropertyFallback;
                      final price = p?['asking_price'];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        title: Text(title),
                        subtitle: Text(
                          '${loc.officeStatus}: $status',
                        ),
                        trailing: Text(
                          price != null ? '$price' : '—',
                          style: theme.textTheme.labelLarge,
                        ),
                        onTap: p == null
                            ? null
                            : () => context.push(
                                  '/property-detail',
                                  extra: p,
                                ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _OfficePropertyRow {
  _OfficePropertyRow({required this.assignment, this.property});
  final Map<String, dynamic> assignment;
  final Map<String, dynamic>? property;
}
