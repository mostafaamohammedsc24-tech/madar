import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/property_language.dart';

/// Compact translation CTA + original/translated toggle + subtle loading.
class PropertyTranslationBar extends StatelessWidget {
  const PropertyTranslationBar({
    super.key,
    required this.propertyLanguage,
    required this.userLanguage,
    required this.showTranslated,
    required this.isTranslating,
    required this.hasTranslation,
    required this.onTranslate,
    required this.onShowOriginal,
    required this.onShowTranslated,
  });

  final ContentLanguage propertyLanguage;
  final ContentLanguage userLanguage;
  final bool showTranslated;
  final bool isTranslating;
  final bool hasTranslation;
  final VoidCallback onTranslate;
  final VoidCallback onShowOriginal;
  final VoidCallback onShowTranslated;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.translate_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.propertyWrittenIn(
                    _langLabel(loc, propertyLanguage),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isTranslating) ...[
            Text(
              loc.translatingPropertyInfo,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 6),
            // Subtle skeleton lines
            _SkeletonLine(widthFactor: 0.92, theme: theme),
            const SizedBox(height: 6),
            _SkeletonLine(widthFactor: 0.7, theme: theme),
          ] else if (!hasTranslation) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                onPressed: onTranslate,
                icon: const Icon(Icons.translate, size: 18),
                label: Text(loc.translateTo(_langLabel(loc, userLanguage))),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(loc.originalContent),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(loc.translatedContent),
                      ),
                    ],
                    selected: {showTranslated},
                    onSelectionChanged: (s) {
                      if (s.first) {
                        onShowTranslated();
                      } else {
                        onShowOriginal();
                      }
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
            if (showTranslated) ...[
              const SizedBox(height: 8),
              Text(
                loc.aiGeneratedTranslation,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _langLabel(AppLocalizations loc, ContentLanguage lang) {
    switch (lang.normalized) {
      case 'ar':
        return loc.languageArabic;
      case 'en':
        return loc.languageEnglish;
      case 'ku':
        return loc.languageKurdish;
      default:
        return lang.displayName(loc.languageCode);
    }
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, required this.theme});

  final double widthFactor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
