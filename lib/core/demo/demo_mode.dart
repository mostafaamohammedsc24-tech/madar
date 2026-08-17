/// Local preview / inspect mode (`--dart-define=DEMO_ENTER_USER_UI=true`).
abstract final class DemoMode {
  static const bool enabled = bool.fromEnvironment(
    'DEMO_ENTER_USER_UI',
    defaultValue: false,
  );

  static const String officeCode = 'OFF001';
  static const String employeeCode = 'EMP001';
  static const String secret = '123456';
  static const String otp = '123456';
}
