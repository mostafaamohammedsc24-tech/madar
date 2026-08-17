import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class PropertyStickyActionBar extends StatelessWidget {
  const PropertyStickyActionBar({
    super.key,
    required this.isSaved,
    required this.onSave,
    required this.onShare,
    required this.onContact,
    required this.onAskAi,
    required this.onScheduleTour,
  });

  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onContact;
  final VoidCallback onAskAi;
  final VoidCallback onScheduleTour;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 10, 8, 10 + bottom),
        child: Row(
          children: [
            IconButton(
              onPressed: onSave,
              tooltip: isSaved ? loc.savedProperty : loc.unsavedProperty,
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              onPressed: onShare,
              tooltip: loc.shareProperty,
              icon: Icon(
                Icons.share_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: FilledButton(
                onPressed: onContact,
                child: Text(
                  loc.contactSalesTeam,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onAskAi,
              tooltip: loc.askAi,
              icon: Icon(
                Icons.psychology_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            IconButton(
              onPressed: onScheduleTour,
              tooltip: loc.scheduleVisit,
              icon: Icon(
                Icons.calendar_month_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
