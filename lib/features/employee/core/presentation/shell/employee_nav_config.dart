import 'package:flutter/material.dart';

import '../../domain/employee_models.dart';

/// Fixed primary navigation for every employee — max 5 items.
/// Role-specific tools live inside Work, not the shell.
class EmployeeNavItem {
  const EmployeeNavItem({
    required this.route,
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
}

const List<EmployeeNavItem> kEmployeePrimaryNav = [
  EmployeeNavItem(
    route: '/employee/home',
    labelKey: 'home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  EmployeeNavItem(
    route: '/employee/work',
    labelKey: 'work',
    icon: Icons.work_outline,
    selectedIcon: Icons.work,
  ),
  EmployeeNavItem(
    route: '/employee/messages',
    labelKey: 'messages',
    icon: Icons.chat_bubble_outline,
    selectedIcon: Icons.chat_bubble,
  ),
  EmployeeNavItem(
    route: '/employee/notifications',
    labelKey: 'notifications',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
  ),
  EmployeeNavItem(
    route: '/employee/profile',
    labelKey: 'profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

List<EmployeeNavItem> navItemsFor(EmployeeAccount employee) =>
    List<EmployeeNavItem>.from(kEmployeePrimaryNav);

List<EmployeeNavItem> visibleNavItems(EmployeeAccount employee) =>
    navItemsFor(employee);

/// A single actionable queue row inside Work / Home.
class WorkQueueItem {
  const WorkQueueItem({
    required this.title,
    required this.count,
    required this.route,
    this.subtitle,
  });

  final String title;
  final int count;
  final String route;
  final String? subtitle;
}
