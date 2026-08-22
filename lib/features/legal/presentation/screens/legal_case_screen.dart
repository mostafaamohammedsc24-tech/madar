import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/legal_strings.dart';
import '../../data/legal_clause_library.dart';
import '../../domain/enums/legal_enums.dart';
import '../../domain/models/legal_models.dart';
import '../providers/legal_workspace_controller.dart';
import '../theme/legal_theme.dart';
import '../widgets/legal_status_chip.dart';
import 'legal_work_screen.dart';

class LegalTransactionsScreen extends StatelessWidget {
  const LegalTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final ws = context.watch<LegalWorkspaceController>();
    final items = ws.allFiltered;
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

class LegalCaseScreen extends StatefulWidget {
  const LegalCaseScreen({required this.caseId, super.key});
  final String caseId;

  @override
  State<LegalCaseScreen> createState() => _LegalCaseScreenState();
}

class _LegalCaseScreenState extends State<LegalCaseScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _sectionIndex = 0;
  int? _compareFrom;
  final _noteCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _rejectCtrl = TextEditingController();
  bool _contextOpen = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = context.read<LegalWorkspaceController>();
      final c = ws.byId(widget.caseId);
      if (c != null) ws.audit(c, 'transaction_opened', 'view');
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _noteCtrl.dispose();
    _msgCtrl.dispose();
    _rejectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final ws = context.watch<LegalWorkspaceController>();
    final c = ws.byId(widget.caseId);
    if (c == null) {
      return Center(child: Text(loc.noActions));
    }
    final lang = AppLocalizations.of(context).languageCode;
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final tablet = MediaQuery.sizeOf(context).width >= 768;
    final dark = Theme.of(context).brightness == Brightness.dark;

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
            Tab(text: loc.navDocuments),
            Tab(text: loc.legalReview),
            Tab(text: loc.contractBuilder),
            Tab(text: loc.navMessages),
            Tab(text: loc.auditTrail),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _OverviewTab(c: c, loc: loc, lang: lang, onOpenProperty: () => _showProperty(context, c, loc)),
              _DocumentsTab(
                c: c,
                loc: loc,
                onReject: (doc) => _rejectDoc(c, doc, loc, ws),
                onApprove: (doc) => ws.setDocumentStatus(caseId: c.id, docId: doc.id, status: LegalDocumentStatus.approved),
                onReplace: (doc) => ws.setDocumentStatus(caseId: c.id, docId: doc.id, status: LegalDocumentStatus.replacementRequired),
                onRequest: () => _addReq(c, loc, ws),
              ),
              _ReviewTab(c: c, loc: loc, ws: ws),
              wide
                  ? _ContractTriple(c: c, loc: loc, lang: lang, ws: ws, sectionIndex: _sectionIndex, onSection: (i) => setState(() => _sectionIndex = i), contextOpen: _contextOpen, onToggleContext: () => setState(() => _contextOpen = !_contextOpen), compareFrom: _compareFrom, onCompare: (v) => setState(() => _compareFrom = v))
                  : _ContractMobile(c: c, loc: loc, lang: lang, ws: ws, sectionIndex: _sectionIndex, onSection: (i) => setState(() => _sectionIndex = i), showContext: tablet && _contextOpen, onToggleContext: () => setState(() => _contextOpen = !_contextOpen)),
              _MessagesTab(c: c, loc: loc, noteCtrl: _noteCtrl, msgCtrl: _msgCtrl, ws: ws),
              _AuditTab(c: c, loc: loc),
            ],
          ),
        ),
      ],
      ),
    );
  }

  void _showProperty(BuildContext context, LegalCase c, LegalStrings loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.openProperty, style: LegalTheme.ibm(size: 18, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('${loc.propertyId}: ${c.propertyId}', style: LegalTheme.mono(size: 13)),
            Text('${loc.address}: ${c.propertyAddress}'),
            Text('${loc.propertyType}: ${c.propertyType}'),
            Text('${loc.area}: ${c.area}'),
            Text('${loc.price}: ${c.price}'),
            Text('${loc.ownership}: ${c.ownershipInfo}'),
            if (c.specialLegalConditions != null) Text('${loc.specialConditions}: ${c.specialLegalConditions}'),
            const SizedBox(height: 12),
            Text(c.transactionNumber, style: LegalTheme.mono(size: 12, color: LegalTheme.primary)),
          ],
        ),
      ),
    );
  }

  Future<void> _rejectDoc(LegalCase c, LegalDocumentReq doc, LegalStrings loc, LegalWorkspaceController ws) async {
    _rejectCtrl.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.reject),
        content: TextField(
          controller: _rejectCtrl,
          maxLines: 3,
          decoration: InputDecoration(hintText: loc.rejectionReason),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.reject)),
        ],
      ),
    );
    if (ok == true && _rejectCtrl.text.trim().isNotEmpty) {
      ws.setDocumentStatus(
        caseId: c.id,
        docId: doc.id,
        status: LegalDocumentStatus.rejected,
        reason: _rejectCtrl.text.trim(),
      );
    }
  }

  Future<void> _addReq(LegalCase c, LegalStrings loc, LegalWorkspaceController ws) async {
    final name = TextEditingController();
    String party = 'buyer';
    var required = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(loc.addRequirement),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: InputDecoration(labelText: loc.document)),
              DropdownButton<String>(
                value: party,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 'buyer', child: Text(loc.buyer)),
                  DropdownMenuItem(value: 'seller', child: Text(loc.seller)),
                  DropdownMenuItem(value: 'both', child: Text(loc.both)),
                ],
                onChanged: (v) => setS(() => party = v ?? 'buyer'),
              ),
              SwitchListTile(
                title: Text(loc.required),
                value: required,
                onChanged: (v) => setS(() => required = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.save)),
          ],
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      ws.addRequirement(caseId: c.id, name: name.text.trim(), party: party, required: required);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.c, required this.loc, required this.onBack});
  final LegalCase c;
  final LegalStrings loc;
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
                    style: LegalTheme.mono(size: 18, weight: FontWeight.w700, color: LegalTheme.primary),
                  ),
                  Text(
                    '${c.transactionType} · ${c.propertyId} · ${labelStage(loc, c.stage)}',
                    style: LegalTheme.ibm(size: 12, color: LegalTheme.muted),
                  ),
                ],
              ),
            ),
            LegalStatusChip(label: labelPriority(loc, c.priority), tone: toneForPriority(c.priority)),
            const SizedBox(width: 8),
            LegalStatusChip(label: c.statusLabel, tone: LegalTone.active),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.c, required this.loc, required this.lang, required this.onOpenProperty});
  final LegalCase c;
  final LegalStrings loc;
  final String lang;
  final VoidCallback onOpenProperty;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _meta(loc.propertyId, c.propertyId),
            _meta(loc.address, c.propertyAddress),
            _meta(loc.buyer, c.buyer.name),
            _meta(loc.seller, c.seller.name),
            _meta(loc.office, c.officeName),
            _meta(loc.assignedLawyer, '${c.assignedLawyer} · ${c.lawyerEmployeeId}'),
            _meta(loc.priority, labelPriority(loc, c.priority)),
            _meta(loc.requiredAction, labelAction(loc, c.requiredAction)),
          ],
        ),
        const SizedBox(height: 20),
        Text(loc.currentStage, style: LegalTheme.ibm(size: 16, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        _Timeline(c: c, loc: loc),
        const SizedBox(height: 20),
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
        _PropertyCard(c: c, loc: loc, onOpen: onOpenProperty),
        if (c.rentToOwn != null) ...[
          const SizedBox(height: 16),
          _RtoCard(t: c.rentToOwn!, loc: loc),
        ],
        if (c.handoffComplete) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            color: LegalTheme.successSoft,
            child: Text(loc.stageCompleted, style: LegalTheme.ibm(size: 14, weight: FontWeight.w600, color: LegalTheme.success)),
          ),
        ],
      ],
    );
  }

  Widget _meta(String k, String v) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: LegalTheme.ibm(size: 10, color: LegalTheme.muted)),
          Text(v, style: LegalTheme.ibm(size: 14, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.c, required this.loc});
  final LegalCase c;
  final LegalStrings loc;

  @override
  Widget build(BuildContext context) {
    final stages = LegalContractStage.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < stages.length; i++)
            _Step(
              index: i + 1,
              label: labelStage(loc, stages[i]),
              current: c.stage == stages[i],
              done: i < c.stage.index,
              blocked: c.priority == LegalPriority.blocked && i == c.stage.index,
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.label, required this.current, required this.done, required this.blocked});
  final int index;
  final String label;
  final bool current;
  final bool done;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final color = blocked
        ? LegalTheme.danger
        : current
            ? LegalTheme.primary
            : done
                ? LegalTheme.success
                : LegalTheme.muted;
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: current || done || blocked ? color : LegalTheme.surfaceLow,
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    index.toString().padLeft(2, '0'),
                    style: LegalTheme.ibm(size: 10, weight: FontWeight.w700, color: current || blocked ? Colors.white : LegalTheme.muted),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: LegalTheme.ibm(size: 10, weight: current ? FontWeight.w700 : FontWeight.w400, color: color),
          ),
        ],
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.title, required this.p, required this.loc});
  final String title;
  final LegalParty p;
  final LegalStrings loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: LegalTheme.outline), borderRadius: BorderRadius.circular(4), color: Theme.of(context).cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LegalTheme.ibm(size: 12, weight: FontWeight.w700, letterSpacing: 0.8, color: LegalTheme.primary)),
          const SizedBox(height: 8),
          Text(p.name, style: LegalTheme.ibm(size: 16, weight: FontWeight.w600)),
          _row(loc.userId, p.madarUserId),
          _row(loc.phone, p.phone),
          _row(loc.country, p.country),
          _row(loc.identityStatus, p.identityStatus.name),
          _row(loc.documentStatus, p.documentStatus.name),
          _row(loc.otpStatus, p.otpStatus.name),
          Text(loc.otpHidden, style: LegalTheme.ibm(size: 11, color: LegalTheme.muted)),
          _row(loc.faceStatus, p.faceStatus.name),
          _row(loc.signatureStatus, p.signatureStatus.name),
          _row(loc.status, p.confirmation.name),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(child: Text(k, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted))),
          Text(v, style: LegalTheme.ibm(size: 12, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.c, required this.loc, required this.onOpen});
  final LegalCase c;
  final LegalStrings loc;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: LegalTheme.outline), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.property, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
          Text('${c.propertyId} · ${c.propertyType} · ${c.area}'),
          Text(c.propertyAddress),
          Text('${loc.price}: ${c.price}'),
          Text('${loc.ownership}: ${c.ownershipInfo}'),
          if (c.specialLegalConditions != null) Text('${loc.specialConditions}: ${c.specialLegalConditions}'),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: onOpen, child: Text(loc.openProperty)),
          ),
        ],
      ),
    );
  }
}

