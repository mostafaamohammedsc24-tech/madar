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

class ClosingCaseScreen extends StatefulWidget {
  const ClosingCaseScreen({required this.caseId, super.key});
  final String caseId;

  @override
  State<ClosingCaseScreen> createState() => _ClosingCaseScreenState();
}

class _ClosingCaseScreenState extends State<ClosingCaseScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _noteCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _financeCtrl = TextEditingController();
  final _rejectCtrl = TextEditingController();
  ChannelDept _channel = ChannelDept.buyer;
  bool _internalMsg = false;
  double _zoom = 1;
  int _rotation = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = context.read<ClosingWorkspaceController>();
      final c = ws.byId(widget.caseId);
      if (c != null) ws.audit(c, 'transaction_opened', 'view');
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _noteCtrl.dispose();
    _msgCtrl.dispose();
    _financeCtrl.dispose();
    _rejectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ClosingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<ClosingWorkspaceController>();
    final c = ws.byId(widget.caseId);
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (c == null) {
      return Scaffold(body: Center(child: Text(loc.noActions)));
    }

    return Scaffold(
      backgroundColor: dark ? LegalTheme.darkBg : LegalTheme.paper,
      body: Column(
        children: [
          _Header(c: c, loc: loc, onBack: () => context.pop()),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            labelColor: LegalTheme.primary,
            tabs: [
              Tab(text: loc.navWork),
              Tab(text: loc.escrow),
              Tab(text: loc.gov),
              Tab(text: loc.navDocs),
              Tab(text: loc.navFinance),
              Tab(text: loc.navMsg),
              Tab(text: loc.audit),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _OverviewTab(c: c, loc: loc, ws: ws, caseId: widget.caseId),
                _EscrowTab(c: c, loc: loc),
                _GovTab(c: c, loc: loc, ws: ws, caseId: widget.caseId),
                _DocsTab(
                  c: c,
                  loc: loc,
                  ws: ws,
                  zoom: _zoom,
                  rotation: _rotation,
                  onZoom: (v) => setState(() => _zoom = v),
                  onRotate: () => setState(() => _rotation = (_rotation + 90) % 360),
                  rejectCtrl: _rejectCtrl,
                ),
                _FinanceTab(c: c, loc: loc, ws: ws, caseId: widget.caseId, ctrl: _financeCtrl),
                _MessagesTab(
                  c: c,
                  loc: loc,
                  ws: ws,
                  noteCtrl: _noteCtrl,
                  msgCtrl: _msgCtrl,
                  channel: _channel,
                  internal: _internalMsg,
                  onChannel: (v) => setState(() => _channel = v),
                  onInternal: (v) => setState(() => _internalMsg = v),
                ),
                _AuditTab(c: c),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.c, required this.loc, required this.onBack});
  final ClosingCase c;
  final ClosingStrings loc;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? LegalTheme.darkSurface : LegalTheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.transactionNumber,
                    style: LegalTheme.mono(size: 20, weight: FontWeight.w700, color: LegalTheme.primary),
                  ),
                  Text(
                    '${c.transactionType} · ${c.countryCode} · ${c.propertyId} · ${loc.stage(timelineLabel(c.timelineStage))}',
                    style: LegalTheme.ibm(size: 12, color: LegalTheme.muted),
                  ),
                ],
              ),
            ),
            LegalStatusChip(label: labelPriority(loc, c.priority), tone: toneForClosingPriority(c.priority)),
            const SizedBox(width: 8),
            LegalStatusChip(label: c.statusLabel, tone: LegalTone.active),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.c, required this.loc, required this.ws, required this.caseId});
  final ClosingCase c;
  final ClosingStrings loc;
  final ClosingWorkspaceController ws;
  final String caseId;

  @override
  Widget build(BuildContext context) {
    final checklist = ws.closingChecklist(c);
    final canClose = ws.canClose(c);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _meta(loc.propertyId, c.propertyId),
            _meta(loc.propertyType, c.propertyType),
            _meta(loc.address, c.propertyAddress),
            _meta(loc.buyer, c.buyer.name),
            _meta(loc.seller, c.seller.name),
            _meta(loc.office, c.officeName),
            _meta(loc.assigned, '${c.assignedLawyer} · ${c.lawyerEmployeeId}'),
            _meta(loc.country, c.countryCode),
            _meta(loc.amount, c.amount),
            _meta(loc.responsible, c.responsibleDepartment),
            _meta(loc.numbering, c.workflow.numberingPrefix),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _banner(loc.digital, LegalTheme.activeSoft, LegalTheme.primary)),
            const SizedBox(width: 8),
            Expanded(child: _banner(loc.physical, LegalTheme.warningSoft, LegalTheme.warning)),
          ],
        ),
        const SizedBox(height: 16),
        _HandoffCard(c: c, loc: loc),
        const SizedBox(height: 16),
        Text(loc.currentStage, style: LegalTheme.ibm(size: 16, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${loc.requiredAction}: ${labelAction(loc, c.requiredAction)}', style: LegalTheme.ibm(size: 13, color: LegalTheme.primary, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        _Timeline(c: c, loc: loc),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, box) {
          final two = box.maxWidth > 720;
          final buyer = _PartyCard(title: loc.buyer, p: c.buyer, loc: loc);
          final seller = _PartyCard(title: loc.seller, p: c.seller, loc: loc);
          if (two) {
            return Row(children: [Expanded(child: buyer), const SizedBox(width: 12), Expanded(child: seller)]);
          }
          return Column(children: [buyer, const SizedBox(height: 12), seller]);
        }),
        const SizedBox(height: 16),
        _PropertyCard(c: c, loc: loc),
        if (c.agricultural) ...[
          const SizedBox(height: 16),
          _AgriCard(c: c, loc: loc),
        ],
        if (c.serviceShare != null) ...[
          const SizedBox(height: 16),
          _panel(
            loc.services,
            '${c.serviceShare!.service}\n${c.serviceShare!.sharedFields.join(' · ')}',
          ),
        ],
        const SizedBox(height: 16),
        Text(loc.checklist, style: LegalTheme.ibm(size: 16, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        _check(loc.checkContract, checklist['contract']!),
        _check(loc.checkEscrow, checklist['escrow']!),
        _check(loc.checkTax, checklist['tax']!),
        _check(loc.checkGov, checklist['gov']!),
        _check(loc.checkTransfer, checklist['transfer']!),
        _check(loc.checkDeed, checklist['deed']!),
        _check(loc.checkSettle, checklist['settlement']!),
        _check(loc.checkReceipts, checklist['receipts']!),
        _check(loc.checkFinal, checklist['final']!),
        const SizedBox(height: 12),
        if (c.isClosed)
          Container(
            padding: const EdgeInsets.all(14),
            color: LegalTheme.successSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.completed, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700, color: LegalTheme.success)),
                Text('${loc.completionDate}: ${c.closedAt == null ? '—' : fmtWhen(c.closedAt!)}'),
                Text('${loc.finalOwner}: ${c.finalOwner ?? c.buyer.name}'),
              ],
            ),
          )
        else ...[
          FilledButton(
            onPressed: canClose ? () => ws.closeTransaction(caseId) : null,
            child: Text(loc.closeTx),
          ),
          if (!canClose)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(loc.cannotClose, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
            ),
        ],
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: SelectableText(ws.finalReport(c), style: LegalTheme.mono(size: 12)),
                ),
              ),
            );
          },
          child: Text(loc.finalReport),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: c.isClosed
              ? null
              : () async {
                  final reason = TextEditingController();
                  ChannelDept dept = ChannelDept.finance;
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => StatefulBuilder(
                      builder: (ctx, setS) => AlertDialog(
                        title: Text(loc.escalate),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<ChannelDept>(
                              value: dept,
                              isExpanded: true,
                              items: ChannelDept.values
                                  .map((d) => DropdownMenuItem(value: d, child: Text(labelChannel(loc, d))))
                                  .toList(),
                              onChanged: (v) => setS(() => dept = v ?? dept),
                            ),
                            TextField(controller: reason, decoration: InputDecoration(hintText: loc.escalateHint)),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.escalate)),
                        ],
                      ),
                    ),
                  );
                  if (ok == true && reason.text.trim().isNotEmpty) {
                    ws.escalate(caseId, dept, reason.text.trim());
                  }
                },
          child: Text(loc.escalate),
        ),
      ],
    );
  }

  Widget _banner(String t, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: bg,
      child: Text(t, style: LegalTheme.ibm(size: 12, weight: FontWeight.w600, color: fg)),
    );
  }

  Widget _meta(String k, String v) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: LegalTheme.ibm(size: 10, color: LegalTheme.muted)),
          Text(v, style: LegalTheme.ibm(size: 13, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _check(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(ok ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: ok ? LegalTheme.success : LegalTheme.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: LegalTheme.ibm(size: 13, color: ok ? LegalTheme.success : LegalTheme.charcoal))),
        ],
      ),
    );
  }

  Widget _panel(String t, String b) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: LegalTheme.outline), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(b, style: LegalTheme.ibm(size: 13)),
        ],
      ),
    );
  }
}

