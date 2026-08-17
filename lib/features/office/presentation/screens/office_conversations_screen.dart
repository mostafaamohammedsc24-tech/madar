import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/office_models.dart';
import '../providers/office_auth_notifier.dart';

class OfficeConversationsScreen extends StatefulWidget {
  const OfficeConversationsScreen({super.key});

  @override
  State<OfficeConversationsScreen> createState() =>
      _OfficeConversationsScreenState();
}

class _OfficeConversationsScreenState extends State<OfficeConversationsScreen> {
  bool _loading = true;
  List<OfficeConversation> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<OfficeAuthNotifier>().repository;
    setState(() => _loading = true);
    final list = await repo.listConversations();
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
      appBar: AppBar(title: Text(loc.officeNavConversations)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(child: Text(loc.officeNoConversations)),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final c = _items[i];
                        final title = c.title?.isNotEmpty == true
                            ? c.title!
                            : loc.officeManagementTeam;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.groups_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          title: Text(title),
                          subtitle: Text(
                            c.lastMessageAt
                                    ?.toLocal()
                                    .toString()
                                    .split('.')
                                    .first ??
                                loc.officeManagementTeam,
                          ),
                          onTap: () => context.push('/office/chat/${c.id}'),
                        );
                      },
                    ),
            ),
    );
  }
}
