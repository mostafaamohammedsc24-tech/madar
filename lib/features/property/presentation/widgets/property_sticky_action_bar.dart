import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class PropertyStickyActionBar extends StatelessWidget {
  const PropertyStickyActionBar({
    super.key,
    required this.onContact,
    required this.onAskAi,
    required this.onScheduleTour,
  });

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
            Expanded(
              child: FilledButton.icon(
                onPressed: onContact,
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: Text(
                  loc.contactSales,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
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
