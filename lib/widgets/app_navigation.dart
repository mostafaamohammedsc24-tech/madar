import '../core/app_export.dart';
import '../core/localization/app_localizations.dart';
import '../routes/app_routes.dart';

/// Zillow-style flat bottom navigation: Search, Updates, Favorites, Plan, Inbox.
/// Sits flush at the bottom with a hairline top border and a light-blue pill
/// behind the active item's icon.
class AppNavigation extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});

  static const Color _activeBlue = Color(0xFF1565C0);
  static const Color _activePill = Color(0xFFE3F0FD);
  static const Color _inactiveIcon = Color(0xFF3C4043);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final branch = navigationShell.currentIndex;

    final items = <_NavItem>[
      _NavItem(
        label: loc.navSearch,
        icon: Icons.search,
        active: branch == 0,
        onTap: () => navigationShell.goBranch(0, initialLocation: branch == 0),
      ),
      _NavItem(
        label: loc.navUpdates,
        icon: Icons.saved_search,
        active: false,
        onTap: () => context.push(AppRoutes.notificationCenter),
      ),
      _NavItem(
        label: loc.navFavorites,
        icon: Icons.favorite_border,
        active: branch == 2,
        onTap: () => navigationShell.goBranch(2, initialLocation: branch == 2),
      ),
      _NavItem(
        label: loc.navPlan,
        icon: Icons.sell_outlined,
        active: branch == 1,
        onTap: () => navigationShell.goBranch(1, initialLocation: branch == 1),
      ),
      _NavItem(
        label: loc.navInbox,
        icon: Icons.inbox_outlined,
        active: branch == 3,
        onTap: () => navigationShell.goBranch(3, initialLocation: branch == 3),
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
          height: 62,
          child: Row(
            children: items
                .map(
                  (item) => Expanded(
                    child: InkWell(
                      onTap: item.onTap,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: item.active
                                  ? _activePill
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              item.icon,
                              size: 24,
                              color: item.active ? _activeBlue : _inactiveIcon,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  item.active ? FontWeight.w700 : FontWeight.w500,
                              color: item.active ? _activeBlue : _inactiveIcon,
                            ),
                          ),
                        ],
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
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
}
