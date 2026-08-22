import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/closing_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart' hide labelPriority, labelAction, labelStage, labelDoc, toneForPriority, toneForDoc;
import '../providers/closing_auth_notifier.dart';
import '../providers/closing_workspace_controller.dart';
import '../widgets/closing_labels.dart';
import 'closing_work_screen.dart';

class ClosingTransactionsScreen extends StatelessWidget {
  const ClosingTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = ClosingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<ClosingWorkspaceController>();
    final items = ws.pageOf(ws.allFiltered);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: ws.setSearch,
            decoration: InputDecoration(
              hintText: loc.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClosingQueueTile(
                item: items[i],
                loc: loc,
                onOpen: () => context.push('/closing/transaction/${items[i].id}'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ClosingFinanceScreen extends StatelessWidget {
  const ClosingFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = ClosingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<ClosingWorkspaceController>();
    final items = ws.allFiltered.where((c) => !c.isClosed).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final c = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(c.transactionNumber, style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
            subtitle: Text(
              '${loc.outstanding}: ${c.finance.outstanding}\n${loc.clearance}: ${c.finance.clearance} · ${c.finance.commissionStatus}',
            ),
            isThreeLine: true,
            onTap: () => context.push('/closing/transaction/${c.id}'),
          ),
        );
      },
    );
  }
}

class ClosingGovListScreen extends StatelessWidget {
  const ClosingGovListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = ClosingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<ClosingWorkspaceController>();
    final rows = <(String, String, String)>[];
    for (final c in ws.allFiltered) {
      for (final p in c.procedures) {
        rows.add((c.id, c.transactionNumber, '${p.name} · ${p.authority} · ${labelGov(loc, p.status)}'));
      }
    }
    if (rows.isEmpty) {
      return Center(child: Text(loc.noActions, style: LegalTheme.ibm(size: 14, color: LegalTheme.muted)));
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final r = rows[i];
        return ListTile(
          title: Text(r.$2, style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
          subtitle: Text(r.$3),
          onTap: () => context.push('/closing/transaction/${r.$1}'),
        );
      },
    );
  }
}

class ClosingDocumentsScreen extends StatelessWidget {
  const ClosingDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = ClosingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<ClosingWorkspaceController>();
    final rows = <(String, String, String)>[];
    for (final c in ws.allFiltered) {
      for (final d in c.documents) {
        rows.add((c.id, d.name, '${c.transactionNumber} · ${labelDeed(loc, d.status)}'));
      }
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final r = rows[i];
        return ListTile(
          title: Text(r.$2),
          subtitle: Text(r.$3),
          onTap: () => context.push('/closing/transaction/${r.$1}'),
        );
      },
    );
  }
}

class ClosingMessagesScreen extends StatelessWidget {
  const ClosingMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = ClosingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<ClosingWorkspaceController>();
    final threads = ws.allFiltered.where((c) => c.messages.isNotEmpty).toList();
    if (threads.isEmpty) {
      return Center(child: Text(loc.noActions, style: LegalTheme.ibm(size: 14, color: LegalTheme.muted)));
    }
    return ListView.builder(
      itemCount: threads.length,
      itemBuilder: (_, i) {
        final c = threads[i];
        return ListTile(
          title: Text('${c.transactionNumber} · ${c.propertyId}'),
          subtitle: Text(c.messages.last.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => context.push('/closing/transaction/${c.id}'),
        );
      },
    );
  }
}

class ClosingArchiveScreen extends StatelessWidget {
  const ClosingArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = ClosingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<ClosingWorkspaceController>();
    final items = ws.archive;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: ws.setSearch,
            decoration: InputDecoration(
              hintText: loc.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(loc.noActions))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClosingQueueTile(
                      item: items[i],
                      loc: loc,
                      onOpen: () => context.push('/closing/transaction/${items[i].id}'),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class ClosingProfileScreen extends StatelessWidget {
  const ClosingProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = ClosingStrings.of(AppLocalizations.of(context));
    final auth = context.watch<ClosingAuthNotifier>();
    final ws = context.watch<ClosingWorkspaceController>();
    final locale = context.watch<LocaleProvider>();
    final staff = auth.staff;
    final started = auth.sessionStartedAt;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(loc.role, style: LegalTheme.ibm(size: 20, weight: FontWeight.w700)),
        Text(staff?.displayName ?? '', style: LegalTheme.ibm(size: 16)),
        Text(staff?.employeeId ?? '', style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
        const SizedBox(height: 12),
        Text(loc.notContract, style: LegalTheme.ibm(size: 13, color: LegalTheme.muted)),
        const SizedBox(height: 8),
        Text(loc.notPublic, style: LegalTheme.ibm(size: 13, color: LegalTheme.muted)),
        const SizedBox(height: 16),
        Text(loc.permissions, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
        Text(loc.canDo),
        const SizedBox(height: 8),
        Text(loc.cannotDo, style: LegalTheme.ibm(size: 13, color: LegalTheme.danger)),
        const SizedBox(height: 16),
        Text('${loc.session}: ${started ?? '—'}', style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        SwitchListTile(
          title: Text(loc.dark),
          value: locale.isDarkMode,
          onChanged: locale.setDarkMode,
        ),
        ListTile(
          title: Text(loc.language),
          trailing: const Icon(Icons.language),
          onTap: () => LanguageSelectorSheet.show(context),
        ),
        const Divider(),
        Text(loc.notifications, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        for (final c in ws.actionable.take(8))
          ListTile(
            leading: const Icon(Icons.notifications_none, color: LegalTheme.primary),
            title: Text(c.transactionNumber, style: LegalTheme.mono(size: 13)),
            subtitle: Text('${labelAction(loc, c.requiredAction)} · ${c.statusLabel}'),
            trailing: LegalStatusChip(label: labelPriority(loc, c.priority), tone: toneForClosingPriority(c.priority)),
            onTap: () => context.push('/closing/transaction/${c.id}'),
          ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () async {
            await auth.logout();
            if (context.mounted) context.go('/closing-login');
          },
          child: Text(loc.signOut),
        ),
      ],
    );
  }
}
