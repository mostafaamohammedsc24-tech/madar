import '../core/app_export.dart';
import '../core/localization/app_localizations.dart';

/// Shifting bottom navigation: active item expands into a light-blue pill
/// with icon + label; inactive items show outline icons only.
/// Order matches product mockups (LTR & RTL via [Directionality]):
/// Search · Properties · Messages · Deals · Profile.
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

    // Shell indices: 0 search, 1 deals/transactions, 2 properties, 3 messages, 4 profile
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
          height: 64,
          child: Row(
            children: items
                .map(
                  (item) => Expanded(
                    child: InkWell(
                      onTap: item.onTap,
                      splashColor: _activePill,
                      highlightColor: Colors.transparent,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: item.active ? 12 : 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: item.active
                                ? _activePill
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.active ? item.selectedIcon : item.icon,
                                size: 24,
                                color: item.active
                                    ? _activeBlue
                                    : _inactiveIcon,
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: item.active
                                    ? Padding(
                                        padding: const EdgeInsetsDirectional
                                            .only(start: 8),
                                        child: Text(
                                          item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _activeBlue,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
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
