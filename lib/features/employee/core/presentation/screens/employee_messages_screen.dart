import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../services/publisher_seed.dart';
import '../../../../../services/supabase_service.dart';
import '../providers/employee_auth_notifier.dart';

/// Permission-scoped internal messages (employee_internal_* tables).
class EmployeeMessagesScreen extends StatefulWidget {
  const EmployeeMessagesScreen({super.key});

  @override
  State<EmployeeMessagesScreen> createState() => _EmployeeMessagesScreenState();
}

class _EmployeeMessagesScreenState extends State<EmployeeMessagesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final emp = context.read<EmployeeAuthNotifier>().employee;
    final auth = context.read<EmployeeAuthNotifier>();
    setState(() => _loading = true);
    if (auth.repository.isPublisherSeedSession) {
      if (!mounted) return;
      setState(() {
        _items = PublisherSeed.messages();
        _loading = false;
      });
      return;
    }
    try {
      final client = SupabaseService.instance.client;
      final rows = await client
          .from('employee_internal_conversations')
          .select()
          .order('last_message_at', ascending: false)
          .limit(40);
      final list = List<Map<String, dynamic>>.from(rows);
      // Scope: same department conversations or ones the employee created.
      final scoped = list.where((c) {
        final dept = c['department_code']?.toString();
        final createdBy = c['created_by_employee_id']?.toString();
        return dept == null ||
            dept == emp?.department.code ||
            createdBy == emp?.id;
      }).toList();
      if (!mounted) return;
      setState(() {
        _items = scoped;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  loc.empNavMessages,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.empMessagesHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      loc.empMessagesEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ..._items.map(
                    (c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.forum_outlined),
                      title: Text(c['title']?.toString() ?? loc.empConversation),
                      subtitle: Text(c['department_code']?.toString() ?? ''),
                      trailing: Text(
                        c['last_message_at']?.toString().split('T').first ?? '',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
              ],
            ),
          );
  }
}
