/// Compile-time demo flag. Production builds must leave this unset/false.
abstract final class DemoMode {
  static const bool enabled = bool.fromEnvironment(
    'DEMO_ENTER_USER_UI',
    defaultValue: false,
  );
}
