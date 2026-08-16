import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';

class OmConversationsScreen extends StatefulWidget {
  const OmConversationsScreen({super.key});

  @override
  State<OmConversationsScreen> createState() => _OmConversationsScreenState();
}

class _OmConversationsScreenState extends State<OmConversationsScreen> {
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
    final list = await repo.listOfficeConversations();
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
                      Center(child: Text(loc.empEmptyChats)),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = _items[i];
                      final office = c['offices'] as Map?;
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        title: Text(
                          c['title']?.toString() ??
                              office?['name']?.toString() ??
                              loc.empOfficeChat,
                        ),
                        subtitle: Text(
                          office?['office_code']?.toString() ??
                              c['team_key']?.toString() ??
                              '',
                        ),
                      );
                    },
                  ),
          );
  }
}
