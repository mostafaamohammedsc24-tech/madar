import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class PropertyStickyActionBar extends StatelessWidget {
  const PropertyStickyActionBar({
    super.key,
    required this.isSaved,
    required this.onSave,
    required this.onContact,
    required this.onAskAi,
    required this.onScheduleTour,
  });

  final bool isSaved;
  final VoidCallback onSave;
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
        padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
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
            Expanded(
              child: FilledButton(
                onPressed: onContact,
                child: Text(loc.contactConnect),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onAskAi,
                child: Text(loc.askAi),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onScheduleTour,
              tooltip: loc.scheduleTour,
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