class _HandoffCard extends StatelessWidget {
  const _HandoffCard({required this.c, required this.loc});
  final ClosingCase c;
  final ClosingStrings loc;

  @override
  Widget build(BuildContext context) {
    final h = c.handoff;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LegalTheme.successSoft,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: LegalTheme.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.handoff, style: LegalTheme.ibm(size: 15, weight: FontWeight.w700, color: LegalTheme.success)),
          const SizedBox(height: 6),
          Text(loc.contractCompleted, style: LegalTheme.ibm(size: 13, weight: FontWeight.w600)),
          Text('${loc.contractId}: ${h.contractId}'),
          Text('${loc.executedVersion}: ${h.executedVersion}'),
          Text('${loc.buyer}: ${h.buyerSigned ? loc.checkContract : '—'}'),
          Text('${loc.seller}: ${h.sellerSigned ? loc.checkContract : '—'}'),
          Text('${loc.executionDate}: ${fmtWhen(h.executedAt)}'),
          Text('${loc.contractLawyer}: ${h.contractLawyerName} · ${h.contractLawyerId}'),
          const SizedBox(height: 8),
          Text(loc.assignedHere, style: LegalTheme.ibm(size: 13, weight: FontWeight.w700, color: LegalTheme.primary)),
          Text(fmtWhen(h.assignedAt), style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.c, required this.loc});
  final ClosingCase c;
  final ClosingStrings loc;

  @override
  Widget build(BuildContext context) {
    final stages = ClosingTimelineStage.values;
    final current = c.timelineStage.index;
    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          _TimelineRow(
            index: i + 1,
            label: loc.stage(timelineLabel(stages[i])),
            done: i < current || c.isClosed,
            active: i == current && !c.isClosed,
            blocked: c.priority == ClosingPriority.blocked && i == current,
            wait: i == current ? _waitReason(c, loc) : null,
          ),
      ],
    );
  }

  String? _waitReason(ClosingCase c, ClosingStrings loc) {
    if (c.blockedReason != null) return '${loc.blockedWhy}: ${c.blockedReason}';
    if (c.requiredAction == ClosingWorkAction.bankConfirmationPending) {
      return '${loc.waitingWhy}: ${labelEscrow(loc, c.escrow.status)}';
    }
    return '${loc.waitingWhy}: ${labelAction(loc, c.requiredAction)}';
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.index,
    required this.label,
    required this.done,
    required this.active,
    required this.blocked,
    this.wait,
  });

  final int index;
  final String label;
  final bool done;
  final bool active;
  final bool blocked;
  final String? wait;

  @override
  Widget build(BuildContext context) {
    final color = blocked
        ? LegalTheme.danger
        : done
            ? LegalTheme.success
            : active
                ? LegalTheme.primary
                : LegalTheme.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: LegalTheme.mono(size: 13, weight: FontWeight.w700, color: color),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: LegalTheme.ibm(size: 14, weight: active ? FontWeight.w700 : FontWeight.w500, color: color)),
                if (wait != null && (active || blocked))
                  Text(wait!, style: LegalTheme.ibm(size: 12, color: blocked ? LegalTheme.danger : LegalTheme.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.title, required this.p, required this.loc});
  final String title;
  final ClosingParty p;
  final ClosingStrings loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: LegalTheme.outline), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
          Text(p.name, style: LegalTheme.ibm(size: 16, weight: FontWeight.w600)),
          Text('${loc.userId}: ${p.madarUserId}', style: LegalTheme.mono(size: 12)),
          Text('${loc.phone}: ${p.phone}'),
          Text('${loc.country}: ${p.country}'),
          Text('${loc.identity}: ${p.identity}'),
          Text('${loc.docsStatus}: ${p.documents}'),
          Text('${loc.paymentStatus}: ${p.payment}'),
          Text('${loc.signatureStatus}: ${p.signature}'),
          Text('${loc.transferStatus}: ${p.ownershipTransfer}'),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.c, required this.loc});
  final ClosingCase c;
  final ClosingStrings loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: LegalTheme.outline), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.property, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
          Text('${loc.propertyId}: ${c.propertyId}', style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
          Text('${loc.address}: ${c.propertyAddress}'),
          Text('${loc.propertyType}: ${c.propertyType}'),
          Text('${loc.area}: ${c.area}'),
          Text('${loc.ownership}: ${c.ownershipInfo}'),
          Text('${loc.currentOwner}: ${c.currentOwner}'),
          Text('${loc.amount}: ${c.amount}'),
          Text('${loc.propertyStatus}: ${c.statusLabel}'),
          Text('${loc.land}: ${c.agricultural ? loc.agricultural : c.area}'),
          Text('${loc.govInfo}: ${c.workflow.governmentAuthorities.join(' · ')}'),
          Text('${loc.special}: ${c.workflow.escrowReleaseConditions.join(' · ')}'),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.openProperty, style: LegalTheme.ibm(size: 18, weight: FontWeight.w600)),
                      Text(c.transactionNumber, style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
                      Text(c.propertyId),
                      Text(c.propertyAddress),
                      Text(c.ownershipInfo),
                    ],
                  ),
                ),
              );
            },
            child: Text(loc.openProperty),
          ),
        ],
      ),
    );
  }
}

