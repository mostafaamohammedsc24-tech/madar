import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/localization/app_localizations.dart';
import '../../services/property_ai_service.dart';
import '../../services/property_catalog_demo.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../search_map_screen/models/property_data.dart';
import 'chat_session_store.dart';
import 'models/chat_models.dart';
import 'widgets/chat_avatar.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_field.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.thread});

  final ChatThread thread;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _ai = PropertyAiService();
  final _history = <Map<String, String>>[];
  List<PropertyData> _catalog = [];
  bool _typing = false;
  bool _busy = false;
  bool _recording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  ChatThread get thread => widget.thread;
  List<ChatMessage> get _messages =>
      ChatSessionStore.instance.messagesFor(thread.id);

  @override
  void initState() {
    super.initState();
    if (thread.kind == ChatThreadKind.ai) _loadCatalog();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final data = await SupabaseService.instance.getProperties(limit: 40);
      if (data.isNotEmpty) {
        _catalog = data
            .map(PropertyData.fromSupabase)
            .where((p) => p.lat != 0 && p.lng != 0)
            .toList();
      }
    } catch (_) {}
    if (_catalog.isEmpty) _catalog = PropertyCatalogDemo.listings();
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

  void _push(ChatMessage message) {
    ChatSessionStore.instance.add(thread.id, message);
    setState(() {});
    _scrollToEnd();
  }

  Future<void> _sendText() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _push(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: text,
        isUser: true,
        createdAt: DateTime.now(),
        type: thread.kind == ChatThreadKind.agent
            ? ChatMessageType.barcode
            : ChatMessageType.text,
      ),
    );
    if (thread.kind == ChatThreadKind.ai) {
      await _replyAi(text);
      return;
    }
    try {
      await SupabaseService.instance.sendMessage(
        conversationId: thread.id,
        content: text,
      );
    } catch (_) {}
  }

  Future<void> _replyAi(String text) async {
    setState(() => _typing = true);
    _history.add({'role': 'user', 'content': text});
    try {
      if (_catalog.isEmpty) await _loadCatalog();
      final result = await _ai.chat(
        userMessage: text,
        catalog: _catalog,
        history: _history.length > 1
            ? _history.sublist(0, _history.length - 1)
            : const [],
      );
      final aiText = result.reply.isNotEmpty
          ? result.reply
          : 'إليك أفضل الاقتراحات المتاحة حسب طلبك.';
      _history.add({'role': 'assistant', 'content': aiText});
      if (!mounted) return;
      setState(() => _typing = false);
      _push(
        ChatMessage(
          id: 'ai-${DateTime.now().microsecondsSinceEpoch}',
          content: aiText,
          isUser: false,
          createdAt: DateTime.now(),
          senderType: 'ai',
          suggestions: result.suggestions.isEmpty ? null : result.suggestions,
          mapFocus: result.mapFocusLat == null
              ? null
              : {
                  'lat': result.mapFocusLat,
                  'lng': result.mapFocusLng,
                  'label': result.mapFocusLabel,
                },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _typing = false);
      _push(
        ChatMessage(
          id: 'ai-err',
          content: 'Sorry, an error occurred. Please try again.',
          isUser: false,
          createdAt: DateTime.now(),
          senderType: 'ai',
        ),
      );
    }
  }

  Future<void> _pickMedia({required bool video}) async {
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final file = video
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 70,
            );
      if (file == null) return;
      if (video) {
        _push(
          ChatMessage(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            content: file.path,
            isUser: true,
            createdAt: DateTime.now(),
            type: ChatMessageType.video,
          ),
        );
        return;
      }
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last;
      final url = 'data:image/$ext;base64,${base64Encode(bytes)}';
      _push(
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          content: url,
          isUser: true,
          createdAt: DateTime.now(),
          type: thread.kind == ChatThreadKind.agent
              ? ChatMessageType.barcode
              : ChatMessageType.image,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendLocation() async {
    final loc = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _push(
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          content: 'location:${pos.latitude},${pos.longitude}',
          isUser: true,
          createdAt: DateTime.now(),
          type: ChatMessageType.location,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.locationLabel)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendBarcode() async {
    final loc = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.sendBarcode),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'IQ-BGD-SALE-2026-000001',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (code == null || code.isEmpty) {
      await _pickMedia(video: false);
      return;
    }
    _push(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: code,
        isUser: true,
        createdAt: DateTime.now(),
        type: ChatMessageType.barcode,
      ),
    );
  }

  void _toggleVoice() {
    if (_recording) {
      _recordTimer?.cancel();
      final seconds = _recordSeconds.clamp(1, 99);
      setState(() {
        _recording = false;
        _recordSeconds = 0;
      });
      _push(
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          content: 'voice',
          isUser: true,
          createdAt: DateTime.now(),
          type: ChatMessageType.voice,
          voiceSeconds: seconds,
        ),
      );
      return;
    }
    setState(() {
      _recording = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordSeconds++);
    });
  }

  void _onCall() {
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loc.callsComingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final messages = _messages;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F6),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            ChatAvatar(thread: thread, size: 38, iconSize: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                thread.title(loc),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _onCall,
            icon: const Icon(Icons.call_outlined),
            tooltip: loc.voiceNote,
          ),
          IconButton(
            onPressed: _onCall,
            icon: const Icon(Icons.videocam_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, index) {
                if (_typing && index == messages.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        ChatAvatar(thread: thread, size: 32, iconSize: 16),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('•••'),
                        ),
                      ],
                    ),
                  );
                }
                return ChatBubble(message: messages[index], thread: thread);
              },
            ),
          ),
          ChatInputField(
            controller: _input,
            thread: thread,
            isRecording: _recording,
            recordingSeconds: _recordSeconds,
            busy: _busy,
            onSend: _sendText,
            onToggleVoice: _toggleVoice,
            onPickImage: () => _pickMedia(video: false),
            onPickVideo: () => _pickMedia(video: true),
            onSendLocation: _sendLocation,
            onSendBarcode: _sendBarcode,
          ),
        ],
      ),
    );
  }
}