class _RtoCard extends StatelessWidget {
  const _RtoCard({required this.t, required this.loc});
  final RentToOwnTerms t;
  final LegalStrings loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: LegalTheme.outline), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.rentToOwn, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
          Text('${loc.price}: ${t.propertyPrice}'),
          Text('${loc.monthlyPayment}: ${t.monthlyPayment}'),
          Text('${loc.duration}: ${t.durationMonths}'),
          Text('${loc.transferCondition}: ${t.ownershipTransferCondition}'),
          Text('${loc.paymentSchedule}: ${t.scheduleSummary}'),
          if (t.initialPayment != null) Text('${loc.initialPayment}: ${t.initialPayment}'),
        ],
      ),
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({
    required this.c,
    required this.loc,
    required this.onReject,
    required this.onApprove,
    required this.onReplace,
    required this.onRequest,
  });
  final LegalCase c;
  final LegalStrings loc;
  final void Function(LegalDocumentReq) onReject;
  final void Function(LegalDocumentReq) onApprove;
  final void Function(LegalDocumentReq) onReplace;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.add, size: 16),
              label: Text(loc.addRequirement),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: c.documents.length,
            itemBuilder: (_, i) {
              final d = c.documents[i];
              return ExpansionTile(
                title: Text(d.name, style: LegalTheme.ibm(size: 14, weight: FontWeight.w600)),
                subtitle: Text('${d.party} · ${d.required ? loc.required : loc.optional}'),
                trailing: LegalStatusChip(label: labelDoc(loc, d.status), tone: toneForDoc(d.status)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (d.deadline != null) Text('${loc.deadline}: ${d.deadline}'),
                        if (d.notes != null) Text('${loc.notes}: ${d.notes}'),
                        Text(loc.versions, style: LegalTheme.ibm(size: 13, weight: FontWeight.w600)),
                        for (final v in d.versions)
                          ListTile(
                            dense: true,
                            title: Text('V${v.version} · ${labelDoc(loc, v.status)}'),
                            subtitle: v.rejectionReason != null ? Text(v.rejectionReason!) : null,
                          ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(onPressed: () => _viewer(context, d, loc), child: Text(loc.view)),
                            TextButton(onPressed: () => onApprove(d), child: Text(loc.approve)),
                            TextButton(onPressed: () => onReject(d), child: Text(loc.reject)),
                            TextButton(onPressed: () => onReplace(d), child: Text(loc.requestReplacement)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _viewer(BuildContext context, LegalDocumentReq d, LegalStrings loc) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          width: 640,
          height: 520,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: Text(d.name, style: LegalTheme.ibm(size: 16, weight: FontWeight.w600))),
                    IconButton(onPressed: () {}, tooltip: loc.zoom, icon: const Icon(Icons.zoom_in)),
                    IconButton(onPressed: () {}, tooltip: loc.download, icon: const Icon(Icons.download)),
                    IconButton(onPressed: () {}, tooltip: loc.print, icon: const Icon(Icons.print)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  color: LegalTheme.surfaceLow,
                  alignment: Alignment.center,
                  child: Text(
                    '${d.name}\n${c.transactionNumber}\n${d.party}',
                    textAlign: TextAlign.center,
                    style: LegalTheme.ibm(size: 14, color: LegalTheme.muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewTab extends StatelessWidget {
  const _ReviewTab({required this.c, required this.loc, required this.ws});
  final LegalCase c;
  final LegalStrings loc;
  final LegalWorkspaceController ws;

  @override
  Widget build(BuildContext context) {
    final r = c.review;
    Widget row(String label, bool v, void Function(bool) on) {
      return CheckboxListTile(
        value: v,
        onChanged: (x) => on(x ?? false),
        title: Text(label),
        controlAffinity: ListTileControlAffinity.leading,
      );
    }

    return ListView(
      children: [
        row(loc.buyer, r.buyerIdentity, (v) => ws.setReviewCheck(c.id, r.copyWith(buyerIdentity: v))),
        row(loc.seller, r.sellerIdentity, (v) => ws.setReviewCheck(c.id, r.copyWith(sellerIdentity: v))),
        row(loc.ownership, r.propertyOwnership, (v) => ws.setReviewCheck(c.id, r.copyWith(propertyOwnership: v))),
        row(loc.property, r.propertyInformation, (v) => ws.setReviewCheck(c.id, r.copyWith(propertyInformation: v))),
        row(loc.requiredDocuments, r.requiredDocuments, (v) => ws.setReviewCheck(c.id, r.copyWith(requiredDocuments: v))),
        row(loc.price, r.transactionPrice, (v) => ws.setReviewCheck(c.id, r.copyWith(transactionPrice: v))),
        row(loc.monthlyPayment, r.paymentTerms, (v) => ws.setReviewCheck(c.id, r.copyWith(paymentTerms: v))),
        row(loc.specialConditions, r.specialConditions, (v) => ws.setReviewCheck(c.id, r.copyWith(specialConditions: v))),
        row(loc.legalReview, r.additionalLegal, (v) => ws.setReviewCheck(c.id, r.copyWith(additionalLegal: v))),
        const Divider(),
        _ExecutionWatch(c: c, loc: loc, ws: ws),
      ],
    );
  }
}

class _ExecutionWatch extends StatelessWidget {
  const _ExecutionWatch({required this.c, required this.loc, required this.ws});
  final LegalCase c;
  final LegalStrings loc;
  final LegalWorkspaceController ws;

  @override
  Widget build(BuildContext context) {
    Widget line(String l, bool ok) => ListTile(
          dense: true,
          leading: Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, color: ok ? LegalTheme.success : LegalTheme.muted, size: 18),
          title: Text(l),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(loc.cannotBypass, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        ),
        line('${loc.buyer} ${loc.confirmed}', c.buyer.confirmation == PartyConfirmation.confirmed),
        line('${loc.seller} ${loc.confirmed}', c.seller.confirmation == PartyConfirmation.confirmed),
        line('${loc.buyer} OTP', c.buyer.otpStatus == VerificationWatch.verified),
        line('${loc.seller} OTP', c.seller.otpStatus == VerificationWatch.verified),
        line('${loc.buyer} ${loc.faceStatus}', c.buyer.faceStatus == VerificationWatch.verified),
        line('${loc.seller} ${loc.faceStatus}', c.seller.faceStatus == VerificationWatch.verified),
        line('${loc.buyer} ${loc.signed}', c.buyer.signatureStatus == SignatureWatch.signed),
        line('${loc.seller} ${loc.signed}', c.seller.signatureStatus == SignatureWatch.signed),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () => ws.executeIfReady(c.id),
            child: Text(loc.executed),
          ),
        ),
      ],
    );
  }
}

class _ContractTriple extends StatelessWidget {
  const _ContractTriple({
    required this.c,
    required this.loc,
    required this.lang,
    required this.ws,
    required this.sectionIndex,
    required this.onSection,
    required this.contextOpen,
    required this.onToggleContext,
    required this.compareFrom,
    required this.onCompare,
  });
  final LegalCase c;
  final LegalStrings loc;
  final String lang;
  final LegalWorkspaceController ws;
  final int sectionIndex;
  final ValueChanged<int> onSection;
  final bool contextOpen;
  final VoidCallback onToggleContext;
  final int? compareFrom;
  final ValueChanged<int?> onCompare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 240, child: _StructureList(c: c, loc: loc, lang: lang, selected: sectionIndex, onSelect: onSection)),
        const VerticalDivider(width: 1),
        Expanded(child: _EditorPane(c: c, loc: loc, lang: lang, ws: ws, sectionIndex: sectionIndex, compareFrom: compareFrom, onCompare: onCompare)),
        if (contextOpen) ...[
          const VerticalDivider(width: 1),
          SizedBox(width: 280, child: _TxContext(c: c, loc: loc)),
        ],
      ],
    );
  }
}