class _AgriCard extends StatelessWidget {
  const _AgriCard({required this.c, required this.loc});
  final ClosingCase c;
  final ClosingStrings loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: LegalTheme.softBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.agricultural, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700, color: LegalTheme.primary)),
          if (c.workflow.skipOwnershipDocument) Text(loc.skipDeed),
          Text(loc.releaseConditions, style: LegalTheme.ibm(size: 12, weight: FontWeight.w600)),
          for (final r in c.workflow.escrowReleaseConditions) Text('· $r'),
        ],
      ),
    );
  }
}

class _EscrowTab extends StatelessWidget {
  const _EscrowTab({required this.c, required this.loc});
  final ClosingCase c;
  final ClosingStrings loc;

  @override
  Widget build(BuildContext context) {
    final e = c.escrow;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LegalStatusChip(label: labelEscrow(loc, e.status), tone: toneForEscrow(e.status)),
        const SizedBox(height: 12),
        Text('${loc.requiredDeposit}: ${e.requiredAmount}'),
        Text('${loc.confirmedAmount}: ${e.confirmedAmount}'),
        Text('${loc.bank}: ${e.bankName}'),
        Text('${loc.navTx}: ${e.transactionNumber}'),
        Text('${loc.buyer}: ${c.buyer.name}'),
        Text('${loc.seller}: ${c.seller.name}'),
        if (e.deadline != null) Text('${loc.depositDeadline}: ${fmtWhen(e.deadline!)}'),
        Text('${loc.bankEmployee}: ${e.bankEmployee ?? '—'}'),
        Text('${loc.receipt}: ${e.receiptId ?? '—'}'),
        Text('${loc.confirmationTime}: ${e.confirmedAt == null ? '—' : fmtWhen(e.confirmedAt!)}'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          color: LegalTheme.warningSoft,
          child: Text(loc.bankCannotConfirm, style: LegalTheme.ibm(size: 13, color: LegalTheme.warning)),
        ),
        const SizedBox(height: 16),
        Text(loc.releaseConditions, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
        for (final r in c.workflow.escrowReleaseConditions) Text('· $r'),
        const SizedBox(height: 16),
        Text(loc.receipts, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
        Text(loc.receiptsLocked, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        for (final r in c.receipts)
          ListTile(
            title: Text(r.label),
            subtitle: Text('${r.source} · ${r.id} · ${fmtWhen(r.at)}'),
          ),
      ],
    );
  }
}

class _GovTab extends StatelessWidget {
  const _GovTab({required this.c, required this.loc, required this.ws, required this.caseId});
  final ClosingCase c;
  final ClosingStrings loc;
  final ClosingWorkspaceController ws;
  final String caseId;

