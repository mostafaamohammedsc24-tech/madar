import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../presentation/search_map_screen/models/property_data.dart';
import '../../domain/models/property_report.dart';
import 'package:provider/provider.dart' as provider;

class PropertyCompareSheet extends StatelessWidget {
  const PropertyCompareSheet({
    super.key,
    required this.base,
    required this.candidates,
  });

  final PropertyReport base;
  final List<PropertyData> candidates;

  static Future<void> show(
    BuildContext context, {
    required PropertyReport base,
    required List<PropertyData> candidates,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => PropertyCompareSheet(
          base: base,
          candidates: candidates,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = provider.Provider.of<LocaleProvider>(context).language;
    final others = candidates
        .where((p) => p.id != base.id)
        .take(12)
        .toList();

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              loc.compareProperty,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: others.isEmpty
                ? Center(child: Text(loc.informationUnavailable))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: others.length,
                    itemBuilder: (_, i) {
                      final p = others[i];
                      return _CompareCard(
                        base: base,
                        other: p,
                        language: language,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.base,
    required this.other,
    required this.language,
  });

  final PropertyReport base;
  final PropertyData other;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final basePrice = base.pricing.currentPrice?.amount;
    final otherPerSqm = other.area > 0 ? other.price / other.area : null;
    final basePerSqm = base.pricing.pricePerSqm?.amount;

    final rows = <(String, String, String)>[
      (
        loc.currentPrice,
        base.pricing.currentPrice?.format() ?? '—',
        other.formattedPrice,
      ),
      (
        loc.sqmPrice,
        basePerSqm != null
            ? base.pricing.pricePerSqm!.format()
            : '—',
        otherPerSqm != null
            ? '${otherPerSqm.toStringAsFixed(0)} ${other.currency}/m²'
            : '—',
      ),
      (
        loc.propertyAreaShort,
        base.areas.primary?.format() ?? '—',
        '${other.area.toInt()} m²',
      ),
      (
        loc.bedrooms,
        '${base.facts.bedrooms ?? '—'}',
        other.bedrooms > 0 ? '${other.bedrooms}' : '—',
      ),
      (
        loc.bathrooms,
        '${base.facts.bathrooms ?? '—'}',
        other.bathrooms > 0 ? '${other.bathrooms}' : '—',
      ),
      (
        loc.yearBuilt,
        '${base.facts.yearBuilt ?? base.construction?.yearBuilt ?? '—'}',
        other.yearBuilt > 0 ? '${other.yearBuilt}' : '—',
      ),
      (
        loc.propertyTypeLabel,
        base.facts.propertyType ?? '—',
        other.typeLabel(AppLocalizations.of(context)),
      ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              other.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              other.localizedAddress(language),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    base.title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.compare_arrows, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    other.title,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        r.$1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        r.$3,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _deltaColor(basePrice, other.price, r.$1, loc),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _deltaColor(
    double? basePrice,
    double otherPrice,
    String label,
    AppLocalizations loc,
  ) {
    if (label != loc.currentPrice || basePrice == null || basePrice <= 0) {
      return null;
    }
    if (otherPrice < basePrice) return Colors.green.shade700;
    if (otherPrice > basePrice) return Colors.red.shade700;
    return null;
  }
}
