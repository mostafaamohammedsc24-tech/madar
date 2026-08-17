import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/enums/data_provenance.dart';

class ProvenanceChip extends StatelessWidget {
  const ProvenanceChip({super.key, required this.provenance});

  final DataProvenance provenance;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (label, color) = switch (provenance) {
      DataProvenance.verified => (loc.dataVerified, theme.colorScheme.primary),
      DataProvenance.publisherProvided => (
          loc.dataPublisherProvided,
          theme.colorScheme.tertiary,
        ),
      DataProvenance.estimated => (
          loc.dataEstimated,
          theme.colorScheme.secondary,
        ),
      DataProvenance.external => (
          loc.dataExternal,
          theme.colorScheme.outline,
        ),
      DataProvenance.mockDemo => (
          loc.dataMockDemo,
          theme.colorScheme.error,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
