import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

/// Arabic-first Office shell — Map · My Properties · Transactions · Requests · Messages · Profile
class OfficeScaffold extends StatelessWidget {
  const OfficeScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final office = context.watch<OfficeAuthNotifier>().office;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _OfficeTopBar(
              officeName: office?.name ?? 'مدار',
              officeCode: office?.officeCode ?? '',
              onSearch: () => context.push('/office/ai'),
              onNotifications: () => context.push('/office/notifications'),
              onProfile: () => navigationShell.goBranch(5),
            ),
          ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: _OfficeBottomNav(shell: navigationShell),
    );
  }
}

class _OfficeTopBar extends StatelessWidget {
  const _OfficeTopBar({
    required this.officeName,
    required this.officeCode,
    required this.onSearch,
    required this.onNotifications,
    required this.onProfile,
  });

  final String officeName;
  final String officeCode;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0041C8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  officeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0B1C30),
                  ),
                ),
                Text(
                  officeCode,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            color: theme.colorScheme.onSurfaceVariant,
          ),
          IconButton(
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_outlined),
            color: theme.colorScheme.onSurfaceVariant,
          ),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(16),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFF0041C8),
              child: Text(
                officeName.isNotEmpty ? officeName.characters.first : 'م',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
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
      (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet,
          loc.officeNavTransactions),
      (Icons.assignment_outlined, Icons.assignment, loc.officeNavLeads),
      (Icons.chat_bubble_outline, Icons.chat_bubble, loc.officeNavConversations),
      (Icons.person_outline, Icons.person, loc.officeNavMore),
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
          top: 4,
        ),
        child: SizedBox(
          height: 64,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selected)
                        Container(
                          width: 18,
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 4),
                          color: const Color(0xFF0041C8),
                        )
                      else
                        const SizedBox(height: 6),
                      Icon(
                        selected ? spec.$2 : spec.$1,
                        size: 22,
                        color: selected
                            ? const Color(0xFF0041C8)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spec.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF0041C8)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
