import 'package:flutter/material.dart';

import '../../../../core/layout/directional_layout.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';

/// Floating photo chrome: back circle, white action pill, agent avatar.
class PropertyReportOverlayChrome extends StatelessWidget {
  const PropertyReportOverlayChrome({
    super.key,
    required this.saved,
    required this.onBack,
    required this.onSave,
    required this.onShare,
    required this.onAskAi,
    required this.onMore,
    this.avatarUrl,
  });

  final bool saved;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onAskAi;
  final VoidCallback onMore;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Row(
        children: [
          _RoundGlassButton(
            icon: DirectionalBackIcon(color: Colors.black87),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: onBack,
          ),
          const Spacer(),
          Material(
            color: Colors.white.withValues(alpha: 0.94),
            elevation: 2,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PillIcon(
                    icon: saved ? Icons.favorite : Icons.favorite_border,
                    color: saved ? const Color(0xFFE53935) : Colors.black87,
                    tooltip: saved ? loc.savedProperty : loc.unsavedProperty,
                    onTap: onSave,
                  ),
                  _pillDivider(),
                  _PillIcon(
                    icon: Icons.share_outlined,
                    tooltip: loc.shareProperty,
                    onTap: onShare,
                  ),
                  _pillDivider(),
                  _PillIcon(
                    icon: Icons.auto_awesome,
                    color: AppTheme.primary,
                    tooltip: loc.askAi,
                    onTap: onAskAi,
                  ),
                  _pillDivider(),
                  _PillIcon(
                    icon: Icons.more_vert,
                    tooltip: loc.moreDetails,
                    onTap: onMore,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person_outline, size: 18, color: Colors.black54)
                : null,
          ),
        ],
      ),
    );
  }

  static Widget _pillDivider() => Container(
        width: 1,
        height: 18,
        color: const Color(0xFFE0E0E0),
      );
}

class _RoundGlassButton extends StatelessWidget {
  const _RoundGlassButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: icon,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _PillIcon extends StatelessWidget {
  const _PillIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: Icon(icon, size: 20, color: color ?? Colors.black87),
    );
  }
}
