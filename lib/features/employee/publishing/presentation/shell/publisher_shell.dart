import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../theme/publisher_tokens.dart';

/// Adaptive Publisher shell — desktop sidebar, mobile bottom nav.
class PublisherShell extends StatelessWidget {
  const PublisherShell({required this.child, super.key});

  final Widget child;

  static const tabs = <_PubTab>[
    _PubTab(
      route: '/employee/work',
      label: 'Work',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      match: ['/employee/work'],
    ),
    _PubTab(
      route: '/employee/publishing/properties',
      label: 'Properties',
      icon: Icons.apartment_outlined,
      selectedIcon: Icons.apartment,
      match: [
        '/employee/publishing/properties',
        '/employee/publishing/property',
      ],
    ),
    _PubTab(
      route: '/employee/publishing/requests',
      label: 'Requests',
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
      match: [
        '/employee/publishing/requests',
        '/employee/publishing/create',
      ],
    ),
    _PubTab(
      route: '/employee/messages',
      label: 'Messages',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      match: ['/employee/messages'],
    ),
    _PubTab(
      route: '/employee/profile',
      label: 'Profile',
      icon: Icons.account_circle_outlined,
      selectedIcon: Icons.account_circle,
      match: ['/employee/profile'],
    ),
  ];

  int _selectedIndex(String location) {
    for (var i = 0; i < tabs.length; i++) {
      for (final m in tabs[i].match) {
        if (location == m ||
            location.startsWith('$m/') ||
            location.startsWith('$m?')) {
          return i;
        }
      }
    }
    if (location.startsWith('/employee/publishing')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<EmployeeAuthNotifier>();
    final employee = auth.employee;
    if (employee == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final location = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(location);
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final theme = Theme.of(context).copyWith(
      textTheme: PublisherTokens.textTheme(Theme.of(context).textTheme),
      scaffoldBackgroundColor: PublisherTokens.background,
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: PublisherTokens.primary,
        secondary: PublisherTokens.secondary,
        surface: PublisherTokens.surface,
        onSurface: PublisherTokens.onSurface,
        onSurfaceVariant: PublisherTokens.onSurfaceVariant,
      ),
    );

    final header = _PublisherHeader(
      employeeName: employee.fullName,
      onSearch: () => context.push('/employee/search'),
      onNotifications: () => context.push('/employee/notifications'),
      onProfile: () => context.go('/employee/profile'),
    );

    return Theme(
      data: theme,
      child: wide
          ? Scaffold(
              backgroundColor: PublisherTokens.background,
              body: Row(
                children: [
                  _DesktopRail(
                    selected: selected,
                    onSelect: (i) => context.go(tabs[i].route),
                    employeeName: employee.fullName,
                    employeeCode: employee.employeeCode,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        header,
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Scaffold(
              backgroundColor: PublisherTokens.background,
              body: Column(
                children: [
                  SafeArea(bottom: false, child: header),
                  Expanded(child: child),
                ],
              ),
              bottomNavigationBar: _MobileNav(
                selected: selected,
                onSelect: (i) => context.go(tabs[i].route),
              ),
            ),
    );
  }
}

class _PubTab {
  const _PubTab({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.match,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final List<String> match;
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.selected,
    required this.onSelect,
    required this.employeeName,
    required this.employeeCode,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final String employeeName;
  final String employeeCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: PublisherTokens.primary,
        border: Border(
          right: BorderSide(color: Color(0xFF1A365D)),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Madar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'PUBLISHING',
                    style: TextStyle(
                      color: PublisherTokens.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < PublisherShell.tabs.length; i++)
              _RailItem(
                label: PublisherShell.tabs[i].label,
                icon: selected == i
                    ? PublisherShell.tabs[i].selectedIcon
                    : PublisherShell.tabs[i].icon,
                selected: selected == i,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$employeeCode · Property Publisher',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1960A3).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xFFA2C9FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: PublisherTokens.surface.withValues(alpha: 0.96),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: PublisherTokens.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < PublisherShell.tabs.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected == i
                              ? PublisherShell.tabs[i].selectedIcon
                              : PublisherShell.tabs[i].icon,
                          size: 22,
                          color: selected == i
                              ? PublisherTokens.secondary
                              : PublisherTokens.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          PublisherShell.tabs[i].label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.2,
                            fontWeight:
                                selected == i ? FontWeight.w700 : FontWeight.w500,
                            color: selected == i
                                ? PublisherTokens.secondary
                                : PublisherTokens.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublisherHeader extends StatelessWidget {
  const _PublisherHeader({
    required this.employeeName,
    required this.onSearch,
    required this.onNotifications,
    required this.onProfile,
  });

  final String employeeName;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: PublisherTokens.card,
        border: Border(
          bottom: BorderSide(
            color: PublisherTokens.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!wide) ...[
            const Text(
              'Madar',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: PublisherTokens.primary,
                letterSpacing: -0.4,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 14,
              color: PublisherTokens.outlineVariant,
            ),
            const Text(
              'PUBLISHING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: PublisherTokens.onSurfaceVariant,
              ),
            ),
          ] else
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: TextField(
                    onTap: onSearch,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText:
                          'Search property ID, office, user, address, phone…',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: PublisherTokens.onSurfaceVariant
                            .withValues(alpha: 0.8),
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: PublisherTokens.surfaceLow,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!wide) const Spacer(),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            color: PublisherTokens.onSurfaceVariant,
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_outlined),
            color: PublisherTokens.onSurfaceVariant,
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: PublisherTokens.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                employeeName.isNotEmpty ? employeeName[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
