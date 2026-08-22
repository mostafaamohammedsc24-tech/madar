import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/closing_strings.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart' hide labelPriority, labelAction, labelStage, labelDoc, toneForPriority, toneForDoc;
import '../../domain/enums/closing_enums.dart';
import '../../domain/models/closing_models.dart';
import '../providers/closing_workspace_controller.dart';
import '../widgets/closing_labels.dart';

class ClosingWorkScreen extends StatelessWidget {
  const ClosingWorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = ClosingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<ClosingWorkspaceController>();
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
                  loc.workQ,
                  style: LegalTheme.ibm(
                    size: 20,
                    weight: FontWeight.w600,
                    color: dark ? LegalTheme.darkText : LegalTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(loc.notContract, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
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
                        label: loc.allFilter,
                        selected: ws.priorityFilter == null,
                        onTap: () => ws.setPriority(null),
                      ),
                      ...ClosingPriority.values.map(
                        (p) => _FilterChip(
                          label: labelPriority(loc, p),
                          selected: ws.priorityFilter == p,
                          onTap: () => ws.setPriority(ws.priorityFilter == p ? null : p),
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
                      child: ClosingQueueTile(
                        item: items[i],
                        loc: loc,
                        onOpen: () => context.push('/closing/transaction/${items[i].id}'),
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

class ClosingQueueTile extends StatelessWidget {
  const ClosingQueueTile({
    super.key,
    required this.item,
    required this.loc,
    required this.onOpen,
  });

  final ClosingCase item;
  final ClosingStrings loc;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = item;
    final urgent = c.priority == ClosingPriority.urgent || c.priority == ClosingPriority.blocked;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final approaching = deadlineSoon(c);

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
                      style: LegalTheme.mono(size: 14, weight: FontWeight.w700, color: LegalTheme.primary),
                    ),
                  ),
                  LegalStatusChip(label: labelPriority(loc, c.priority), tone: toneForClosingPriority(c.priority)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${c.transactionType}  ·  ${c.propertyType}',
                style: LegalTheme.ibm(size: 14, weight: FontWeight.w600),
              ),
              Text('${loc.property}: ${c.propertyId}', style: LegalTheme.mono(size: 12, color: LegalTheme.muted)),
              Text(c.propertyAddress, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
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
                  Expanded(child: _kv(loc.amount, c.amount)),
                  Expanded(child: _kv(loc.currentStage, loc.stage(timelineLabel(c.timelineStage)))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _kv(loc.responsible, c.responsibleDepartment)),
                  Expanded(child: _kv(loc.status, c.statusLabel)),
                ],
              ),
              const SizedBox(height: 8),
              _kv(loc.lastActivity, fmtWhen(c.lastActivity)),
              if (approaching) ...[
                const SizedBox(height: 8),
                LegalStatusChip(label: loc.approaching, tone: LegalTone.warning),
              ],
              if (c.blockedReason != null) ...[
                const SizedBox(height: 8),
                Text('${loc.blockedWhy}: ${c.blockedReason}', style: LegalTheme.ibm(size: 12, color: LegalTheme.danger)),
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
                  style: LegalTheme.ibm(size: 13, weight: FontWeight.w700, color: LegalTheme.primary),
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
        Text(v, style: LegalTheme.ibm(size: 13, weight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
