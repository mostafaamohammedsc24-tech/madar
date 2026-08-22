import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/field_strings.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../providers/field_auth_notifier.dart';
import '../providers/field_workspace_controller.dart';

class FieldScaffold extends StatelessWidget {
  const FieldScaffold({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final rail = w >= 768;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? LegalTheme.darkBg : LegalTheme.paper,
      body: rail
          ? Row(children: [
              _Rail(shell: navigationShell, extended: w >= 1024),
              Expanded(child: Column(children: [const FieldTopBar(), Expanded(child: navigationShell)])),
            ])
          : Column(children: [const FieldTopBar(), Expanded(child: navigationShell), _Bottom(shell: navigationShell)]),
    );
  }
}

class FieldTopBar extends StatelessWidget {
  const FieldTopBar({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = FieldStrings.of(AppLocalizations.of(context));
    final auth = context.watch<FieldAuthNotifier>();
    final ws = context.watch<FieldWorkspaceController>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final staff = auth.staff;
    return Material(
      color: dark ? LegalTheme.navy : LegalTheme.surface,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: dark ? LegalTheme.darkElevated : LegalTheme.outline))),
        child: Row(children: [
          Text(loc.brand, style: LegalTheme.ibm(size: 18, weight: FontWeight.w700, color: LegalTheme.primary, letterSpacing: 1.4)),
          const SizedBox(width: 12),
          Container(width: 1, height: 28, color: LegalTheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loc.dept, style: LegalTheme.ibm(size: 15, weight: FontWeight.w600, color: dark ? LegalTheme.darkText : LegalTheme.charcoal)),
              Text('${loc.role}  ·  ${staff?.employeeId ?? 'INF-0020'}', style: LegalTheme.ibm(size: 11, color: LegalTheme.muted)),
            ]),
          ),
          if (staff != null)
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(staff.displayName, style: LegalTheme.ibm(size: 12, weight: FontWeight.w600)),
              Text(staff.employeeId, style: LegalTheme.mono(size: 11, color: LegalTheme.muted)),
            ]),
          IconButton(tooltip: loc.notifications, onPressed: () => context.go('/field/profile'), icon: Badge(isLabelVisible: ws.unreadCount > 0, label: Text('${ws.unreadCount}'), child: const Icon(Icons.notifications_none_outlined))),
          IconButton(onPressed: () => context.go('/field/profile'), icon: const Icon(Icons.person_outline)),
        ]),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.shell, required this.extended});
  final StatefulNavigationShell shell;
  final bool extended;
  @override
  Widget build(BuildContext context) {
    final loc = FieldStrings.of(AppLocalizations.of(context));
    final items = _items(loc);
    return Material(
      color: LegalTheme.navy,
      child: SizedBox(
        width: extended ? 220 : 72,
        child: ListView(children: [
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 8),
            child: Text(extended ? loc.brand : 'م', style: LegalTheme.ibm(size: 16, weight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < items.length; i++)
            InkWell(
              onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 0, vertical: 12),
                decoration: BoxDecoration(color: shell.currentIndex == i ? LegalTheme.primary.withValues(alpha: 0.28) : null, borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
                  Icon(items[i].$1, color: shell.currentIndex == i ? Colors.white : LegalTheme.darkMuted, size: 20),
                  if (extended) ...[const SizedBox(width: 12), Flexible(child: Text(items[i].$2, style: LegalTheme.ibm(size: 13, color: Colors.white)))],
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Bottom extends StatelessWidget {
  const _Bottom({required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) {
    final items = _items(FieldStrings.of(AppLocalizations.of(context)));
    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? LegalTheme.darkSurface : LegalTheme.surface,
      child: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: LegalTheme.outline))),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom, top: 6),
        child: Row(children: List.generate(items.length, (i) {
          final on = shell.currentIndex == i;
          return Expanded(
            child: InkWell(
              onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(items[i].$1, size: 22, color: on ? LegalTheme.primary : LegalTheme.muted),
                  Text(items[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: LegalTheme.ibm(size: 9, color: on ? LegalTheme.primary : LegalTheme.muted)),
                ]),
              ),
            ),
          );
        })),
      ),
    );
  }
}

List<(IconData, String)> _items(FieldStrings loc) => [
      (Icons.assignment_outlined, loc.navWork),
      (Icons.event_outlined, loc.navAssign),
      (Icons.home_work_outlined, loc.navProps),
      (Icons.description_outlined, loc.navReports),
      (Icons.chat_bubble_outline, loc.navMsg),
      (Icons.inventory_2_outlined, loc.navArchive),
      (Icons.person_outline, loc.navProfile),
    ];

class FieldWorkspaceLoader extends StatefulWidget {
  const FieldWorkspaceLoader({required this.child, super.key});
  final Widget child;
  @override
  State<FieldWorkspaceLoader> createState() => _FieldWorkspaceLoaderState();
}

class _FieldWorkspaceLoaderState extends State<FieldWorkspaceLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<FieldWorkspaceController>().load());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
