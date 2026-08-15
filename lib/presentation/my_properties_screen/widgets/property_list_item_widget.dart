import '../../../core/app_export.dart';
import '../../../widgets/status_badge_widget.dart';

class MyPropertyData {
  final String id;
  final String status;
  final String title;
  final String imageUrl;
  final String semanticLabel;
  final String address;
  final String formattedValue;
  final double priceChange;
  final int dailyVisitors;
  final double area;
  final int bedrooms;
  final List<String> improvements;

  const MyPropertyData({
    required this.id,
    required this.status,
    required this.title,
    required this.imageUrl,
    required this.semanticLabel,
    required this.address,
    required this.formattedValue,
    required this.priceChange,
    required this.dailyVisitors,
    required this.area,
    required this.bedrooms,
    required this.improvements,
  });
}

// V4 Swipeable Action — Dismissible swipe + revealed action row — LOCKED
class PropertyListItemWidget extends StatelessWidget {
  final MyPropertyData property;
  final VoidCallback onDismissed;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  const PropertyListItemWidget({
    required this.property,
    required this.onDismissed,
    required this.onEdit,
    required this.onShare,
    super.key,
  });

  PropertyStatus _parseStatus(String s) {
    switch (s) {
      case 'active':
        return PropertyStatus.active;
      case 'underReview':
        return PropertyStatus.underReview;
      case 'sold':
        return PropertyStatus.sold;
      case 'rented':
        return PropertyStatus.rented;
      case 'pending':
        return PropertyStatus.pending;
      default:
        return PropertyStatus.active;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = property;
    final status = _parseStatus(p.status);

    return Dismissible(
      key: Key(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(iconName: 'delete', color: Colors.white, size: 24),
            const SizedBox(height: 4),
            const Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Remove Listing?'),
            content: Text(
              'Are you sure you want to remove "${p.title}" from your listings?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDismissed(),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
          // V4 Gradient Accent left border — LOCKED
          border: Border(
            left: BorderSide(
              color: p.priceChange < 0
                  ? AppTheme.error
                  : p.priceChange > 0
                  ? AppTheme.success
                  : AppTheme.primary,
              width: 4,
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Property image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                  child: CustomImageWidget(
                    imageUrl: p.imageUrl,
                    width: 100,
                    height: 110,
                    fit: BoxFit.cover,
                    semanticLabel: p.semanticLabel,
                  ),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.title,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadgeWidget(
                              status: _parseStatus(p.status),
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'location_on',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                p.address,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Value + price change
                        Row(
                          children: [
                            Text(
                              p.formattedValue,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (p.priceChange != 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: p.priceChange > 0
                                      ? AppTheme.successLight
                                      : AppTheme.errorLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomIconWidget(
                                      iconName: p.priceChange > 0
                                          ? 'arrow_upward'
                                          : 'keyboard_arrow_down',
                                      color: p.priceChange > 0
                                          ? AppTheme.success
                                          : AppTheme.error,
                                      size: 10,
                                    ),
                                    Text(
                                      '${p.priceChange.abs()}%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: p.priceChange > 0
                                            ? AppTheme.success
                                            : AppTheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Stats row
                        Row(
                          children: [
                            _MiniStat(
                              icon: 'visibility',
                              value: '${p.dailyVisitors}/day',
                            ),
                            const SizedBox(width: 10),
                            _MiniStat(
                              icon: 'square_foot',
                              value: '${p.area.toInt()}m²',
                            ),
                            if (p.bedrooms > 0) ...[
                              const SizedBox(width: 10),
                              _MiniStat(icon: 'bed', value: '${p.bedrooms} bd'),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Improvements section (if any)
            if (p.improvements.isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'trending_up',
                          color: AppTheme.warning,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Boost your listing',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.improvements.first,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.warning,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Action buttons row
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: 'edit',
                      label: 'Edit',
                      onTap: onEdit,
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppTheme.borderLight),
                  Expanded(
                    child: _ActionButton(
                      icon: 'share',
                      label: 'Share',
                      onTap: onShare,
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppTheme.borderLight),
                  Expanded(
                    child: _ActionButton(
                      icon: 'visibility',
                      label: 'Preview',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String icon;
  final String value;
  const _MiniStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomIconWidget(
          iconName: icon,
          color: AppTheme.primary.withAlpha(153),
          size: 11,
        ),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppTheme.primary.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(iconName: icon, color: AppTheme.primary, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}