  @override
  Widget build(BuildContext context) {
    final a = c.appointment;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(loc.gov, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final p in c.procedures)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(p.name, style: LegalTheme.ibm(size: 15, weight: FontWeight.w700))),
                      LegalStatusChip(label: labelGov(loc, p.status), tone: toneForGov(p.status)),
                    ],
                  ),
                  Text('${loc.authority}: ${p.authority}'),
                  Text('${loc.navDocs}: ${p.requiredDocuments.join(' · ')}'),
                  if (p.submittedAt != null) Text('${loc.date}: ${fmtWhen(p.submittedAt!)}'),
                  if (p.referenceNumber != null) Text('${loc.reference}: ${p.referenceNumber}'),
                  if (p.expectedCompletion != null) Text('${loc.expected}: ${fmtWhen(p.expectedCompletion!)}'),
                  if (p.responsible != null) Text('${loc.responsible}: ${p.responsible}'),
                  if (p.notes != null) Text(p.notes!),
                  if (p.rejectionReason != null)
                    Text('${loc.rejectionReason}: ${p.rejectionReason}', style: LegalTheme.ibm(size: 13, color: LegalTheme.danger)),
                  if (p.correction != null) Text('${loc.correction}: ${p.correction}'),
                  if (!c.isClosed)
                    Wrap(
                      spacing: 6,
                      children: [
                        TextButton(
                          onPressed: () => ws.setProcedureStatus(caseId, p.id, GovProcedureStatus.submitted),
                          child: Text(labelGov(loc, GovProcedureStatus.submitted)),
                        ),
                        TextButton(
                          onPressed: () => ws.setProcedureStatus(caseId, p.id, GovProcedureStatus.completed),
                          child: Text(labelGov(loc, GovProcedureStatus.completed)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(loc.transfer, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('${loc.attend}: ${a.required}'),
        Text('${loc.authority}: ${a.authority}'),
        Text('${loc.location}: ${a.location}'),
        Text('${loc.date}: ${a.date == null ? '—' : fmtWhen(a.date!)}'),
        Text('${loc.time}: ${a.time ?? '—'}'),
        Text('${loc.buyerAttend}: ${a.buyerAttend}'),
        Text('${loc.sellerAttend}: ${a.sellerAttend}'),
        Text('${loc.lawyerAttend}: ${a.lawyerAttend}'),
        Text('${loc.status}: ${a.status}'),
        Text('${loc.transferMode}: ${a.mode}'),
        Text('${loc.navDocs}: ${a.requiredDocuments.join(' · ')}'),
        const SizedBox(height: 8),
        Text(loc.futureDigital, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        if (!c.isClosed && c.lifecycle == ClosingLifecycle.ownershipTransferPending)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FilledButton(
              onPressed: () => ws.completePhysicalTransfer(caseId),
              child: Text(loc.markTransferDone),
            ),
          ),
      ],
    );
  }
}

class _DocsTab extends StatelessWidget {
  const _DocsTab({
    required this.c,
    required this.loc,
    required this.ws,
    required this.zoom,
    required this.rotation,
    required this.onZoom,
    required this.onRotate,
    required this.rejectCtrl,
  });

  final ClosingCase c;
  final ClosingStrings loc;
  final ClosingWorkspaceController ws;
  final double zoom;
  final int rotation;
  final ValueChanged<double> onZoom;
  final VoidCallback onRotate;
  final TextEditingController rejectCtrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            TextButton(onPressed: () => onZoom((zoom - 0.2).clamp(0.6, 2.4)), child: Text('- ${loc.zoom}')),
            TextButton(onPressed: () => onZoom((zoom + 0.2).clamp(0.6, 2.4)), child: Text('+ ${loc.zoom}')),
            TextButton(onPressed: onRotate, child: Text(loc.rotate)),
            TextButton(onPressed: () {}, child: Text(loc.download)),
            TextButton(onPressed: () {}, child: Text(loc.print)),
          ],
        ),
        Transform.rotate(
          angle: rotation * 3.14159 / 180,
          child: Transform.scale(
            scale: zoom,
            child: Container(
              height: 180,
              alignment: Alignment.center,
              color: LegalTheme.surfaceLow,
              child: Text(c.transactionNumber, style: LegalTheme.mono(size: 16, color: LegalTheme.primary)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final d in c.documents)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(d.name, style: LegalTheme.ibm(size: 15, weight: FontWeight.w700))),
                      LegalStatusChip(label: labelDeed(loc, d.status), tone: toneForDeed(d.status)),
                    ],
                  ),
                  Text(d.kind, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
                  Text(loc.versions, style: LegalTheme.ibm(size: 12, weight: FontWeight.w600)),
                  for (final v in d.versions)
                    Text('V${v.version} · ${labelDeed(loc, v.status)} · ${fmtWhen(v.at)}${v.reason == null ? '' : ' · ${v.reason}'}'),
                  if (!c.isClosed && (d.kind == 'deed' || d.kind == 'government'))
                    Wrap(
                      spacing: 6,
                      children: [
                        TextButton(
                          onPressed: () => ws.setDeedStatus(c.id, d.id, DeedReviewStatus.approved),
                          child: Text(loc.approve),
                        ),
                        TextButton(
                          onPressed: () async {
                            rejectCtrl.clear();
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(loc.reject),
                                content: TextField(controller: rejectCtrl, decoration: InputDecoration(hintText: loc.rejectionReason)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.reject)),
                                ],
                              ),
                            );
                            if (ok == true && rejectCtrl.text.trim().isNotEmpty) {
                              ws.setDeedStatus(c.id, d.id, DeedReviewStatus.rejected, reason: rejectCtrl.text.trim());
                            }
                          },
                          child: Text(loc.reject),
                        ),
                        TextButton(
                          onPressed: () => ws.setDeedStatus(c.id, d.id, DeedReviewStatus.correctionRequired),
                          child: Text(loc.replace),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FinanceTab extends StatelessWidget {
  const _FinanceTab({required this.c, required this.loc, required this.ws, required this.caseId, required this.ctrl});
  final ClosingCase c;
  final ClosingStrings loc;
  final ClosingWorkspaceController ws;
  final String caseId;
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    final f = c.finance;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(loc.cannotChangeFinance, style: LegalTheme.ibm(size: 13, color: LegalTheme.muted)),
        const SizedBox(height: 12),
        Text('${loc.tax} — ${loc.property}: ${f.propertyTaxes}'),
        Text('${loc.tax} — ${loc.navTx}: ${f.transactionTaxes}'),
        Text('${loc.gov}: ${f.governmentFees}'),
        Text('${loc.services}: ${f.serviceFees}'),
        Text('${loc.commission}: ${f.commissionStatus}'),
        Text('${loc.outstanding}: ${f.outstanding}'),
        Text('${loc.clearance}: ${f.clearance}'),
        const Divider(height: 32),
        Text(loc.navFinance, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        Text('${loc.sellerPayout}: ${f.sellerAmount}'),
        Text('${loc.companyFees}: ${f.companyFees}'),
        Text('${loc.finalSeller}: ${f.finalSellerAmount}'),
        const SizedBox(height: 16),
        TextField(controller: ctrl, decoration: InputDecoration(hintText: loc.requestFinanceHint, border: const OutlineInputBorder())),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: c.isClosed
              ? null
              : () {
                  if (ctrl.text.trim().isEmpty) return;
                  ws.requestFinanceAdjustment(caseId, ctrl.text.trim());
                  ctrl.clear();
                },
          child: Text(loc.financeReq),
        ),
      ],
    );
  }
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab({
    required this.c,
    required this.loc,
    required this.ws,
    required this.noteCtrl,
    required this.msgCtrl,
    required this.channel,
    required this.internal,
    required this.onChannel,
    required this.onInternal,
  });

  final ClosingCase c;
  final ClosingStrings loc;
  final ClosingWorkspaceController ws;
  final TextEditingController noteCtrl;
  final TextEditingController msgCtrl;
  final ChannelDept channel;
  final bool internal;
  final ValueChanged<ChannelDept> onChannel;
  final ValueChanged<bool> onInternal;

  @override
  Widget build(BuildContext context) {
    final customer = c.messages.where((m) => !m.internal).toList();
    final team = c.messages.where((m) => m.internal).toList();
    final internalNotes = c.notes.where((n) => n.internal).toList();
    final customerNotes = c.notes.where((n) => !n.internal).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${c.transactionNumber} · ${c.propertyId}', style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
        const SizedBox(height: 8),
        Text(loc.customerChat, style: LegalTheme.ibm(size: 15, weight: FontWeight.w700)),
        for (final m in customer) _msg(m, loc),
        Text(loc.internalChat, style: LegalTheme.ibm(size: 15, weight: FontWeight.w700)),
        Text(loc.neverMix, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        for (final m in team) _msg(m, loc),
        DropdownButton<ChannelDept>(
          value: channel,
          isExpanded: true,
          items: ChannelDept.values.map((d) => DropdownMenuItem(value: d, child: Text(labelChannel(loc, d)))).toList(),
          onChanged: (v) {
            if (v != null) onChannel(v);
          },
        ),
        SwitchListTile(
          title: Text(loc.internalChat),
          value: internal,
          onChanged: onInternal,
        ),
        TextField(controller: msgCtrl, decoration: InputDecoration(hintText: loc.messageHint)),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () {
              if (msgCtrl.text.trim().isEmpty) return;
              ws.addMessage(c.id, channel, msgCtrl.text.trim(), internal: internal);
              msgCtrl.clear();
            },
            child: Text(loc.send),
          ),
        ),
        const Divider(),
        Text(loc.internalNotes, style: LegalTheme.ibm(size: 15, weight: FontWeight.w700)),
        for (final n in internalNotes) Text('${n.author}: ${n.body} · ${fmtWhen(n.at)}'),
        Text(loc.customerNotes, style: LegalTheme.ibm(size: 15, weight: FontWeight.w700)),
        for (final n in customerNotes) Text('${n.author}: ${n.body} · ${fmtWhen(n.at)}'),
        TextField(controller: noteCtrl, decoration: InputDecoration(hintText: loc.noteHint)),
        Row(
          children: [
            TextButton(
              onPressed: () {
                if (noteCtrl.text.trim().isEmpty) return;
                ws.addNote(c.id, true, noteCtrl.text.trim());
                noteCtrl.clear();
              },
              child: Text(loc.addInternal),
            ),
            TextButton(
              onPressed: () {
                if (noteCtrl.text.trim().isEmpty) return;
                ws.addNote(c.id, false, noteCtrl.text.trim());
                noteCtrl.clear();
              },
              child: Text(loc.addCustomer),
            ),
          ],
        ),
      ],
    );
  }

  Widget _msg(ClosingMessage m, ClosingStrings loc) {
    return ListTile(
      dense: true,
      title: Text('${labelChannel(loc, m.channel)} · ${m.author}'),
      subtitle: Text(m.body),
      trailing: Text(fmtWhen(m.at), style: LegalTheme.ibm(size: 10, color: LegalTheme.muted)),
    );
  }
}

class _AuditTab extends StatelessWidget {
  const _AuditTab({required this.c});
  final ClosingCase c;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: c.audit.length,
      itemBuilder: (_, i) {
        final a = c.audit[c.audit.length - 1 - i];
        return ListTile(
          title: Text('${a.action} · ${a.result}'),
          subtitle: Text('${a.employeeName} · ${a.employeeId} · ${a.transactionNumber}\n${fmtWhen(a.at)}'),
          isThreeLine: true,
        );
      },
    );
  }
}
