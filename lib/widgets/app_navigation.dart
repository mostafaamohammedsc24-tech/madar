import '../core/app_export.dart';
import '../core/localization/app_localizations.dart';

/// Shifting bottom navigation: active item expands into a light-blue pill
/// with icon + label; inactive items show outline icons only.
/// On narrow screens the active label is omitted so the pill never overflows.
class AppNavigation extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});

  static const Color _activeBlue = Color(0xFF1565C0);
  static const Color _activePill = Color(0xFFE3F0FD);
  static const Color _inactiveIcon = Color(0xFF3C4043);

  /// Below this width, active tabs stay icon-only (pill still highlights).
  static const double _labelMinWidth = 390;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final branch = navigationShell.currentIndex;
    final showLabels =
        MediaQuery.sizeOf(context).width >= _labelMinWidth;

    final items = <_NavItem>[
      _NavItem(
        label: loc.navSearch,
        icon: Icons.search,
        selectedIcon: Icons.search,
        active: branch == 0,
        onTap: () => navigationShell.goBranch(0, initialLocation: branch == 0),
      ),
      _NavItem(
        label: loc.navProperties,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        active: branch == 2,
        onTap: () => navigationShell.goBranch(2, initialLocation: branch == 2),
      ),
      _NavItem(
        label: loc.navMessages,
        icon: Icons.chat_bubble_outline_rounded,
        selectedIcon: Icons.chat_bubble_rounded,
        active: branch == 3,
        onTap: () => navigationShell.goBranch(3, initialLocation: branch == 3),
      ),
      _NavItem(
        label: loc.navDeals,
        icon: Icons.handshake_outlined,
        selectedIcon: Icons.handshake,
        active: branch == 1,
        onTap: () => navigationShell.goBranch(1, initialLocation: branch == 1),
      ),
      _NavItem(
        label: loc.navProfile,
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        active: branch == 4,
        onTap: () => navigationShell.goBranch(4, initialLocation: branch == 4),
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: items
                .map(
                  (item) => Expanded(
                    child: InkWell(
                      onTap: item.onTap,
                      splashColor: _activePill,
                      highlightColor: Colors.transparent,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 96),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(
                              horizontal: item.active && showLabels ? 10 : 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: item.active
                                  ? _activePill
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.active
                                      ? item.selectedIcon
                                      : item.icon,
                                  size: 22,
                                  color: item.active
                                      ? _activeBlue
                                      : _inactiveIcon,
                                ),
                                if (item.active && showLabels) ...[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _activeBlue,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool active;
  final VoidCallback onTap;
}
