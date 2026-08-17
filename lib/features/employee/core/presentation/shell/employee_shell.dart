import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../theme/app_theme.dart';
import '../providers/employee_auth_notifier.dart';
import 'employee_nav_config.dart';

/// Single employee platform shell: Logo · Search · avatar header +
/// Home / Work / Messages / Notifications / Profile.
class EmployeeShell extends StatelessWidget {
  const EmployeeShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<EmployeeAuthNotifier>();
    final employee = auth.employee;
    if (employee == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 1000;
    final items = visibleNavItems(employee);
    final loc = AppLocalizations.of(context);
    final location = GoRouterState.of(context).uri.toString();

    String labelFor(EmployeeNavItem item) {
      switch (item.labelKey) {
        case 'home':
          return loc.empNavHome;
        case 'work':
          return loc.empNavWork;
        case 'messages':
          return loc.empNavMessages;
        case 'notifications':
          return loc.empNavNotifications;
        case 'profile':
          return loc.empNavProfile;
        default:
          return item.labelKey;
      }
    }

    final header = _EmployeeHeader(
      departmentName: employee.department.localizedName(
        Localizations.localeOf(context).languageCode,
      ),
      employeeName: employee.fullName,
      onSearch: () => context.push('/employee/search'),
      onAvatar: () => context.go('/employee/profile'),
    );

    final selected = _indexFor(items, location).clamp(0, items.length - 1);

    if (useRail) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Column(
          children: [
            header,
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: selected,
                    onDestinationSelected: (i) => context.go(items[i].route),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final item in items)
                        NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(labelFor(item)),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          SafeArea(bottom: false, child: header),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(items[i].route),
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: labelFor(item),
            ),
        ],
      ),
    );
  }

  int _indexFor(List<EmployeeNavItem> items, String location) {
    // Nested work routes keep Work tab selected.
    if (location.startsWith('/employee/work') ||
        location.startsWith('/employee/finance') ||
        location.startsWith('/employee/bank') ||
        location.startsWith('/employee/om') ||
        location.startsWith('/employee/publishing') ||
        location.startsWith('/employee/information') ||
        location.startsWith('/employee/media') ||
        location.startsWith('/employee/engineering') ||
        location.startsWith('/employee/sales') ||
        location.startsWith('/employee/legal') ||
        location.startsWith('/employee/hr') ||
        location.startsWith('/employee/closing') ||
        location.startsWith('/employee/support') ||
        location.startsWith('/employee/audit')) {
      return items.indexWhere((e) => e.route == '/employee/work').clamp(0, 4);
    }
    for (var i = 0; i < items.length; i++) {
      if (location == items[i].route ||
          location.startsWith('${items[i].route}/')) {
        return i;
      }
    }
    return 0;
  }
}

class _EmployeeHeader extends StatelessWidget {
  const _EmployeeHeader({
    required this.departmentName,
    required this.employeeName,
    required this.onSearch,
    required this.onAvatar,
  });

  final String departmentName;
  final String employeeName;
  final VoidCallback onSearch;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Madar',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              departmentName,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
          InkWell(
            onTap: onAvatar,
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                employeeName.isNotEmpty ? employeeName[0].toUpperCase() : 'E',
                style: theme.textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
