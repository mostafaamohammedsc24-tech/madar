import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';

class OfficeScaffold extends StatelessWidget {
  const OfficeScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    const navHeight = 72.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          Positioned.fill(
            bottom: navHeight + bottom,
            child: navigationShell,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _OfficeBottomNav(shell: navigationShell),
          ),
        ],
      ),
    );
  }
}

class _OfficeBottomNav extends StatelessWidget {
  const _OfficeBottomNav({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final idx = shell.currentIndex;
    final items = [
      (Icons.map_outlined, Icons.map, loc.officeNavHome),
      (Icons.home_work_outlined, Icons.home_work, loc.officeNavProperties),
      (Icons.receipt_long_outlined, Icons.receipt_long, loc.officeNavTransactions),
      (Icons.trending_up_outlined, Icons.trending_up, loc.officeNavLeads),
      (Icons.chat_bubble_outline, Icons.chat_bubble, loc.officeNavConversations),
      (Icons.more_horiz, Icons.more_horiz, loc.officeNavMore),
    ];

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom,
          top: 6,
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = idx == i;
            final spec = items[i];
            return Expanded(
              child: InkWell(
                onTap: () => shell.goBranch(
                  i,
                  initialLocation: i == shell.currentIndex,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? spec.$2 : spec.$1,
                        size: 22,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spec.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
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
