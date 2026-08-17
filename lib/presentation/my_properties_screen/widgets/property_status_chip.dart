import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../models/owned_property.dart';

class PropertyStatusChip extends StatelessWidget {
  const PropertyStatusChip({super.key, required this.status});

  final OwnedListingStatus status;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final Color color;
    final String label;
    switch (status) {
      case OwnedListingStatus.active:
        color = AppTheme.success;
        label = loc.statusActiveLabel;
      case OwnedListingStatus.pending:
        color = AppTheme.warning;
        label = loc.statusPendingLabel;
      case OwnedListingStatus.underReview:
        color = AppTheme.warning;
        label = loc.underReview;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
