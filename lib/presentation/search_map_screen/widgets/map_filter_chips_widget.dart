import '../../../core/app_export.dart';
import '../../../core/localization/app_localizations.dart';

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
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final option = options[i];
          final isSelected = option == selected;
          final label = loc.filterLabel(option);

          return GestureDetector(
            onTap: () => onChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option != 'All') ...[
                    CustomIconWidget(
                      iconName: _getIcon(option),
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
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