class _ContractMobile extends StatelessWidget {
  const _ContractMobile({
    required this.c,
    required this.loc,
    required this.lang,
    required this.ws,
    required this.sectionIndex,
    required this.onSection,
    required this.showContext,
    required this.onToggleContext,
  });
  final LegalCase c;
  final LegalStrings loc;
  final String lang;
  final LegalWorkspaceController ws;
  final int sectionIndex;
  final ValueChanged<int> onSection;
  final bool showContext;
  final VoidCallback onToggleContext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ContractStructureCatalog.sectionIds.length,
            itemBuilder: (_, i) {
              final id = ContractStructureCatalog.sectionIds[i];
              final sel = i == sectionIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: ChoiceChip(
                  label: Text(ContractStructureCatalog.title(id, lang == 'ku' ? 'ku' : lang == 'en' ? 'en' : 'ar')),
                  selected: sel,
                  onSelected: (_) => onSection(i),
                ),
              );
            },
          ),
        ),
        Expanded(child: _EditorPane(c: c, loc: loc, lang: lang, ws: ws, sectionIndex: sectionIndex, compareFrom: null, onCompare: (_) {})),
      ],
    );
  }
}

class _StructureList extends StatelessWidget {
  const _StructureList({required this.c, required this.loc, required this.lang, required this.selected, required this.onSelect});
  final LegalCase c;
  final LegalStrings loc;
  final String lang;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: ContractStructureCatalog.sectionIds.length,
      itemBuilder: (_, i) {
        final id = ContractStructureCatalog.sectionIds[i];
        return ListTile(
          dense: true,
          selected: i == selected,
          title: Text(ContractStructureCatalog.title(id, lang == 'en' ? 'en' : lang == 'ku' ? 'ku' : 'ar'), style: LegalTheme.ibm(size: 13)),
          onTap: () => onSelect(i),
        );
      },
    );
  }
}

