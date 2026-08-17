import 'package:flutter/foundation.dart';

/// Lightweight performance instrumentation (debug / profile only).
class PerformanceMonitor {
  PerformanceMonitor._();
  static final PerformanceMonitor instance = PerformanceMonitor._();

  final _marks = <String, DateTime>{};

  void mark(String label) {
    if (!kDebugMode) return;
    _marks[label] = DateTime.now();
    debugPrint('[perf] mark: $label');
  }

  void measure(String label, String since) {
    if (!kDebugMode) return;
    final start = _marks[since];
    if (start == null) return;
    final ms = DateTime.now().difference(start).inMilliseconds;
    debugPrint('[perf] $label: ${ms}ms (since $since)');
  }
}
