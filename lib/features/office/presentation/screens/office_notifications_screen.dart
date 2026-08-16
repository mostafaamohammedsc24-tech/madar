import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

class OfficeNotificationsScreen extends StatefulWidget {
  const OfficeNotificationsScreen({super.key});

  @override
  State<OfficeNotificationsScreen> createState() =>
      _OfficeNotificationsScreenState();
}

class _OfficeNotificationsScreenState extends State<OfficeNotificationsScreen> {
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
    final list = await repo.listNotifications();
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
      appBar: AppBar(title: Text(loc.officeNotifications)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(child: Text(loc.officeNoNotifications)),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final n = _items[i];
                        final unread = n['read_at'] == null;
                        return ListTile(
                          tileColor: unread
                              ? theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.25)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          title: Text(n['title']?.toString() ?? ''),
                          subtitle: Text(n['body']?.toString() ?? ''),
                        );
                      },
                    ),
            ),
    );
  }
}