class _EditorPane extends StatelessWidget {
  const _EditorPane({
    required this.c,
    required this.loc,
    required this.lang,
    required this.ws,
    required this.sectionIndex,
    required this.compareFrom,
    required this.onCompare,
  });
  final LegalCase c;
  final LegalStrings loc;
  final String lang;
  final LegalWorkspaceController ws;
  final int sectionIndex;
  final int? compareFrom;
  final ValueChanged<int?> onCompare;

  @override
  Widget build(BuildContext context) {
    final cur = c.currentContract;
    final locked = cur?.locked == true;
    final id = ContractStructureCatalog.sectionIds[sectionIndex.clamp(0, ContractStructureCatalog.sectionIds.length - 1)];
    LegalContractSection? section;
    if (cur != null) {
      for (final s in cur.sections) {
        if (s.id == id) {
          section = s;
          break;
        }
      }
    }
    final warnings = ws.validateBeforeSend(c);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('${loc.version} ${cur?.label ?? '—'}', style: LegalTheme.mono(size: 13)),
            const Spacer(),
            if (locked) LegalStatusChip(label: loc.locked, tone: LegalTone.danger),
          ],
        ),
        if (locked) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(loc.executedLocked)),
        const SizedBox(height: 8),
        Text(section?.title ?? ContractStructureCatalog.title(id, 'ar'), style: LegalTheme.ibm(size: 18, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: LegalTheme.surface, border: Border.all(color: LegalTheme.outline)),
          child: Text(section?.body ?? '', style: LegalTheme.ibm(size: 16, height: 1.6)),
        ),
        const SizedBox(height: 12),
        Text(loc.clauseLibrary, style: LegalTheme.ibm(size: 14, weight: FontWeight.w600)),
        Text(loc.clauseDisclaimer, style: LegalTheme.ibm(size: 11, color: LegalTheme.muted)),
        Wrap(
          spacing: 6,
          children: [
            for (final cl in LegalClauseLibrary.catalog)
              ActionChip(
                label: Text('${cl.id} ${cl.titleAr}', style: LegalTheme.ibm(size: 11)),
                onPressed: locked ? null : () => ws.insertClause(c.id, id, cl),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (c.contracts.length >= 2)
          TextButton(
            onPressed: () {
              final a = c.contracts[c.contracts.length - 2];
              final b = c.contracts.last;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(loc.compareVersions),
                  content: SingleChildScrollView(child: Text(ws.diff(a, b))),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.close))],
                ),
              );
            },
            child: Text(loc.compareVersions),
          ),
        if (warnings.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: LegalTheme.warningSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.validationWarning, style: LegalTheme.ibm(size: 13, weight: FontWeight.w700, color: LegalTheme.warning)),
                for (final w in warnings) Text('· $w'),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: locked ? null : () => ws.saveDraft(c.id, cur?.sections ?? [], 'مسودة'),
              child: Text(loc.saveDraft),
            ),
            FilledButton(
              onPressed: locked || !ws.canApproveSend(c)
                  ? null
                  : () => _sendPreview(context, c, loc, ws),
              child: Text(loc.approveAndSend),
            ),
            OutlinedButton(
              onPressed: () => _pdf(context, c, loc, ws),
              child: Text(loc.generatePdf),
            ),
          ],
        ),
        if (cur?.sentToBuyer == true) Text(loc.sentToBuyer, style: LegalTheme.ibm(size: 12, color: LegalTheme.success)),
        if (cur?.sentToSeller == true) Text(loc.sentToSeller, style: LegalTheme.ibm(size: 12, color: LegalTheme.success)),
      ],
    );
  }

  void _sendPreview(BuildContext context, LegalCase c, LegalStrings loc, LegalWorkspaceController ws) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.readyToSend),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${loc.navContracts}: ${c.contractNumber}'),
            Text('${loc.buyer}: ${c.buyer.name}'),
            Text('${loc.seller}: ${c.seller.name}'),
            Text('${loc.property}: ${c.propertyAddress}'),
            Text('${loc.price}: ${c.authorizedAmount}'),
            Text('${loc.version}: ${c.currentContract?.label}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ws.approveAndSend(c.id);
            },
            child: Text(loc.approveAndSend),
          ),
        ],
      ),
    );
  }

  void _pdf(BuildContext context, LegalCase c, LegalStrings loc, LegalWorkspaceController ws) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.generatePdf),
        content: SizedBox(
          width: 480,
          height: 420,
          child: SingleChildScrollView(child: Text(ws.contractPlainText(c), style: LegalTheme.ibm(size: 13, height: 1.5))),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.close))],
      ),
    );
  }
}

