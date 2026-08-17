import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../providers/employee_auth_notifier.dart';

class EmployeeSearchScreen extends StatefulWidget {
  const EmployeeSearchScreen({super.key});

  @override
  State<EmployeeSearchScreen> createState() => _EmployeeSearchScreenState();
}

class _EmployeeSearchScreenState extends State<EmployeeSearchScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final repo = context.read<EmployeeAuthNotifier>().repository;
    setState(() => _loading = true);
    final list = await repo.globalSearch(_ctrl.text);
    if (!mounted) return;
    setState(() {
      _results = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: loc.empGlobalSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = _results[i];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  leading: Icon(
                    r['type'] == 'office'
                        ? Icons.apartment_outlined
                        : Icons.receipt_long_outlined,
                  ),
                  title: Text(r['title']?.toString() ?? ''),
                  subtitle: Text(
                    '${r['type']} · ${r['subtitle'] ?? ''}',
                  ),
                  onTap: () {
                    if (r['type'] == 'transaction') {
                      context.push(
                        '/employee/finance/transaction/${r['id']}',
                        extra: r['raw'],
                      );
                    } else if (r['type'] == 'office') {
                      context.go('/employee/om/offices');
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
