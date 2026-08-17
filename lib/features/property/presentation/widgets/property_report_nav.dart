import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

/// Horizontal section navigator for the property report.
class PropertyReportNav extends StatelessWidget {
  const PropertyReportNav({
    super.key,
    required this.sections,
    required this.onTap,
  });

  final List<ReportNavItem> sections;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = sections[i];
          return ActionChip(
            label: Text(s.label),
            onPressed: () => onTap(s.key),
            backgroundColor: theme.colorScheme.surface,
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class ReportNavItem {
  const ReportNavItem({required this.key, required this.label});
  final String key;
  final String label;
}

List<ReportNavItem> buildReportNavItems(AppLocalizations loc, dynamic report) {
  final items = <ReportNavItem>[
    ReportNavItem(key: 'overview', label: loc.reportOverview),
  ];
  if (report.showFacts) {
    items.add(ReportNavItem(key: 'facts', label: loc.factsAndFeatures));
  }
  if (report.showDimensions) {
    items.add(ReportNavItem(key: 'dimensions', label: loc.dimensionsSection));
  }
  if (report.showDescription || report.showWhatsSpecial) {
    items.add(ReportNavItem(key: 'details', label: loc.description));
  }
  items.add(ReportNavItem(key: 'financial', label: loc.priceAndValuation));
  if (report.showConstruction || report.showBuilder) {
    items.add(ReportNavItem(key: 'construction', label: loc.constructionSection));
  }
  if (report.showPriceHistory || report.showSalesHistory) {
    items.add(ReportNavItem(key: 'history', label: loc.salesHistory));
  }
  if (report.showMap || report.showNeighborhood || report.showNearby) {
    items.add(ReportNavItem(key: 'location', label: loc.locationHierarchy));
  }
  if (report.showInvestment || report.showMarketAnalytics) {
    items.add(ReportNavItem(key: 'investment', label: loc.investmentPotential));
  }
  if (report.showFutureProjects) {
    items.add(ReportNavItem(key: 'future', label: loc.futureOfArea));
  }
  if (report.showDocuments) {
    items.add(ReportNavItem(key: 'documents', label: loc.documents));
  }
  items.add(ReportNavItem(key: 'contact', label: loc.contactSalesTeam));
  return items;
}
