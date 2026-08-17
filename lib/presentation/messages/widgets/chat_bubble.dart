import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../services/property_ai_service.dart';
import '../../../theme/app_theme.dart';
import '../../search_map_screen/widgets/ai_property_suggestion_card.dart';
import '../../search_map_screen/widgets/property_detail_sheet_widget.dart';
import '../models/chat_models.dart';
import 'chat_avatar.dart';
import 'chat_markdown_text.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, required this.thread});

  final ChatMessage message;
  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isUser = message.isUser;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                ChatAvatar(thread: thread, size: 32, iconSize: 16),
                const SizedBox(width: 8),
              ],
              Flexible(child: _body(context, loc, radius, isUser)),
            ],
          ),
          if (message.suggestions != null &&
              message.suggestions!.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 242,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.only(start: 40),
                itemCount: message.suggestions!.length,
                itemBuilder: (context, index) {
                  final item = message.suggestions![index];
                  if (item is! PropertyAiSuggestion) {
                    return const SizedBox.shrink();
                  }
                  return AiPropertySuggestionCard(
                    suggestion: item,
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            PropertyDetailSheetWidget(property: item.property),
                      );
                    },
                  );
                },
              ),
            ),
            if (message.mapFocus != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 40, top: 4),
                child: TextButton.icon(
                  onPressed: () {
                    context.go(
                      '/search-map-screen',
                      extra: {
                        'lat': message.mapFocus!['lat'],
                        'lng': message.mapFocus!['lng'],
                        'label': message.mapFocus!['label'],
                      },
                    );
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(
                    message.mapFocus!['label']?.toString().isNotEmpty == true
                        ? '${loc.openInMaps}: ${message.mapFocus!['label']}'
                        : loc.openInMaps,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations loc,
    BorderRadius radius,
    bool isUser,
  ) {
    switch (message.type) {
      case ChatMessageType.image:
        return _ImageBody(url: message.content, radius: radius);
      case ChatMessageType.video:
        return _VideoBody(radius: radius, isUser: isUser, loc: loc);
      case ChatMessageType.location:
        return _LocationBody(
          content: message.content,
          isUser: isUser,
          radius: radius,
          loc: loc,
        );
      case ChatMessageType.voice:
        return _VoiceBody(
          seconds: message.voiceSeconds ?? 4,
          isUser: isUser,
          radius: radius,
          loc: loc,
        );
      case ChatMessageType.barcode:
        return _TextShell(
          isUser: isUser,
          radius: radius,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_2,
                size: 18,
                color: isUser ? Colors.white : AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF101828),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      case ChatMessageType.text:
        final color = isUser ? Colors.white : const Color(0xFF101828);
        return _TextShell(
          isUser: isUser,
          radius: radius,
          child: ChatMarkdownText(
            data: message.content,
            style: TextStyle(color: color, fontSize: 15),
            boldStyle: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
    }
  }
}

class _TextShell extends StatelessWidget {
  const _TextShell({
    required this.isUser,
    required this.radius,
    required this.child,
  });

  final bool isUser;
  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? AppTheme.primary : Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({required this.url, required this.radius});

  final String url;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final image = url.startsWith('data:')
        ? Image.memory(
            base64Decode(url.split(',').last),
            fit: BoxFit.cover,
            width: 220,
            height: 180,
          )
        : Image.network(
            url,
            fit: BoxFit.cover,
            width: 220,
            height: 180,
            errorBuilder: (_, _, _) => Container(
              width: 220,
              height: 180,
              color: const Color(0xFFE3F2FD),
              child: const Icon(Icons.broken_image, color: AppTheme.primary),
            ),
          );

    return ClipRRect(borderRadius: radius, child: image);
  }
}

class _VideoBody extends StatelessWidget {
  const _VideoBody({
    required this.radius,
    required this.isUser,
    required this.loc,
  });

  final BorderRadius radius;
  final bool isUser;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return _TextShell(
      isUser: isUser,
      radius: radius,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_fill,
            color: isUser ? Colors.white : AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            loc.videoLabel,
            style: TextStyle(
              color: isUser ? Colors.white : const Color(0xFF101828),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBody extends StatelessWidget {
  const _LocationBody({
    required this.content,
    required this.isUser,
    required this.radius,
    required this.loc,
  });

  final String content;
  final bool isUser;
  final BorderRadius radius;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final parts = content.replaceFirst('location:', '').split(',');
    final lat = double.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final lng = double.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

    return GestureDetector(
      onTap: () async {
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        );
        await launchUrl(url, mode: LaunchMode.externalApplication);
      },
      child: _TextShell(
        isUser: isUser,
        radius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: isUser ? Colors.white : AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  loc.currentLocation,
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF101828),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
              style: TextStyle(
                color: isUser
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF667085),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceBody extends StatelessWidget {
  const _VoiceBody({
    required this.seconds,
    required this.isUser,
    required this.radius,
    required this.loc,
  });

  final int seconds;
  final bool isUser;
  final BorderRadius radius;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final mm = (seconds ~/ 60).toString().padLeft(1, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return _TextShell(
      isUser: isUser,
      radius: radius,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow_rounded,
            color: isUser ? Colors.white : AppTheme.primary,
          ),
          const SizedBox(width: 6),
          ...List.generate(
            8,
            (i) => Container(
              width: 3,
              height: 8.0 + (i % 4) * 4,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppTheme.primary.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$mm:$ss',
            style: TextStyle(
              color: isUser ? Colors.white : const Color(0xFF101828),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
