import '../core/app_export.dart';
import './app_navigation.dart';

// V2 Floating Pill — screens sit above nav bar with proper padding
class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Nav bar height: pill padding (10*2) + icon (22) + vertical padding (8*2) + margin bottom (16) + system padding
    const navBarVisualHeight = 88.0;

    return Scaffold(
      extendBody: false,
      body: Stack(
        children: [
          // Screen content with bottom padding so it doesn't go behind nav bar
          Positioned.fill(
            bottom: navBarVisualHeight + bottomPadding,
            child: navigationShell,
          ),
          // Floating pill nav bar on top
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppNavigation(navigationShell: navigationShell),
          ),
        ],
      ),
    );
  }
}
