import 'package:flutter/material.dart';

/// Plays one delayed action in local demo recordings (`DEMO_ENTER_USER_UI`).
class DemoAutoAdvance extends StatefulWidget {
  const DemoAutoAdvance({
    super.key,
    required this.onAdvance,
    required this.child,
    this.delay = const Duration(milliseconds: 2800),
  });

  final VoidCallback onAdvance;
  final Widget child;
  final Duration delay;

  static const bool enabled = bool.fromEnvironment(
    'DEMO_ENTER_USER_UI',
    defaultValue: false,
  );

  @override
  State<DemoAutoAdvance> createState() => _DemoAutoAdvanceState();
}

class _DemoAutoAdvanceState extends State<DemoAutoAdvance> {
  @override
  void initState() {
    super.initState();
    if (!DemoAutoAdvance.enabled) return;
    Future<void>.delayed(widget.delay, () {
      if (mounted) widget.onAdvance();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
