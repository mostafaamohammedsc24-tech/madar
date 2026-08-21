import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../theme/bank_tokens.dart';

/// Arabic-first Bank Operations shell — Work · Transactions · Receipts · Messages · Profile
class BankShell extends StatelessWidget {
  const BankShell({required this.child, super.key});

  final Widget child;

  static const tabs = <_BankTab>[
    _BankTab(
      route: '/employee/work',
      label: 'العمل',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
      match: ['/employee/work', '/employee/home'],
    ),
    _BankTab(
      route: '/employee/bank/transactions',
      label: 'المعاملات',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      match: [
        '/employee/bank/transactions',
        '/employee/bank/transaction',
        '/employee/bank/deposits',
      ],
    ),
    _BankTab(
      route: '/employee/bank/receipts',
      label: 'الإيصالات',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      match: ['/employee/bank/receipts', '/employee/bank/receipt'],
    ),
    _BankTab(
      route: '/employee/messages',
      label: 'الرسائل',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      match: ['/employee/messages'],
    ),
    _BankTab(
      route: '/employee/profile',
      label: 'الملف',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      match: ['/employee/profile'],
    ),
  ];

  int _selectedIndex(String location) {
    for (var i = 0; i < tabs.length; i++) {
      for (final m in tabs[i].match) {
        if (location == m ||
            location.startsWith('$m/') ||
            location.startsWith('$m?')) {
          return i;
        }
      }
    }
    if (location.startsWith('/employee/bank')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<EmployeeAuthNotifier>();
    final employee = auth.employee;
    if (employee == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final location = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(location);
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final theme = Theme.of(context).copyWith(
      textTheme: BankTokens.textTheme(Theme.of(context).textTheme),
      scaffoldBackgroundColor: BankTokens.background,
      colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: BankTokens.primary,
            secondary: BankTokens.secondary,
            surface: BankTokens.surface,
            onSurface: BankTokens.onSurface,
            onSurfaceVariant: BankTokens.onSurfaceVariant,
          ),
    );

    return Theme(
      data: theme,
      child: wide
          ? Scaffold(
              backgroundColor: BankTokens.background,
              body: Row(
                children: [
                  _DesktopRail(
                    selected: selected,
                    onSelect: (i) => context.go(tabs[i].route),
                    employeeName: employee.fullName,
                    employeeCode: employee.employeeCode,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _BankTopBar(
                          employeeName: employee.fullName,
                          employeeCode: employee.employeeCode,
                          onNotifications: () =>
                              context.push('/employee/notifications'),
                          onProfile: () => context.go('/employee/profile'),
                        ),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Scaffold(
              backgroundColor: BankTokens.background,
              body: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: _BankTopBar(
                      employeeName: employee.fullName,
                      employeeCode: employee.employeeCode,
                      onNotifications: () =>
                          context.push('/employee/notifications'),
                      onProfile: () => context.go('/employee/profile'),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
              bottomNavigationBar: _MobileNav(
                selected: selected,
                onSelect: (i) => context.go(tabs[i].route),
              ),
            ),
    );
  }
}

class _BankTab {
  const _BankTab({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.match,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final List<String> match;
}

class _BankTopBar extends StatelessWidget {
  const _BankTopBar({
    required this.employeeName,
    required this.employeeCode,
    required this.onNotifications,
    required this.onProfile,
  });

  final String employeeName;
  final String employeeCode;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: BankTokens.card,
        border: Border(
          bottom: BorderSide(
            color: BankTokens.outlineVariant.withValues(alpha: 0.7),
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
              color: BankTokens.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مدار · عمليات البنك',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: BankTokens.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: BankTokens.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'جلسة آمنة · $employeeName · $employeeCode',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: BankTokens.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_outlined),
            color: BankTokens.onSurfaceVariant,
          ),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(16),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: BankTokens.primary,
              child: Text(
                employeeName.isNotEmpty ? employeeName.characters.first : 'ب',
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

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.selected,
    required this.onSelect,
    required this.employeeName,
    required this.employeeCode,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final String employeeName;
  final String employeeCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: BankTokens.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MADAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'عمليات البنك',
                    style: TextStyle(
                      color: Color(0xFFA5BDFF),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      employeeCode,
                      style: const TextStyle(
                        color: Color(0xFFA5BDFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < BankShell.tabs.length; i++)
              _RailItem(
                tab: BankShell.tabs[i],
                selected: selected == i,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'وصول آمن · تدقيق كامل',
                style: TextStyle(
                  color: Color(0xFF86A0CD),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _BankTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? tab.selectedIcon : tab.icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  tab.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BankTokens.card,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: BankTokens.outlineVariant)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom,
          top: 4,
        ),
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(BankShell.tabs.length, (i) {
              final tab = BankShell.tabs[i];
              final on = selected == i;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (on)
                        Container(
                          width: 18,
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 4),
                          color: BankTokens.primary,
                        )
                      else
                        const SizedBox(height: 6),
                      Icon(
                        on ? tab.selectedIcon : tab.icon,
                        size: 22,
                        color: on
                            ? BankTokens.primary
                            : BankTokens.onSurfaceVariant,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                          color: on
                              ? BankTokens.primary
                              : BankTokens.onSurfaceVariant,
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
