import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../presentation/search_map_screen/search_map_screen.dart';
import '../../../../services/supabase_service.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/office_models.dart';
import '../providers/office_auth_notifier.dart';
import '../widgets/office_property_card.dart';

class OfficeChatScreen extends StatefulWidget {
  const OfficeChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<OfficeChatScreen> createState() => _OfficeChatScreenState();
}

class _OfficeChatScreenState extends State<OfficeChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = true;
  List<OfficeMessage> _messages = [];
  final Map<String, PropertyData> _propertyCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<OfficeAuthNotifier>().repository;
    setState(() => _loading = true);
    final msgs = await repo.listMessages(widget.conversationId);
    for (final m in msgs) {
      if (m.propertyId != null && !_propertyCache.containsKey(m.propertyId)) {
        try {
          final raw =
              await SupabaseService.instance.getPropertyById(m.propertyId!);
          if (raw != null) {
            _propertyCache[m.propertyId!] = PropertyData.fromSupabase(raw);
          }
        } catch (_) {}
      }
    }
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final repo = context.read<OfficeAuthNotifier>().repository;
    final ok = await repo.sendTextMessage(
      conversationId: widget.conversationId,
      body: text,
    );
    if (!ok || !mounted) return;
    _ctrl.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final office = context.watch<OfficeAuthNotifier>().office;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: Text(loc.officeManagementTeam)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final mine = m.senderSide == 'office';
                      if (m.messageType == 'property_card' &&
                          m.propertyId != null &&
                          _propertyCache[m.propertyId!] != null) {
                        final p = _propertyCache[m.propertyId!]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OfficePropertyCard(
                            property: p,
                            officeName: office?.name,
                            showFoundBuyer: false,
                            onOpen: () => context.push(
                              '/property-detail',
                              extra: p.rawData,
                            ),
                          ),
                        );
                      }
                      return Align(
                        alignment: mine
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: mine
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.body ?? '',
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (m.readAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    loc.officeRead,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: loc.officeMessageHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
