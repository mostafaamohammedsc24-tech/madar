import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/madar_drag_handle.dart';
import '../models/chat_models.dart';

class ChatInputField extends StatelessWidget {
  const ChatInputField({
    super.key,
    required this.controller,
    required this.thread,
    required this.isRecording,
    required this.recordingSeconds,
    required this.busy,
    required this.onSend,
    required this.onToggleVoice,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onSendLocation,
    required this.onSendBarcode,
  });

  final TextEditingController controller;
  final ChatThread thread;
  final bool isRecording;
  final int recordingSeconds;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onToggleVoice;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onSendLocation;
  final VoidCallback onSendBarcode;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final hint = thread.kind == ChatThreadKind.agent
        ? loc.agentInputHint
        : loc.typeYourMessage;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: isRecording
              ? _RecordingBar(
                  seconds: recordingSeconds,
                  label: loc.recording,
                  onStop: onToggleVoice,
                )
              : Row(
                  children: [
                    IconButton(
                      onPressed: busy ? null : () => _openAttach(context, loc),
                      icon: const Icon(
                        Icons.attach_file_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => onSend(),
                          decoration: InputDecoration(
                            hintText: hint,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ValueListenableBuilder(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        final hasText = value.text.trim().isNotEmpty;
                        return IconButton(
                          onPressed: busy
                              ? null
                              : (hasText ? onSend : onToggleVoice),
                          icon: CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            child: Icon(
                              hasText
                                  ? Icons.send_rounded
                                  : Icons.mic_none_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _openAttach(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MadarDragHandle(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachAction(
                    icon: Icons.image_outlined,
                    label: loc.imageLabel,
                    onTap: () {
                      Navigator.pop(ctx);
                      onPickImage();
                    },
                  ),
                  _AttachAction(
                    icon: Icons.videocam_outlined,
                    label: loc.videoLabel,
                    onTap: () {
                      Navigator.pop(ctx);
                      onPickVideo();
                    },
                  ),
                  _AttachAction(
                    icon: Icons.location_on_outlined,
                    label: loc.locationLabel,
                    onTap: () {
                      Navigator.pop(ctx);
                      onSendLocation();
                    },
                  ),
                  if (thread.kind == ChatThreadKind.agent)
                    _AttachAction(
                      icon: Icons.qr_code_2,
                      label: loc.sendBarcode,
                      onTap: () {
                        Navigator.pop(ctx);
                        onSendBarcode();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachAction extends StatelessWidget {
  const _AttachAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFE3F2FD),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF344054),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  const _RecordingBar({
    required this.seconds,
    required this.label,
    required this.onStop,
  });

  final int seconds;
  final String label;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final ss = seconds.toString().padLeft(2, '0');
    return Row(
      children: [
        const Icon(Icons.fiber_manual_record, color: Color(0xFFD32F2F)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label 0:$ss',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFFD32F2F),
            ),
          ),
        ),
        TextButton(onPressed: onStop, child: const Text('OK')),
      ],
    );
  }
}
