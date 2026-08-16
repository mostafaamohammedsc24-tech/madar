import 'employee_permissions.dart';

class EmployeeDepartment {
  const EmployeeDepartment({
    required this.id,
    required this.code,
    required this.nameEn,
    this.nameAr,
    this.nameKu,
  });

  final String id;
  final String code;
  final String nameEn;
  final String? nameAr;
  final String? nameKu;

  EmployeeDepartmentCode get departmentCode => departmentFromCode(code);

  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr ?? nameEn;
      case 'ku':
        return nameKu ?? nameEn;
      default:
        return nameEn;
    }
  }

  factory EmployeeDepartment.fromMap(Map<String, dynamic> d) {
    return EmployeeDepartment(
      id: d['id']?.toString() ?? '',
      code: d['code'] as String? ?? '',
      nameEn: d['name_en'] as String? ?? '',
      nameAr: d['name_ar'] as String?,
      nameKu: d['name_ku'] as String?,
    );
  }
}

class EmployeeRole {
  const EmployeeRole({
    required this.id,
    required this.code,
    required this.nameEn,
    this.nameAr,
    this.nameKu,
  });

  final String id;
  final String code;
  final String nameEn;
  final String? nameAr;
  final String? nameKu;

  factory EmployeeRole.fromMap(Map<String, dynamic> d) {
    return EmployeeRole(
      id: d['id']?.toString() ?? '',
      code: d['code'] as String? ?? '',
      nameEn: d['name_en'] as String? ?? '',
      nameAr: d['name_ar'] as String?,
      nameKu: d['name_ku'] as String?,
    );
  }
}

class EmployeeAccount {
  const EmployeeAccount({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.department,
    required this.role,
    required this.permissions,
    this.profilePhotoUrl,
    this.jobTitle,
    this.countryCode = 'IQ',
    this.branchCode,
    this.region,
    this.employmentStatus = 'active',
    this.joiningDate,
    this.lastLoginAt,
  });

  final String id;
  final String employeeCode;
  final String fullName;
  final EmployeeDepartment department;
  final EmployeeRole role;
  final Set<String> permissions;
  final String? profilePhotoUrl;
  final String? jobTitle;
  final String countryCode;
  final String? branchCode;
  final String? region;
  final String employmentStatus;
  final DateTime? joiningDate;
  final DateTime? lastLoginAt;

  bool can(String permission) => permissions.contains(permission);

  bool get isFinance =>
      department.departmentCode == EmployeeDepartmentCode.finance;
  bool get isBank => department.departmentCode == EmployeeDepartmentCode.bank;
  bool get isOfficeManagement =>
      department.departmentCode == EmployeeDepartmentCode.officeManagement;

  factory EmployeeAccount.fromLoginMap(
    Map<String, dynamic> d,
    List<dynamic> perms,
  ) {
    return EmployeeAccount(
      id: d['id']?.toString() ?? '',
      employeeCode: d['employee_code'] as String? ?? '',
      fullName: d['full_name'] as String? ?? '',
      profilePhotoUrl: d['profile_photo_url'] as String?,
      jobTitle: d['job_title'] as String?,
      countryCode: d['country_code'] as String? ?? 'IQ',
      branchCode: d['branch_code'] as String?,
      region: d['region'] as String?,
      employmentStatus: d['employment_status'] as String? ?? 'active',
      joiningDate: d['joining_date'] != null
          ? DateTime.tryParse(d['joining_date'].toString())
          : null,
      lastLoginAt: d['last_login_at'] != null
          ? DateTime.tryParse(d['last_login_at'].toString())
          : null,
      department: EmployeeDepartment.fromMap(
        Map<String, dynamic>.from(d['department'] as Map? ?? {}),
      ),
      role: EmployeeRole.fromMap(
        Map<String, dynamic>.from(d['role'] as Map? ?? {}),
      ),
      permissions: perms.map((e) => e.toString()).toSet(),
    );
  }
}

class EmployeeSession {
  const EmployeeSession({
    required this.token,
    required this.employee,
    this.expiresAt,
  });

  final String token;
  final EmployeeAccount employee;
  final DateTime? expiresAt;
}

class FinanceDashboardStats {
  const FinanceDashboardStats({
    required this.pendingDeposits,
    required this.confirmedDeposits,
    required this.unpaid,
    required this.overdue,
    required this.awaitingSettlement,
    required this.officeAmountsDue,
    required this.companyRevenue,
    required this.pendingTransfers,
    required this.todaysOps,
  });

  final int pendingDeposits;
  final int confirmedDeposits;
  final int unpaid;
  final int overdue;
  final int awaitingSettlement;
  final double officeAmountsDue;
  final double companyRevenue;
  final int pendingTransfers;
  final int todaysOps;
}

class BankDashboardStats {
  const BankDashboardStats({
    required this.pendingDeposits,
    required this.todaysDeposits,
    required this.completedDeposits,
    required this.awaitingOtp,
    required this.verificationRequired,
    required this.failedVerification,
  });

  final int pendingDeposits;
  final int todaysDeposits;
  final int completedDeposits;
  final int awaitingOtp;
  final int verificationRequired;
  final int failedVerification;
}

class OfficeMgmtDashboardStats {
  const OfficeMgmtDashboardStats({
    required this.activeOffices,
    required this.pendingRequests,
    required this.newPropertyReports,
    required this.awaitingPhotography,
    required this.activeOfficeTransactions,
  });

  final int activeOffices;
  final int pendingRequests;
  final int newPropertyReports;
  final int awaitingPhotography;
  final int activeOfficeTransactions;
}
