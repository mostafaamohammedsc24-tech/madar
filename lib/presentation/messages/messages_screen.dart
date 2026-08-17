import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/ai_client.dart';
import '../../services/supabase_service.dart';

// Messages Screen — 5 pinned conversations + AI chat + image/location sharing

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  int _selectedConversation = 0;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingMessages = false;
  RealtimeChannel? _messageChannel;
  bool _isSendingMedia = false;

  static const _aiConfig = ChatConfig(
    provider: 'GEMINI',
    model: 'gemini/gemini-2.5-flash',
    streaming: true,
  );

  // Conversation definitions — icons only, no emojis
  static const List<Map<String, dynamic>> _conversationDefs = [
    {
      'id': 'ai',
      'titleKey': 'ai',
      'subtitleKey': 'ai_sub',
      'iconName': 'smart_toy',
      'color': 0xFF6C63FF,
      'pinned': true,
      'type': 'ai',
    },
    {
      'id': 'support',
      'titleKey': 'support',
      'subtitleKey': 'support_sub',
      'iconName': 'headset_mic',
      'color': 0xFF00897B,
      'pinned': true,
      'type': 'support',
    },
    {
      'id': 'sales',
      'titleKey': 'sales',
      'subtitleKey': 'sales_sub',
      'iconName': 'real_estate_agent',
      'color': 0xFF1565C0,
      'pinned': true,
      'type': 'sales',
    },
    {
      'id': 'closing',
      'titleKey': 'closing',
      'subtitleKey': 'closing_sub',
      'iconName': 'handshake',
      'color': 0xFFF57C00,
      'pinned': true,
      'type': 'closing',
    },
    {
      'id': 'agent',
      'titleKey': 'agent',
      'subtitleKey': 'agent_sub',
      'iconName': 'gavel',
      'color': 0xFF7B1FA2,
      'pinned': true,
      'type': 'agent',
    },
  ];

  final List<Map<String, String>> _aiHistory = [];

  String _convTitle(BuildContext context, Map<String, dynamic> conv) {
    final loc = AppLocalizations.of(context);
    switch (conv['titleKey'] as String) {
      case 'ai':
        return loc.msgAiAssistant;
      case 'support':
        return loc.msgCustomerSupport;
      case 'sales':
        return loc.msgSalesTeam;
      case 'closing':
        return loc.msgClosingTeam;
      case 'agent':
        return loc.msgAgentLawyer;
      default:
        return conv['titleKey'] as String;
    }
  }

  String _convSubtitle(BuildContext context, Map<String, dynamic> conv) {
    final loc = AppLocalizations.of(context);
    switch (conv['subtitleKey'] as String) {
      case 'ai_sub':
        return loc.msgAiSub;
      case 'support_sub':
        return loc.msgSupportSub;
      case 'sales_sub':
        return loc.msgSalesSub;
      case 'closing_sub':
        return loc.msgClosingSub;
      case 'agent_sub':
        return loc.msgAgentSub;
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageChannel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final conv = _conversationDefs[_selectedConversation];
    if (conv['type'] == 'ai') {
      setState(() => _messages = List.from(_aiHistory.map((m) => m)));
      return;
    }
    setState(() => _isLoadingMessages = true);
    try {
      final convId = conv['id'] as String;
      final msgs = await SupabaseService.instance.getMessages(convId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoadingMessages = false;
        });
        _subscribeToMessages(convId);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  void _subscribeToMessages(String convId) {
    _messageChannel?.unsubscribe();
    _messageChannel = SupabaseService.instance.subscribeToMessages(convId, (
      msg,
    ) {
      if (mounted) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final conv = _conversationDefs[_selectedConversation];

    if (conv['type'] == 'ai') {
      await _sendAiMessage(text);
      return;
    }

    setState(() {
      _messages.add({
        'content': text,
        'sender_type': 'user',
        'created_at': DateTime.now().toIso8601String(),
        'message_type': 'text',
      });
    });
    _scrollToBottom();

    try {
      await SupabaseService.instance.sendMessage(
        conversationId: conv['id'] as String,
        content: text,
      );
    } catch (_) {}
  }

  Future<void> _sendAiMessage(String text) async {
    setState(() {
      _messages.add({
        'content': text,
        'sender_type': 'user',
        'created_at': DateTime.now().toIso8601String(),
        'message_type': 'text',
      });
      _isTyping = true;
    });
    _scrollToBottom();

    _aiHistory.add({'role': 'user', 'content': text});

    try {
      final aiClient = AiClient();
      const systemPrompt =
          'You are Madar AI Assistant for a real estate platform. Help users search for properties, understand prices, and guide them through buying, selling, and renting processes in Iraq, Saudi Arabia, and UAE. Respond in the same language the user writes in. Be helpful and professional.';

      final response = await aiClient.chatCompletion(
        config: _aiConfig,
        messages: [
          {'role': 'system', 'content': systemPrompt},
          ..._aiHistory,
        ],
      );

      final aiText =
          response ?? 'Sorry, I could not respond right now. Please try again.';
      _aiHistory.add({'role': 'assistant', 'content': aiText});

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'content': aiText,
            'sender_type': 'ai',
            'created_at': DateTime.now().toIso8601String(),
            'message_type': 'text',
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'content': 'Sorry, an error occurred. Please try again.',
            'sender_type': 'ai',
            'created_at': DateTime.now().toIso8601String(),
            'message_type': 'text',
          });
        });
      }
    }
  }

  Future<void> _sendImage() async {
    final loc = AppLocalizations.of(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    setState(() => _isSendingMedia = true);

    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.$ext';

      String imageUrl = '';
      try {
        final supabase = SupabaseService.instance.client;
        await supabase.storage
            .from('chat-media')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        imageUrl = supabase.storage.from('chat-media').getPublicUrl(fileName);
      } catch (_) {
        // Fallback: store as base64 data URI for demo
        final base64 = base64Encode(bytes);
        imageUrl = 'data:image/$ext;base64,$base64';
      }

      final conv = _conversationDefs[_selectedConversation];
      setState(() {
        _messages.add({
          'content': imageUrl,
          'sender_type': 'user',
          'created_at': DateTime.now().toIso8601String(),
          'message_type': 'image',
        });
      });
      _scrollToBottom();

      if (conv['type'] != 'ai') {
        try {
          await SupabaseService.instance.sendMessage(
            conversationId: conv['id'] as String,
            content: imageUrl,
          );
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.isRTL ? 'فشل إرسال الصورة' : 'Failed to send image',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingMedia = false);
    }
  }

  Future<void> _sendLocation() async {
    final loc = AppLocalizations.of(context);
    setState(() => _isSendingMedia = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.isRTL
                    ? 'لم يتم منح إذن الموقع'
                    : 'Location permission denied',
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final locationContent =
          'location:${position.latitude},${position.longitude}';
      final conv = _conversationDefs[_selectedConversation];

      setState(() {
        _messages.add({
          'content': locationContent,
          'sender_type': 'user',
          'created_at': DateTime.now().toIso8601String(),
          'message_type': 'location',
        });
      });
      _scrollToBottom();

      if (conv['type'] != 'ai') {
        try {
          await SupabaseService.instance.sendMessage(
            conversationId: conv['id'] as String,
            content: locationContent,
          );
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.isRTL ? 'فشل الحصول على الموقع' : 'Failed to get location',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingMedia = false);
    }
  }

  void _showAttachmentMenu() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachOption(
                  icon: Icons.image,
                  label: loc.isRTL ? 'صورة' : 'Image',
                  color: AppTheme.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _sendImage();
                  },
                ),
                _buildAttachOption(
                  icon: Icons.camera_alt,
                  label: loc.isRTL ? 'كاميرا' : 'Camera',
                  color: const Color(0xFF6C63FF),
                  onTap: () async {
                    Navigator.pop(context);
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 70,
                    );
                    if (picked != null) {
                      // Reuse _sendImage logic with picked file
                      setState(() => _isSendingMedia = true);
                      try {
                        final bytes = await picked.readAsBytes();
                        final ext = picked.name.split('.').last;
                        final base64Str = base64Encode(bytes);
                        final imageUrl = 'data:image/$ext;base64,$base64Str';
                        setState(() {
                          _messages.add({
                            'content': imageUrl,
                            'sender_type': 'user',
                            'created_at': DateTime.now().toIso8601String(),
                            'message_type': 'image',
                          });
                        });
                        _scrollToBottom();
                      } finally {
                        if (mounted) setState(() => _isSendingMedia = false);
                      }
                    }
                  },
                ),
                _buildAttachOption(
                  icon: Icons.location_on,
                  label: loc.isRTL ? 'موقع' : 'Location',
                  color: AppTheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    _sendLocation();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            loc.navMessages,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: isTablet
          ? Row(
              children: [
                SizedBox(
                  width: 280,
                  child: _buildConversationList(context, theme),
                ),
                Expanded(child: _buildChatArea(context, theme)),
              ],
            )
          : Column(
              children: [
                _buildConversationTabs(context, theme),
                Expanded(child: _buildChatArea(context, theme)),
              ],
            ),
    );
  }

  Widget _buildConversationTabs(BuildContext context, ThemeData theme) {
    return Container(
      height: 80,
      color: theme.cardColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: _conversationDefs.length,
        itemBuilder: (_, i) {
          final conv = _conversationDefs[i];
          final isSelected = i == _selectedConversation;
          final color = Color(conv['color'] as int);
          final title = _convTitle(context, conv);
          final shortTitle = title.split(' ').first;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedConversation = i);
              _loadMessages();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : color.withAlpha(60),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: conv['iconName'] as String,
                    color: isSelected ? Colors.white : color,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    shortTitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationList(BuildContext context, ThemeData theme) {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              loc.navMessages,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _conversationDefs.length,
              itemBuilder: (_, i) {
                final conv = _conversationDefs[i];
                final isSelected = i == _selectedConversation;
                final color = Color(conv['color'] as int);

                return ListTile(
                  selected: isSelected,
                  selectedTileColor: color.withAlpha(20),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: conv['iconName'] as String,
                        color: color,
                        size: 22,
                      ),
                    ),
                  ),
                  title: Text(
                    _convTitle(context, conv),
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    _convSubtitle(context, conv),
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    setState(() => _selectedConversation = i);
                    _loadMessages();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(BuildContext context, ThemeData theme) {
    final conv = _conversationDefs[_selectedConversation];
    final color = Color(conv['color'] as int);
    final loc = AppLocalizations.of(context);

    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: conv['iconName'] as String,
                    color: color,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _convTitle(context, conv),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _convSubtitle(context, conv),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (conv['type'] == 'ai')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Gemini AI',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: _isLoadingMessages
              ? Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : _messages.isEmpty
              ? _buildEmptyChat(context, theme, conv)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_isTyping && i == _messages.length) {
                      return _buildTypingIndicator(theme, conv);
                    }
                    return _buildMessageBubble(theme, _messages[i], loc);
                  },
                ),
        ),
        // Input
        _buildMessageInput(context, theme, loc),
      ],
    );
  }

  Widget _buildEmptyChat(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> conv,
  ) {
    final color = Color(conv['color'] as int);
    final loc = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: conv['iconName'] as String,
                color: color,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _convTitle(context, conv),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            conv['type'] == 'ai'
                ? (loc.isRTL
                      ? 'اسألني عن أي عقار أو صفقة'
                      : 'Ask me about any property or deal')
                : (loc.isRTL
                      ? 'ابدأ محادثة مع ${_convTitle(context, conv)}'
                      : 'Start a conversation with ${_convTitle(context, conv)}'),
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (conv['type'] == 'ai') ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(
                  loc.isRTL
                      ? 'ابحث عن شقة في بغداد'
                      : 'Find an apartment in Baghdad',
                ),
                _buildSuggestionChip(
                  loc.isRTL
                      ? 'ما هي أسعار العقارات؟'
                      : 'What are property prices?',
                ),
                _buildSuggestionChip(
                  loc.isRTL ? 'كيف تعمل الصفقات؟' : 'How do transactions work?',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withAlpha(40)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ThemeData theme,
    Map<String, dynamic> msg,
    AppLocalizations loc,
  ) {
    final isUser = msg['sender_type'] == 'user';
    final content = msg['content'] as String? ?? '';
    final msgType = msg['message_type'] as String? ?? 'text';
    final conv = _conversationDefs[_selectedConversation];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: conv['iconName'] as String,
                  color: Color(conv['color'] as int),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: msgType == 'image'
                ? _buildImageBubble(content, isUser, theme, loc)
                : msgType == 'location'
                ? _buildLocationBubble(content, isUser, theme, loc)
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primary : theme.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      content,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildImageBubble(
    String imageUrl,
    bool isUser,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return GestureDetector(
      onTap: () => _showImageFullscreen(imageUrl),
      onLongPress: () => _downloadImage(imageUrl, loc),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220, maxHeight: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          child: Stack(
            children: [
              imageUrl.startsWith('data:')
                  ? Image.memory(
                      base64Decode(imageUrl.split(',').last),
                      fit: BoxFit.cover,
                      width: 220,
                      height: 180,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 220,
                      height: 180,
                      errorBuilder: (_, __, ___) => Container(
                        width: 220,
                        height: 180,
                        color: AppTheme.primary.withAlpha(20),
                        child: Icon(
                          Icons.broken_image,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download, color: Colors.white, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        loc.isRTL ? 'حفظ' : 'Save',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationBubble(
    String content,
    bool isUser,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    // Parse lat,lng from "location:lat,lng"
    final parts = content.replaceFirst('location:', '').split(',');
    final lat = double.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final lng = double.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

    return GestureDetector(
      onTap: () async {
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: isUser ? Colors.white : AppTheme.error,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  loc.isRTL ? 'الموقع الحالي' : 'Current Location',
                  style: TextStyle(
                    color: isUser
                        ? Colors.white
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
              style: TextStyle(
                color: isUser ? Colors.white.withAlpha(200) : Colors.grey,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.white.withAlpha(40)
                    : AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                loc.isRTL ? 'فتح في الخريطة' : 'Open in Maps',
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageFullscreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: imageUrl.startsWith('data:')
                    ? Image.memory(base64Decode(imageUrl.split(',').last))
                    : Image.network(
                        imageUrl,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImage(String imageUrl, AppLocalizations loc) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.isRTL ? 'جاري حفظ الصورة...' : 'Saving image...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // On web, open in new tab; on mobile, show save confirmation
    if (kIsWeb) {
      try {
        final url = Uri.parse(
          imageUrl.startsWith('data:') ? imageUrl : imageUrl,
        );
        await launchUrl(url);
      } catch (_) {}
    }
  }

  Widget _buildTypingIndicator(ThemeData theme, Map<String, dynamic> conv) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: conv['iconName'] as String,
                color: Color(conv['color'] as int),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + i * 100),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(150),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // Attachment button
          GestureDetector(
            onTap: _isSendingMedia ? null : _showAttachmentMenu,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isSendingMedia
                    ? Colors.grey.withAlpha(30)
                    : AppTheme.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: _isSendingMedia
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : Icon(Icons.attach_file, color: AppTheme.primary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: loc.isRTL
                      ? 'اكتب رسالتك...'
                      : 'Type your message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
