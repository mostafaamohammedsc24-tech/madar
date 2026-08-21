import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../theme/publisher_tokens.dart';

/// Stitch publisher shell: Madar · PUBLISHING header + Work/Properties/Requests/Messages/Profile.
class PublisherShell extends StatelessWidget {
  const PublisherShell({required this.child, super.key});

  final Widget child;

  static const _tabs = <_PubTab>[
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
    for (var i = 0; i < _tabs.length; i++) {
      for (final m in _tabs[i].match) {
        if (location == m || location.startsWith('$m/') || location.startsWith('$m?')) {
          return i;
        }
      }
    }
    // Other publishing nested tools still highlight Properties.
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
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: PublisherTokens.textTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: PublisherTokens.background,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: PublisherTokens.primary,
          secondary: PublisherTokens.secondary,
          surface: PublisherTokens.surface,
          onSurface: PublisherTokens.onSurface,
          onSurfaceVariant: PublisherTokens.onSurfaceVariant,
        ),
      ),
      child: Scaffold(
        backgroundColor: PublisherTokens.background,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: _PublisherHeader(
                onSearch: () => context.push('/employee/search'),
                onNotifications: () => context.push('/employee/notifications'),
                onProfile: () => context.go('/employee/profile'),
              ),
            ),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: Material(
          color: PublisherTokens.surface.withValues(alpha: 0.92),
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: PublisherTokens.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: EdgeInsets.only(bottom: bottom),
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go(_tabs[i].route),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selected == i
                                  ? _tabs[i].selectedIcon
                                  : _tabs[i].icon,
                              size: 24,
                              color: selected == i
                                  ? PublisherTokens.secondary
                                  : PublisherTokens.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tabs[i].label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: -0.2,
                                fontWeight: selected == i
                                    ? FontWeight.w600
                                    : FontWeight.w500,
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

class _PublisherHeader extends StatelessWidget {
  const _PublisherHeader({
    required this.onSearch,
    required this.onNotifications,
    required this.onProfile,
  });

  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: PublisherTokens.surface.withValues(alpha: 0.88),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Madar',
            style: PublisherTokens.textTheme(Theme.of(context).textTheme)
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: PublisherTokens.primary,
                  letterSpacing: -0.4,
                ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 1,
            height: 16,
            color: PublisherTokens.outlineVariant,
          ),
          Text(
            'PUBLISHING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: PublisherTokens.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            color: PublisherTokens.onSurfaceVariant,
          ),
          IconButton(
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_outlined),
            color: PublisherTokens.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: PublisherTokens.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
