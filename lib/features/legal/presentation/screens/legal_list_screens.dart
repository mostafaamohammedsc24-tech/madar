import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/legal_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../../domain/enums/legal_enums.dart';
import '../providers/legal_auth_notifier.dart';
import '../providers/legal_workspace_controller.dart';
import '../theme/legal_theme.dart';
import '../widgets/legal_status_chip.dart';
import 'legal_work_screen.dart';

class LegalContractsScreen extends StatelessWidget {
  const LegalContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final ws = context.watch<LegalWorkspaceController>();
    final items = ws.allFiltered.where((c) => c.contracts.isNotEmpty).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: ws.setSearch,
            decoration: InputDecoration(
              hintText: '${loc.navContracts} · ${loc.searchHint}',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (_, i) {
              final c = items[i];
              final v = c.currentContract!;
              return ListTile(
                title: Text(c.contractNumber, style: LegalTheme.mono(size: 14, color: LegalTheme.primary)),
                subtitle: Text('${c.transactionNumber} · ${c.buyer.name} / ${c.seller.name} · ${v.label} · ${v.status.name}'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.push('/legal/transaction/${c.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final ws = context.watch<LegalWorkspaceController>();
    final rows = <(String, String, String, LegalDocumentStatus)>[];
    for (final c in ws.allFiltered) {
      for (final d in c.documents) {
        rows.add((c.transactionNumber, d.name, d.party, d.status));
      }
    }
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
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final r = rows[i];
              return ListTile(
                title: Text(r.$2),
                subtitle: Text('${r.$1} · ${r.$3}'),
                trailing: LegalStatusChip(label: labelDoc(loc, r.$4), tone: toneForDoc(r.$4)),
                onTap: () => context.push('/legal/transaction/${r.$1}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class LegalMessagesScreen extends StatelessWidget {
  const LegalMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final ws = context.watch<LegalWorkspaceController>();
    final threads = ws.allFiltered.where((c) => c.messages.isNotEmpty).toList();
    if (threads.isEmpty) {
      return Center(child: Text(loc.noActions, style: LegalTheme.ibm(size: 14, color: LegalTheme.muted)));
    }
    return ListView.builder(
      itemCount: threads.length,
      itemBuilder: (_, i) {
        final c = threads[i];
        return ListTile(
          title: Text('${c.transactionNumber} · ${loc.buyer}: ${c.buyer.name}'),
          subtitle: Text(c.messages.last.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => context.push('/legal/transaction/${c.id}'),
        );
      },
    );
  }
}

class LegalArchiveScreen extends StatelessWidget {
  const LegalArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final ws = context.watch<LegalWorkspaceController>();
    final items = ws.archiveCases;
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
                    child: LegalCaseQueueTile(
                      legalCase: items[i],
                      loc: loc,
                      onOpen: () => context.push('/legal/transaction/${items[i].id}'),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class LegalProfileScreen extends StatelessWidget {
  const LegalProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final auth = context.watch<LegalAuthNotifier>();
    final ws = context.watch<LegalWorkspaceController>();
    final locale = context.watch<LocaleProvider>();
    final staff = auth.staff;
    final started = auth.sessionStartedAt;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(loc.contractLawyer, style: LegalTheme.ibm(size: 20, weight: FontWeight.w700)),
        Text(staff?.displayName ?? '', style: LegalTheme.ibm(size: 16)),
        Text(staff?.employeeId ?? '', style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
        const SizedBox(height: 12),
        Text(loc.roleBoundary, style: LegalTheme.ibm(size: 13, color: LegalTheme.muted)),
        const SizedBox(height: 16),
        Text(loc.permissionsLabel, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
        Text(loc.canDo),
        const SizedBox(height: 8),
        Text(loc.cannotDo, style: LegalTheme.ibm(size: 13, color: LegalTheme.danger)),
        const SizedBox(height: 16),
        Text('${loc.sessionLabel}: ${started ?? '—'}', style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        SwitchListTile(
          title: Text(loc.darkMode),
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
        for (final n in ws.notifications)
          ListTile(
            leading: Icon(n.read ? Icons.notifications_none : Icons.notifications, color: LegalTheme.primary),
            title: Text(n.title),
            subtitle: Text('${n.body} · ${n.at}'),
            onTap: () {
              ws.markNotificationRead(n.id);
              if (n.caseId != null) context.push('/legal/transaction/${n.caseId}');
            },
          ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () async {
            await auth.logout();
            if (context.mounted) context.go('/legal-login');
          },
          child: Text(loc.signOut),
        ),
      ],
    );
  }
}
