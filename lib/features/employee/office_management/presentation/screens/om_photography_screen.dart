import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class OmPhotographyScreen extends StatefulWidget {
  const OmPhotographyScreen({super.key});

  @override
  State<OmPhotographyScreen> createState() => _OmPhotographyScreenState();
}

class _OmPhotographyScreenState extends State<OmPhotographyScreen> {
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
    final list = await repo.listPhotographyRequests();
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
                      Center(child: Text(loc.empEmptyPhotography)),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = _items[i];
                      final office = p['offices'] as Map?;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        title: Text(p['temporary_property_id']?.toString() ?? ''),
                        subtitle: Text(
                          '${office?['name'] ?? ''} · ${p['location_text'] ?? ''} · '
                          '${p['status']} · ${p['owner_phone'] ?? ''}',
                        ),
                      );
                    },
                  ),
          );
  }
}
