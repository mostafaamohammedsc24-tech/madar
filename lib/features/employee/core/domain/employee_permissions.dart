/// Permission codes — must match employee_permissions.code in DB.
abstract final class EmployeePermission {
  static const transactionsView = 'transactions.view';
  static const transactionsCreate = 'transactions.create';
  static const transactionsUpdate = 'transactions.update';
  static const financialView = 'financial.view';
  static const financialEdit = 'financial.edit';
  static const financialRules = 'financial.rules';
  static const financialSettlement = 'financial.settlement';
  static const financialReports = 'financial.reports';
  static const bankVerify = 'bank.verify';
  static const bankDepositConfirm = 'bank.deposit.confirm';
  static const bankReceiptCreate = 'bank.receipt.create';
  static const bankPartialDeposit = 'bank.partial_deposit';
  static const officesView = 'offices.view';
  static const officesCreate = 'offices.create';
  static const officesEdit = 'offices.edit';
  static const officesSuspend = 'offices.suspend';
  static const officesCredentialsReset = 'offices.credentials.reset';
  static const propertiesView = 'properties.view';
  static const propertiesAssign = 'properties.assign';
  static const propertiesPublishRequest = 'properties.publish.request';
  static const reportsView = 'reports.view';
  static const reportsExport = 'reports.export';
  static const messagesView = 'messages.view';
  static const messagesSend = 'messages.send';
  static const auditView = 'audit.view';
  static const searchGlobal = 'search.global';
}

enum EmployeeDepartmentCode { finance, bank, officeManagement, unknown }

EmployeeDepartmentCode departmentFromCode(String? code) {
  switch ((code ?? '').toLowerCase()) {
    case 'finance':
      return EmployeeDepartmentCode.finance;
    case 'bank':
      return EmployeeDepartmentCode.bank;
    case 'office_management':
      return EmployeeDepartmentCode.officeManagement;
    default:
      return EmployeeDepartmentCode.unknown;
  }
}

enum FinancialStatus {
  awaitingCalculation,
  amountDetermined,
  awaitingDeposit,
  partiallyDeposited,
  fullyDeposited,
  depositConfirmed,
  awaitingSettlement,
  readyForRelease,
  released,
  completed,
  overdue,
  blocked,
  disputed,
}

FinancialStatus financialStatusFromWire(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'amount_determined':
      return FinancialStatus.amountDetermined;
    case 'awaiting_deposit':
      return FinancialStatus.awaitingDeposit;
    case 'partially_deposited':
      return FinancialStatus.partiallyDeposited;
    case 'fully_deposited':
      return FinancialStatus.fullyDeposited;
    case 'deposit_confirmed':
      return FinancialStatus.depositConfirmed;
    case 'awaiting_settlement':
      return FinancialStatus.awaitingSettlement;
    case 'ready_for_release':
      return FinancialStatus.readyForRelease;
    case 'released':
      return FinancialStatus.released;
    case 'completed':
      return FinancialStatus.completed;
    case 'overdue':
      return FinancialStatus.overdue;
    case 'blocked':
      return FinancialStatus.blocked;
    case 'disputed':
      return FinancialStatus.disputed;
    default:
      return FinancialStatus.awaitingCalculation;
  }
}

String financialStatusWire(FinancialStatus s) {
  switch (s) {
    case FinancialStatus.awaitingCalculation:
      return 'awaiting_calculation';
    case FinancialStatus.amountDetermined:
      return 'amount_determined';
    case FinancialStatus.awaitingDeposit:
      return 'awaiting_deposit';
    case FinancialStatus.partiallyDeposited:
      return 'partially_deposited';
    case FinancialStatus.fullyDeposited:
      return 'fully_deposited';
    case FinancialStatus.depositConfirmed:
      return 'deposit_confirmed';
    case FinancialStatus.awaitingSettlement:
      return 'awaiting_settlement';
    case FinancialStatus.readyForRelease:
      return 'ready_for_release';
    case FinancialStatus.released:
      return 'released';
    case FinancialStatus.completed:
      return 'completed';
    case FinancialStatus.overdue:
      return 'overdue';
    case FinancialStatus.blocked:
      return 'blocked';
    case FinancialStatus.disputed:
      return 'disputed';
  }
}
