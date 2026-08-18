import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../theme/app_theme.dart';

enum ChatThreadKind { ai, support, sales, closing, agent }

enum ChatMessageType { text, image, location, voice, video, barcode, propertyCard }

class ChatThread {
  const ChatThread({
    required this.id,
    required this.kind,
    required this.icon,
    this.displayName,
  });

  final String id;
  final ChatThreadKind kind;
  final IconData icon;
  final String? displayName;

  Color get color => AppTheme.primary;

  String title(AppLocalizations loc) {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    return switch (kind) {
      ChatThreadKind.ai => loc.msgAiAssistant,
      ChatThreadKind.support => loc.msgCustomerSupport,
      ChatThreadKind.sales => loc.msgSalesTeam,
      ChatThreadKind.closing => loc.msgClosingTeam,
      ChatThreadKind.agent => loc.msgAgentLawyer,
    };
  }

  String subtitle(AppLocalizations loc) {
    return switch (kind) {
      ChatThreadKind.ai => loc.msgAiSub,
      ChatThreadKind.support => loc.msgSupportSub,
      ChatThreadKind.sales => loc.msgSalesSub,
      ChatThreadKind.closing => loc.msgClosingSub,
      ChatThreadKind.agent => loc.msgAgentSub,
    };
  }

  static const List<ChatThread> pinned = [
    ChatThread(id: 'ai', kind: ChatThreadKind.ai, icon: Icons.auto_awesome),
    ChatThread(
      id: 'support',
      kind: ChatThreadKind.support,
      icon: Icons.headset_mic_outlined,
    ),
    ChatThread(
      id: 'sales',
      kind: ChatThreadKind.sales,
      icon: Icons.storefront_outlined,
    ),
    ChatThread(
      id: 'closing',
      kind: ChatThreadKind.closing,
      icon: Icons.handshake_outlined,
    ),
    ChatThread(
      id: 'agent',
      kind: ChatThreadKind.agent,
      icon: Icons.qr_code_2_rounded,
    ),
  ];
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.createdAt,
    this.type = ChatMessageType.text,
    this.senderType = 'peer',
    this.suggestions,
    this.mapFocus,
    this.voiceSeconds,
  });

  final String id;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final ChatMessageType type;
  final String senderType;
  final List<dynamic>? suggestions;
  final Map<String, dynamic>? mapFocus;
  final int? voiceSeconds;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final sender = map['sender_type'] as String? ?? 'peer';
    final rawType = map['message_type'] as String? ?? 'text';
    final content = map['content'] as String? ?? '';
    ChatMessageType type = switch (rawType) {
      'image' => ChatMessageType.image,
      'location' => ChatMessageType.location,
      'voice' => ChatMessageType.voice,
      'video' => ChatMessageType.video,
      'barcode' => ChatMessageType.barcode,
      'property' || 'property_card' => ChatMessageType.propertyCard,
      _ =>
        content.startsWith('location:')
            ? ChatMessageType.location
            : content.trimLeft().startsWith('{') && content.contains('"title"')
                ? ChatMessageType.propertyCard
                : ChatMessageType.text,
    };
    final created =
        DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now();
    return ChatMessage(
      id: map['id']?.toString() ?? created.millisecondsSinceEpoch.toString(),
      content: content,
      isUser: sender == 'user',
      createdAt: created,
      type: type,
      senderType: sender,
      suggestions: map['suggestions'] is List
          ? List<dynamic>.from(map['suggestions'] as List)
          : null,
      mapFocus: map['map_focus'] is Map
          ? Map<String, dynamic>.from(map['map_focus'] as Map)
          : null,
      voiceSeconds: (map['voice_seconds'] as num?)?.toInt(),
    );
  }
}
