import '../core/app_export.dart';
import '../core/localization/app_localizations.dart';

// V2 Floating Pill BottomNav — LOCKED core technique
// Detached pill container floats above content, extendBody: true in AppScaffold

class _TabSpec {
  final String label;
  final String icon;
  final String selectedIcon;
  final int? branchIndex;

  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation>
    with SingleTickerProviderStateMixin {
  int _selectedVisualIndex = 0;

  late AnimationController _animController;

  static const List<_TabSpec> _tabs = [
    _TabSpec(
      label: 'Search',
      icon: 'map_outlined',
      selectedIcon: 'map',
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Deals',
      icon: 'handshake_outlined',
      selectedIcon: 'handshake',
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'Properties',
      icon: 'home_work_outlined',
      selectedIcon: 'home_work',
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'Messages',
      icon: 'chat_bubble_outline',
      selectedIcon: 'chat_bubble',
      branchIndex: 3,
    ),
    _TabSpec(
      label: 'Profile',
      icon: 'person_outline',
      selectedIcon: 'person',
      branchIndex: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _syncVisualIndex();
  }

  void _syncVisualIndex() {
    final currentBranch = widget.navigationShell.currentIndex;
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].branchIndex == currentBranch) {
        _selectedVisualIndex = i;
        break;
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTabTap(int visualIndex) {
    final tab = _tabs[visualIndex];
    if (tab.branchIndex == null) return;
    setState(() => _selectedVisualIndex = visualIndex);
    widget.navigationShell.goBranch(
      tab.branchIndex!,
      initialLocation: tab.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final loc = AppLocalizations.of(context);

    final tabLabels = [
      loc.navSearch,
      loc.navDeals,
      loc.navProperties,
      loc.navMessages,
      loc.navProfile,
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(36),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            final isActive = i == _selectedVisualIndex;

            return GestureDetector(
              onTap: () => _onTabTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 16 : 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primary.withAlpha(31)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: isActive ? tab.selectedIcon : tab.icon,
                      color: isActive
                          ? AppTheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: isActive
                          ? Row(
                              children: [
                                const SizedBox(width: 6),
                                Text(
                                  tabLabels[i],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
