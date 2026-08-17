import 'package:flutter/material.dart';

import '../core/performance/performance_monitor.dart';

/// Loads a deferred Dart library then builds the route widget.
class DeferredRouteLoader extends StatefulWidget {
  const DeferredRouteLoader({
    super.key,
    required this.loadLibrary,
    required this.builder,
    this.loading,
  });

  final Future<void> Function() loadLibrary;
  final Widget Function() builder;
  final Widget? loading;

  @override
  State<DeferredRouteLoader> createState() => _DeferredRouteLoaderState();
}

class _DeferredRouteLoaderState extends State<DeferredRouteLoader> {
  late Future<void> _load;

  @override
  void initState() {
    super.initState();
    PerformanceMonitor.instance.mark('deferred_route_load');
    _load = widget.loadLibrary().whenComplete(() {
      PerformanceMonitor.instance.measure('deferred_route_ready', 'deferred_route_load');
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loading ??
              const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('${snapshot.error}'),
            ),
          );
        }
        return widget.builder();
      },
    );
  }
}

/// Lightweight skeleton for in-shell route transitions.
class RouteLoadingShell extends StatelessWidget {
  const RouteLoadingShell({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: theme.colorScheme.primary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
