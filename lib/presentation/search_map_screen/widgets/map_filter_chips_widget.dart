import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/listing_filter_theme.dart';

class MapFilterChipsWidget extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Function(String) onChanged;

  const MapFilterChipsWidget({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  String _getIcon(String option) {
    switch (option) {
      case 'Sale':
        return 'home';
      case 'Rent':
        return 'apartment';
      case 'Mortgage':
        return 'account_balance';
      case 'Land':
        return 'landscape';
      case 'Commercial':
        return 'store';
      case 'Investment':
        return 'trending_up';
      default:
        return 'map';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final option = options[i];
          final isSelected = option == selected;
          final label = loc.filterLabel(option);
          final accent = ListingFilterTheme.colorForFilter(option);
          final isAll = option == 'All';

          final bgColor = isSelected
              ? (isAll ? AppTheme.primary : accent)
              : (isAll
                  ? theme.colorScheme.surface
                  : accent.withValues(alpha: 0.12));
          final borderColor = isAll
              ? (isSelected
                  ? AppTheme.primary
                  : theme.colorScheme.outlineVariant)
              : accent.withValues(alpha: isSelected ? 1 : 0.55);
          final fgColor = isSelected
              ? Colors.white
              : (isAll ? theme.colorScheme.onSurface : accent);

          return GestureDetector(
            onTap: () => onChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: (isAll ? AppTheme.primary : accent).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isAll) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    CustomIconWidget(
                      iconName: _getIcon(option),
                      color: fgColor,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: fgColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
