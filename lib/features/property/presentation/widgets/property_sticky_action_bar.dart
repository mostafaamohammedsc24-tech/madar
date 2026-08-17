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
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: onContact,
              icon: const Icon(Icons.phone_outlined, size: 20),
              label: Text(
                loc.contactSalesShort,
                textAlign: TextAlign.center,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: onAskAi,
                  icon: Icon(
                    Icons.psychology_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    loc.askAi,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onScheduleTour,
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    loc.scheduleVisit,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
