import 'package:flutter/material.dart';

import '../../domain/employee_models.dart';
import '../../domain/employee_permissions.dart';

class EmployeeNavItem {
  const EmployeeNavItem({
    required this.route,
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
    this.requiredPermission,
  });

  final String route;
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
  final String? requiredPermission;
}

List<EmployeeNavItem> navItemsFor(EmployeeAccount employee) {
  switch (employee.department.departmentCode) {
    case EmployeeDepartmentCode.finance:
      return const [
        EmployeeNavItem(
          route: '/employee/home',
          labelKey: 'home',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          requiredPermission: EmployeePermission.financialView,
        ),
        EmployeeNavItem(
          route: '/employee/finance/transactions',
          labelKey: 'finOps',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          requiredPermission: EmployeePermission.financialView,
        ),
        EmployeeNavItem(
          route: '/employee/finance/deposits',
          labelKey: 'deposits',
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet,
          requiredPermission: EmployeePermission.financialView,
        ),
        EmployeeNavItem(
          route: '/employee/finance/offices',
          labelKey: 'offices',
          icon: Icons.storefront_outlined,
          selectedIcon: Icons.storefront,
          requiredPermission: EmployeePermission.financialView,
        ),
        EmployeeNavItem(
          route: '/employee/finance/commissions',
          labelKey: 'commissions',
          icon: Icons.percent_outlined,
          selectedIcon: Icons.percent,
          requiredPermission: EmployeePermission.financialRules,
        ),
        EmployeeNavItem(
          route: '/employee/finance/settlements',
          labelKey: 'settlements',
          icon: Icons.handshake_outlined,
          selectedIcon: Icons.handshake,
          requiredPermission: EmployeePermission.financialSettlement,
        ),
        EmployeeNavItem(
          route: '/employee/audit',
          labelKey: 'audit',
          icon: Icons.policy_outlined,
          selectedIcon: Icons.policy,
          requiredPermission: EmployeePermission.auditView,
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
    case EmployeeDepartmentCode.bank:
      return const [
        EmployeeNavItem(
          route: '/employee/home',
          labelKey: 'home',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
        ),
        EmployeeNavItem(
          route: '/employee/bank/transactions',
          labelKey: 'operations',
          icon: Icons.list_alt_outlined,
          selectedIcon: Icons.list_alt,
          requiredPermission: EmployeePermission.transactionsView,
        ),
        EmployeeNavItem(
          route: '/employee/bank/deposits',
          labelKey: 'deposits',
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments,
          requiredPermission: EmployeePermission.bankDepositConfirm,
        ),
        EmployeeNavItem(
          route: '/employee/bank/receipts',
          labelKey: 'receipts',
          icon: Icons.description_outlined,
          selectedIcon: Icons.description,
          requiredPermission: EmployeePermission.bankReceiptCreate,
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
    case EmployeeDepartmentCode.officeManagement:
      return const [
        EmployeeNavItem(
          route: '/employee/home',
          labelKey: 'home',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
        ),
        EmployeeNavItem(
          route: '/employee/om/offices',
          labelKey: 'offices',
          icon: Icons.apartment_outlined,
          selectedIcon: Icons.apartment,
          requiredPermission: EmployeePermission.officesView,
        ),
        EmployeeNavItem(
          route: '/employee/om/reports',
          labelKey: 'reports',
          icon: Icons.flag_outlined,
          selectedIcon: Icons.flag,
          requiredPermission: EmployeePermission.propertiesView,
        ),
        EmployeeNavItem(
          route: '/employee/om/photography',
          labelKey: 'photography',
          icon: Icons.photo_camera_outlined,
          selectedIcon: Icons.photo_camera,
          requiredPermission: EmployeePermission.propertiesPublishRequest,
        ),
        EmployeeNavItem(
          route: '/employee/om/conversations',
          labelKey: 'chats',
          icon: Icons.chat_bubble_outline,
          selectedIcon: Icons.chat_bubble,
          requiredPermission: EmployeePermission.messagesView,
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
    case EmployeeDepartmentCode.publishing:
      return const [
        EmployeeNavItem(
          route: '/employee/home',
          labelKey: 'home',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          requiredPermission: EmployeePermission.publishingView,
        ),
        EmployeeNavItem(
          route: '/employee/publishing/requests',
          labelKey: 'requests',
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          requiredPermission: EmployeePermission.publishingView,
        ),
        EmployeeNavItem(
          route: '/employee/publishing/create',
          labelKey: 'newRequest',
          icon: Icons.add_box_outlined,
          selectedIcon: Icons.add_box,
          requiredPermission: EmployeePermission.publishingCreate,
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
    case EmployeeDepartmentCode.information:
      return const [
        EmployeeNavItem(
          route: '/employee/home',
          labelKey: 'home',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          requiredPermission: EmployeePermission.informationView,
        ),
        EmployeeNavItem(
          route: '/employee/information/assigned',
          labelKey: 'assigned',
          icon: Icons.home_work_outlined,
          selectedIcon: Icons.home_work,
          requiredPermission: EmployeePermission.informationView,
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
    case EmployeeDepartmentCode.photography:
      return const [
        EmployeeNavItem(
          route: '/employee/home',
          labelKey: 'home',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          requiredPermission: EmployeePermission.mediaView,
        ),
        EmployeeNavItem(
          route: '/employee/media/assigned',
          labelKey: 'shoots',
          icon: Icons.photo_camera_outlined,
          selectedIcon: Icons.photo_camera,
          requiredPermission: EmployeePermission.mediaView,
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
    case EmployeeDepartmentCode.engineering:
      return const [
        EmployeeNavItem(
          route: '/employee/home',
          labelKey: 'home',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          requiredPermission: EmployeePermission.engineeringView,
        ),
        EmployeeNavItem(
          route: '/employee/engineering/assigned',
          labelKey: 'floorPlans',
          icon: Icons.architecture_outlined,
          selectedIcon: Icons.architecture,
          requiredPermission: EmployeePermission.engineeringView,
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
    case EmployeeDepartmentCode.unknown:
      return const [
        EmployeeNavItem(
          route: '/employee/home',
          labelKey: 'home',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
        ),
        EmployeeNavItem(
          route: '/employee/profile',
          labelKey: 'profile',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
        ),
      ];
  }
}

List<EmployeeNavItem> visibleNavItems(EmployeeAccount employee) {
  return navItemsFor(employee)
      .where(
        (i) =>
            i.requiredPermission == null ||
            employee.can(i.requiredPermission!),
      )
      .toList();
}
