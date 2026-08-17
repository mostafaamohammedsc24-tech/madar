import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/chat_models.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.thread,
    this.size = 52,
    this.iconSize = 24,
  });

  final ChatThread thread;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(thread.icon, color: AppTheme.primary, size: iconSize),
    );
  }
}
