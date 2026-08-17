import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/employee_auth_notifier.dart';
import '../../domain/employee_permissions.dart';
import '../../../finance/presentation/screens/finance_dashboard_screen.dart';
import '../../../bank/presentation/screens/bank_dashboard_screen.dart';
import '../../../office_management/presentation/screens/om_dashboard_screen.dart';

/// Routes to the correct department workspace dashboard.
class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<EmployeeAuthNotifier>().employee;
    if (employee == null) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (employee.department.departmentCode) {
      case EmployeeDepartmentCode.finance:
        return const FinanceDashboardScreen();
      case EmployeeDepartmentCode.bank:
        return const BankDashboardScreen();
      case EmployeeDepartmentCode.officeManagement:
        return const OmDashboardScreen();
      case EmployeeDepartmentCode.unknown:
        return const Center(child: Text('No workspace assigned'));
    }
  }
}