class _TxContext extends StatelessWidget {
  const _TxContext({required this.c, required this.loc});
  final LegalCase c;
  final LegalStrings loc;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(c.transactionNumber, style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
        Text('${loc.buyer}: ${c.buyer.name}'),
        Text('${loc.seller}: ${c.seller.name}'),
        Text('${loc.propertyId}: ${c.propertyId}'),
        Text('${loc.price}: ${c.authorizedAmount}'),
        Text('${loc.currentStage}: ${labelStage(loc, c.stage)}'),
        const Divider(),
        Text(loc.requiredDocuments, style: LegalTheme.ibm(size: 12, weight: FontWeight.w700)),
        for (final d in c.documents)
          Text('${d.name} — ${labelDoc(loc, d.status)}', style: LegalTheme.ibm(size: 12)),
      ],
    );
  }
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab({required this.c, required this.loc, required this.noteCtrl, required this.msgCtrl, required this.ws});
  final LegalCase c;
  final LegalStrings loc;
  final TextEditingController noteCtrl;
  final TextEditingController msgCtrl;
  final LegalWorkspaceController ws;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(loc.internalChat, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        Text(loc.internalNeverCustomer, style: LegalTheme.ibm(size: 12, color: LegalTheme.danger)),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: const Color(0xFFFFF8E1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final n in c.notes.where((n) => n.visibility == LegalNoteVisibility.internal))
                Text('${n.at} · ${n.author}\n${n.body}'),
              for (final m in c.messages.where((m) => m.internal))
                Text('${m.at} · ${m.author}\n${m.body}'),
            ],
          ),
        ),
        TextField(controller: noteCtrl, decoration: InputDecoration(labelText: loc.internalNote)),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () {
              if (noteCtrl.text.trim().isEmpty) return;
              ws.addNote(c.id, LegalNoteVisibility.internal, noteCtrl.text.trim());
              noteCtrl.clear();
            },
            child: Text(loc.save),
          ),
        ),
        const Divider(),
        Text(loc.customerChat, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        Text('${c.transactionNumber} · ${loc.buyer}: ${c.buyer.name} · ${c.propertyId}'),
        for (final m in c.messages.where((m) => !m.internal))
          ListTile(dense: true, title: Text(m.body), subtitle: Text('${m.channel.name} · ${m.author}')),
        TextField(controller: msgCtrl, decoration: InputDecoration(labelText: loc.customerNote)),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () {
              if (msgCtrl.text.trim().isEmpty) return;
              ws.addMessage(c.id, LegalMessageChannel.buyer, '${c.transactionNumber}\n${msgCtrl.text.trim()}');
              msgCtrl.clear();
            },
            child: Text(loc.send),
          ),
        ),
      ],
    );
  }
}

class _AuditTab extends StatelessWidget {
  const _AuditTab({required this.c, required this.loc});
  final LegalCase c;
  final LegalStrings loc;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: c.audit.length,
      itemBuilder: (_, i) {
        final e = c.audit[c.audit.length - 1 - i];
        return ListTile(
          dense: true,
          title: Text(e.action, style: LegalTheme.ibm(size: 13, weight: FontWeight.w600)),
          subtitle: Text('${e.lawyerId} · ${e.at} · ${e.transactionNumber}\n${e.result}'),
        );
      },
    );
  }
}
