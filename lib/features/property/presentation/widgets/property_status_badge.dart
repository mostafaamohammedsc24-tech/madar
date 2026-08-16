import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/enums/property_status.dart';

class PropertyStatusBadge extends StatelessWidget {
  const PropertyStatusBadge({super.key, required this.status});

  final PropertyStatus status;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (label, icon, color) = _meta(loc, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  (String, IconData, Color) _meta(AppLocalizations loc, ThemeData theme) {
    switch (status) {
      case PropertyStatus.forSale:
        return (loc.forSale, Icons.sell_outlined, const Color(0xFF2E7D32));
      case PropertyStatus.forRent:
        return (loc.forRent, Icons.key_outlined, const Color(0xFF1565C0));
      case PropertyStatus.rentToOwn:
        return (loc.leaseToOwn, Icons.home_work_outlined, const Color(0xFF6A1B9A));
      case PropertyStatus.mortgage:
        return (loc.mortgage, Icons.account_balance_outlined, const Color(0xFFEF6C00));
      case PropertyStatus.sold:
        return (loc.statusSold, Icons.check_circle_outline, const Color(0xFF546E7A));
      case PropertyStatus.pending:
        return (loc.pending, Icons.hourglass_empty, const Color(0xFFF9A825));
      case PropertyStatus.reserved:
        return (loc.statusReserved, Icons.bookmark_outline, const Color(0xFF00838F));
      case PropertyStatus.underReview:
        return (loc.statusUnderReview, Icons.rate_review_outlined, const Color(0xFF5D4037));
      case PropertyStatus.offMarket:
        return (loc.statusOffMarket, Icons.visibility_off_outlined, const Color(0xFF78909C));
      case PropertyStatus.investment:
        return (loc.investment, Icons.trending_up, const Color(0xFF00897B));
    }
  }
}
