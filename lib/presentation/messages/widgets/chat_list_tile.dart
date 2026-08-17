import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../chat_session_store.dart';
import '../models/chat_models.dart';
import 'chat_avatar.dart';

class ChatListTile extends StatelessWidget {
  const ChatListTile({super.key, required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final last = ChatSessionStore.instance.last(thread.id);
    final preview = _preview(loc, last);
    final time = last == null ? '' : _formatTime(last.createdAt);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ChatAvatar(thread: thread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.title(loc),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF101828),
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF667085),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _preview(AppLocalizations loc, ChatMessage? last) {
    if (last == null) return thread.subtitle(loc);
    return switch (last.type) {
      ChatMessageType.image => loc.imageLabel,
      ChatMessageType.video => loc.videoLabel,
      ChatMessageType.location => loc.locationLabel,
      ChatMessageType.voice => loc.voiceNote,
      ChatMessageType.barcode => loc.sendBarcode,
      ChatMessageType.text => last.content.replaceAll('**', ''),
    };
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    if (now.year == local.year &&
        now.month == local.month &&
        now.day == local.day) {
      return DateFormat.Hm().format(local);
    }
    return DateFormat('d/M').format(local);
  }
}
