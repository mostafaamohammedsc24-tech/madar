/// Local preview / inspect mode (`--dart-define=DEMO_ENTER_USER_UI=true`).
/// Production builds leave this false; no runtime path returns seed data.
abstract final class DemoMode {
  static const bool enabled = bool.fromEnvironment(
    'DEMO_ENTER_USER_UI',
    defaultValue: false,
  );

  // Unused legacy constants retained only so dormant seed helpers still compile.
  static const String officeCode = 'OFF001';
  static const String employeeCode = 'EMP001';
  static const String secret = '123456';
  static const String otp = '123456';
}
