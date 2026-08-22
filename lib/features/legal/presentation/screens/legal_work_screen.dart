import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/legal_strings.dart';
import '../../domain/enums/legal_enums.dart';
import '../../domain/models/legal_models.dart';
import '../providers/legal_workspace_controller.dart';
import '../theme/legal_theme.dart';
import '../widgets/legal_status_chip.dart';

class LegalWorkScreen extends StatelessWidget {
  const LegalWorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final ws = context.watch<LegalWorkspaceController>();
    final items = ws.actionable;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: dark ? LegalTheme.darkBg : LegalTheme.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.workQuestion,
                  style: LegalTheme.ibm(
                    size: 20,
                    weight: FontWeight.w600,
                    color: dark ? LegalTheme.darkText : LegalTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: ws.setSearch,
                  decoration: InputDecoration(
                    hintText: loc.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: dark ? LegalTheme.darkSurface : LegalTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: loc.filter,
                        selected: ws.priorityFilter == null && ws.actionFilter == null,
                        onTap: () {
                          ws.setPriorityFilter(null);
                          ws.setActionFilter(null);
                        },
                      ),
                      ...LegalPriority.values.map(
                        (p) => _FilterChip(
                          label: labelPriority(loc, p),
                          selected: ws.priorityFilter == p,
                          onTap: () => ws.setPriorityFilter(ws.priorityFilter == p ? null : p),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      loc.noActions,
                      style: LegalTheme.ibm(size: 16, color: LegalTheme.muted),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) => Padding(
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
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? LegalTheme.softBlue : LegalTheme.surfaceLow,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: selected ? LegalTheme.primary : LegalTheme.outline),
          ),
          child: Text(
            label,
            style: LegalTheme.ibm(
              size: 11,
              weight: FontWeight.w600,
              color: selected ? LegalTheme.primary : LegalTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class LegalCaseQueueTile extends StatelessWidget {
  const LegalCaseQueueTile({
    super.key,
    required this.legalCase,
    required this.loc,
    required this.onOpen,
  });

  final LegalCase legalCase;
  final LegalStrings loc;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = legalCase;
    final urgent = c.priority == LegalPriority.urgent;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final approaching = c.deadline != null &&
        c.deadline!.difference(DateTime.now()) < const Duration(hours: 24);

    return Material(
      color: dark ? LegalTheme.darkSurface : LegalTheme.surface,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.symmetric(
              horizontal: const BorderSide(color: LegalTheme.outline),
              vertical: BorderSide(
                color: urgent ? LegalTheme.danger : LegalTheme.outline,
                width: urgent ? 3 : 1,
              ),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c.transactionNumber,
                      style: LegalTheme.mono(
                        size: 13,
                        weight: FontWeight.w600,
                        color: LegalTheme.primary,
                      ),
                    ),
                  ),
                  LegalStatusChip(
                    label: labelPriority(loc, c.priority),
                    tone: toneForPriority(c.priority),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${c.propertyAddress}  ·  ${c.transactionType}',
                style: LegalTheme.ibm(size: 14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _kv(loc.buyer, c.buyer.name)),
                  Expanded(child: _kv(loc.seller, c.seller.name)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _kv(loc.currentStage, labelStage(loc, c.stage))),
                  Expanded(child: _kv(loc.lastActivity, _fmt(c.lastActivity))),
                ],
              ),
              if (approaching) ...[
                const SizedBox(height: 8),
                LegalStatusChip(label: loc.approachingDeadline, tone: LegalTone.warning),
              ],
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: LegalTheme.activeSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${loc.requiredAction}: ${labelAction(loc, c.requiredAction)}',
                  style: LegalTheme.ibm(
                    size: 13,
                    weight: FontWeight.w700,
                    color: LegalTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: LegalTheme.ibm(size: 10, color: LegalTheme.muted, letterSpacing: 0.4)),
        Text(v, style: LegalTheme.ibm(size: 13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  String _fmt(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
