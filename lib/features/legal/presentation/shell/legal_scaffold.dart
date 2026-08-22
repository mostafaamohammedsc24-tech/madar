import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/legal_strings.dart';
import '../providers/legal_auth_notifier.dart';
import '../providers/legal_workspace_controller.dart';
import '../theme/legal_theme.dart';

class LegalScaffold extends StatelessWidget {
  const LegalScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 1024;
    final tablet = width >= 768;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? LegalTheme.darkBg : LegalTheme.paper,
      body: desktop || tablet
          ? Row(
              children: [
                _NavRail(
                  shell: navigationShell,
                  extended: desktop,
                ),
                Expanded(
                  child: Column(
                    children: [
                      const LegalTopBar(),
                      Expanded(child: navigationShell),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                const LegalTopBar(),
                Expanded(child: navigationShell),
                _BottomNav(shell: navigationShell),
              ],
            ),
    );
  }
}

class LegalTopBar extends StatelessWidget {
  const LegalTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final auth = context.watch<LegalAuthNotifier>();
    final ws = context.watch<LegalWorkspaceController>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final staff = auth.staff;

    return Material(
      color: dark ? LegalTheme.navy : LegalTheme.surface,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: dark ? LegalTheme.darkElevated : LegalTheme.outline,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              loc.brand,
              style: LegalTheme.ibm(
                size: 18,
                weight: FontWeight.w700,
                color: LegalTheme.primary,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 28, color: LegalTheme.outline),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.legalOperations,
                    style: LegalTheme.ibm(
                      size: 15,
                      weight: FontWeight.w600,
                      color: dark ? LegalTheme.darkText : LegalTheme.charcoal,
                    ),
                  ),
                  Text(
                    '${loc.contractLawyer}  ·  ${staff?.employeeId ?? 'LAW-0042'}',
                    style: LegalTheme.ibm(size: 11, color: LegalTheme.muted),
                  ),
                ],
              ),
            ),
            if (staff != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      staff.displayName,
                      style: LegalTheme.ibm(
                        size: 12,
                        weight: FontWeight.w600,
                        color: dark ? LegalTheme.darkText : LegalTheme.charcoal,
                      ),
                    ),
                    Text(
                      staff.employeeId,
                      style: LegalTheme.mono(size: 11, color: LegalTheme.muted),
                    ),
                  ],
                ),
              ),
            IconButton(
              tooltip: loc.notifications,
              onPressed: () => context.go('/legal/profile'),
              icon: Badge(
                isLabelVisible: ws.unreadCount > 0,
                label: Text('${ws.unreadCount}'),
                child: const Icon(Icons.notifications_none_outlined),
              ),
            ),
            IconButton(
              tooltip: loc.navProfile,
              onPressed: () => context.go('/legal/profile'),
              icon: const Icon(Icons.person_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({required this.shell, required this.extended});
  final StatefulNavigationShell shell;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final items = _items(loc);
    return Material(
      color: dark ? LegalTheme.navy : LegalTheme.navy,
      child: SizedBox(
        width: extended ? 220 : 72,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  extended ? loc.brand : 'م',
                  style: LegalTheme.ibm(
                    size: extended ? 16 : 18,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < items.length; i++)
              _RailItem(
                icon: items[i].$1,
                label: items[i].$2,
                selected: shell.currentIndex == i,
                extended: extended,
                onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
              ),
            const Spacer(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: EdgeInsets.symmetric(
          horizontal: extended ? 12 : 0,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected ? LegalTheme.primary.withValues(alpha: 0.28) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment:
              extended ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : LegalTheme.darkMuted, size: 20),
            if (extended) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: LegalTheme.ibm(
                    size: 13,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : LegalTheme.darkMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final items = _items(loc);
    final idx = shell.currentIndex;
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? LegalTheme.darkSurface
          : LegalTheme.surface,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: LegalTheme.outline)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom, top: 6),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = idx == i;
            return Expanded(
              child: InkWell(
                onTap: () => shell.goBranch(i, initialLocation: i == idx),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].$1,
                        size: 22,
                        color: selected ? LegalTheme.primary : LegalTheme.muted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LegalTheme.ibm(
                          size: 10,
                          weight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? LegalTheme.primary : LegalTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

List<(IconData, String)> _items(LegalStrings loc) => [
      (Icons.assignment_outlined, loc.navWork),
      (Icons.account_tree_outlined, loc.navTransactions),
      (Icons.description_outlined, loc.navContracts),
      (Icons.folder_outlined, loc.navDocuments),
      (Icons.chat_bubble_outline, loc.navMessages),
      (Icons.inventory_2_outlined, loc.navArchive),
      (Icons.person_outline, loc.navProfile),
    ];

class LegalWorkspaceLoader extends StatefulWidget {
  const LegalWorkspaceLoader({required this.child, super.key});
  final Widget child;

  @override
  State<LegalWorkspaceLoader> createState() => _LegalWorkspaceLoaderState();
}

class _LegalWorkspaceLoaderState extends State<LegalWorkspaceLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LegalWorkspaceController>().load();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
