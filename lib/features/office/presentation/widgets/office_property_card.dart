import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../presentation/search_map_screen/search_map_screen.dart';
import '../../../../theme/app_theme.dart';

class OfficePropertyCard extends StatelessWidget {
  const OfficePropertyCard({
    super.key,
    required this.property,
    required this.onOpen,
    this.onFoundBuyer,
    this.onDismiss,
    this.officeName,
    this.compact = false,
    this.showFoundBuyer = true,
  });

  final PropertyData property;
  final VoidCallback onOpen;
  final VoidCallback? onFoundBuyer;
  final VoidCallback? onDismiss;
  final String? officeName;
  final bool compact;
  final bool showFoundBuyer;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black26,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      property.imageUrl,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 84,
                        height: 84,
                        color: AppTheme.surfaceVariantLight,
                        child: const Icon(Icons.home_work_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${property.price.toStringAsFixed(0)} ${property.currency}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${property.type} · ${property.listingType}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (officeName != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${loc.officeLabel}: $officeName',
                  style: theme.textTheme.labelSmall,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpen,
                      child: Text(loc.officeViewProperty),
                    ),
                  ),
                  if (showFoundBuyer && onFoundBuyer != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: onFoundBuyer,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                        ),
                        child: Text(loc.officeFoundBuyerCta),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
