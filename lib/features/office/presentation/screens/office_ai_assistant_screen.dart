import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../presentation/search_map_screen/models/property_data.dart';
import '../../../../presentation/search_map_screen/widgets/ai_property_suggestion_card.dart';
import '../../../../presentation/search_map_screen/widgets/property_detail_sheet_widget.dart';
import '../../../../services/property_ai_service.dart';
import '../../../../services/supabase_service.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

/// Office-facing Madar AI — fast inventory search with suggestion cards.
class OfficeAiAssistantScreen extends StatefulWidget {
  const OfficeAiAssistantScreen({super.key});

  @override
  State<OfficeAiAssistantScreen> createState() =>
      _OfficeAiAssistantScreenState();
}

class _OfficeAiAssistantScreenState extends State<OfficeAiAssistantScreen> {
  final _ai = PropertyAiService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, String>> _history = [];
  List<PropertyData> _catalog = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final auth = context.read<OfficeAuthNotifier>();
      final rows = await auth.repository.loadDiscoverableProperties();
      if (rows.isNotEmpty) {
        _catalog = rows.map(PropertyData.fromSupabase).toList();
      }
    } catch (_) {}
    if (_catalog.isEmpty) {
      try {
        final data = await SupabaseService.instance.getProperties(limit: 80);
        if (data.isNotEmpty) {
          _catalog = data.map(PropertyData.fromSupabase).toList();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _messages.add({
        'role': 'ai',
        'text':
            'مساعد مدار للمكاتب جاهز. اكتب ميزانية العميل، الحي، عدد الغرف، قرب المدارس، أو أي شرط — سأعرض بطاقات العقارات المناسبة بسرعة.',
      });
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _busy = true;
      _messages.add({'role': 'user', 'text': text});
    });
    _scrollToEnd();

    _history.add({'role': 'user', 'content': text});
    final result = await _ai.chat(
      userMessage: text,
      catalog: _catalog,
      history: _history.length > 1
          ? _history.sublist(0, _history.length - 1)
          : const [],
    );
    final reply = result.reply.isNotEmpty
        ? result.reply
        : 'إليك أفضل المطابقات من مخزون العقارات.';
    _history.add({'role': 'assistant', 'content': reply});

    if (!mounted) return;
    setState(() {
      _busy = false;
      _messages.add({
        'role': 'ai',
        'text': reply,
        if (result.suggestions.isNotEmpty) 'suggestions': result.suggestions,
        if (result.mapFocusLat != null)
          'map_focus': {
            'lat': result.mapFocusLat,
            'lng': result.mapFocusLng,
            'label': result.mapFocusLabel,
          },
      });
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _openProperty(PropertyData property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PropertyDetailSheetWidget(property: property),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(loc.officeAiAssistantTitle),
        actions: [
          IconButton(
            tooltip: loc.officeNavHome,
            onPressed: () => context.go('/office/home'),
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length + (_busy ? 1 : 0),
              itemBuilder: (context, index) {
                if (_busy && index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                final suggestions = msg['suggestions'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppTheme.primary
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: isUser
                              ? null
                              : Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                        ),
                        child: Text(
                          msg['text'] as String? ?? '',
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            height: 1.45,
                          ),
                        ),
                      ),
                      if (suggestions is List && suggestions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 238,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: suggestions.length,
                            itemBuilder: (context, i) {
                              final item = suggestions[i];
                              if (item is! PropertyAiSuggestion) {
                                return const SizedBox.shrink();
                              }
                              return AiPropertySuggestionCard(
                                suggestion: item,
                                onTap: () => _openProperty(item.property),
                              );
                            },
                          ),
                        ),
                      ],
                      if (msg['map_focus'] is Map)
                        TextButton.icon(
                          onPressed: () => context.go('/office/home'),
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: Text(
                            (msg['map_focus'] as Map)['label']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true
                                ? '${loc.officeShowOnMap}: ${(msg['map_focus'] as Map)['label']}'
                                : loc.officeShowOnMap,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: loc.officeAiSearchHint,
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy ? null : _send,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.send_rounded),
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
