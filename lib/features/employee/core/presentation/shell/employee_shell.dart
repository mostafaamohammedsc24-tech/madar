import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../theme/app_theme.dart';
import '../providers/employee_auth_notifier.dart';
import 'employee_nav_config.dart';

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
    final useSidebar = width >= 900;
    final items = visibleNavItems(employee);
    final loc = AppLocalizations.of(context);
    final location = GoRouterState.of(context).uri.toString();

    String labelFor(EmployeeNavItem item) {
      switch (item.labelKey) {
        case 'home':
          return loc.empNavHome;
        case 'finOps':
          return loc.empNavFinOps;
        case 'deposits':
          return loc.empNavDeposits;
        case 'offices':
          return loc.empNavOffices;
        case 'commissions':
          return loc.empNavCommissions;
        case 'settlements':
          return loc.empNavSettlements;
        case 'audit':
          return loc.empNavAudit;
        case 'notifications':
          return loc.empNavNotifications;
        case 'profile':
          return loc.empNavProfile;
        case 'operations':
          return loc.empNavOperations;
        case 'receipts':
          return loc.empNavReceipts;
        case 'reports':
          return loc.empNavReports;
        case 'photography':
          return loc.empNavPhotography;
        case 'chats':
          return loc.empNavChats;
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
      onNotifications: () => context.push('/employee/notifications'),
      onProfile: () => context.push('/employee/profile'),
    );

    if (useSidebar) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Row(
          children: [
            NavigationRail(
              extended: width >= 1100,
              selectedIndex: _indexFor(items, location).clamp(0, items.length - 1),
              onDestinationSelected: (i) => context.go(items[i].route),
              labelType: width >= 1100
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
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
      );
    }

    final mobileItems = items.take(5).toList();
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          SafeArea(bottom: false, child: header),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex:
            _indexFor(mobileItems, location).clamp(0, mobileItems.length - 1),
        onDestinationSelected: (i) => context.go(mobileItems[i].route),
        destinations: [
          for (final item in mobileItems)
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
    required this.onNotifications,
    required this.onProfile,
  });

  final String departmentName;
  final String employeeName;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

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
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              departmentName,
              style: theme.textTheme.labelMedium,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: onProfile,
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                employeeName.isNotEmpty ? employeeName[0].toUpperCase() : 'E',
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
