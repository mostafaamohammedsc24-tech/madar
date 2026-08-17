import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'chat_room_screen.dart';
import 'models/chat_models.dart';
import 'widgets/chat_list_tile.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  Future<void> _openThread(ChatThread thread) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => ChatRoomScreen(thread: thread)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          loc.navMessages,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: ChatThread.pinned.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 80, color: Color(0xFFEEF2F6)),
        itemBuilder: (context, index) {
          final thread = ChatThread.pinned[index];
          return ChatListTile(thread: thread, onTap: () => _openThread(thread));
        },
      ),
    );
  }
}
