import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/mapping_strings.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart' hide labelPriority, labelAction, labelStage, labelDoc, toneForPriority, toneForDoc;
import '../../domain/enums/mapping_enums.dart';
import '../../domain/models/mapping_models.dart';
import '../providers/mapping_workspace_controller.dart';
import '../widgets/floor_plan_canvas.dart';
import '../widgets/mapping_labels.dart';

class MappingCaseScreen extends StatefulWidget {
  const MappingCaseScreen({required this.jobId, super.key});
  final String jobId;

  @override
  State<MappingCaseScreen> createState() => _MappingCaseScreenState();
}

class _MappingCaseScreenState extends State<MappingCaseScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _note = TextEditingController();
  final _msg = TextEditingController();
  final _corr = TextEditingController();
  MappingChannel _ch = MappingChannel.publisher;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = context.read<MappingWorkspaceController>();
      final j = ws.byId(widget.jobId);
      if (j != null) {
        ws.audit(j, 'property_opened');
        if (j.floors.isNotEmpty) ws.selectFloor(j.floors.first.id);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _note.dispose();
    _msg.dispose();
    _corr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = MappingStrings.of(AppLocalizations.of(context));
    final ws = context.watch<MappingWorkspaceController>();
    final j = ws.byId(widget.jobId);
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (j == null) return Scaffold(body: Center(child: Text(loc.noActions)));

    return Scaffold(
      backgroundColor: dark ? LegalTheme.darkBg : LegalTheme.paper,
      body: Column(
        children: [
          _Header(j: j, loc: loc, onBack: () => context.pop(), sync: ws.sync, locSync: loc),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            labelColor: LegalTheme.primary,
            tabs: [
              Tab(text: loc.overview),
              Tab(text: loc.canvas),
              Tab(text: loc.navMeas),
              Tab(text: loc.nav3d),
              Tab(text: loc.validation),
              Tab(text: loc.audit),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _Overview(j: j, loc: loc, ws: ws),
                _CanvasTab(j: j, loc: loc, ws: ws),
                _MeasTab(j: j, loc: loc, ws: ws),
                _ConnectTab(j: j, loc: loc, ws: ws, msg: _msg, ch: _ch, onCh: (v) => setState(() => _ch = v)),
                _ValidTab(j: j, loc: loc, ws: ws, corr: _corr, note: _note),
                _AuditTab(j: j),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.j, required this.loc, required this.onBack, required this.sync, required this.locSync});
  final MappingJob j;
  final MappingStrings loc;
  final MappingStrings locSync;
  final VoidCallback onBack;
  final SyncState sync;

  @override
  Widget build(BuildContext context) {
    final syncLabel = switch (sync) {
      SyncState.saved => locSync.saved,
      SyncState.saving => locSync.saving,
      SyncState.offline => locSync.offline,
      SyncState.syncing => locSync.saving,
      SyncState.synced => locSync.synced,
    };
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
                  Text(j.propertyId, style: LegalTheme.mono(size: 20, weight: FontWeight.w700, color: LegalTheme.primary)),
                  Text('${j.requestNumber} · ${j.propertyType} · ${j.address}', style: LegalTheme.ibm(size: 12, color: LegalTheme.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            LegalStatusChip(label: syncLabel, tone: LegalTone.neutral),
            const SizedBox(width: 8),
            LegalStatusChip(label: labelStatus(loc, j.status), tone: toneForStatus(j.status)),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.j, required this.loc, required this.ws});
  final MappingJob j;
  final MappingStrings loc;
  final MappingWorkspaceController ws;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(spacing: 16, runSpacing: 8, children: [
          _meta(loc.propertyId, j.propertyId),
          _meta(loc.requestNo, j.requestNumber),
          _meta(loc.country, j.country),
          _meta(loc.city, j.city),
          _meta(loc.type, j.propertyType),
          _meta(loc.publisher, j.publisher),
          _meta(loc.infoEmp, j.informationEmployee),
          _meta(loc.photoEmp, j.photographer),
          _meta(loc.assigned, '${j.assignedEngineer} · ${j.engineerId}'),
          _meta(loc.deadline, fmtWhen(j.deadline)),
          _meta(loc.bedrooms, '${j.bedrooms}'),
          _meta(loc.bathrooms, '${j.bathrooms}'),
          if (j.unitLabel != null) _meta(loc.unit, j.unitLabel!),
        ]),
        if (j.buildingPlan) ...[
          const SizedBox(height: 8),
          Text(loc.buildingPlan, style: LegalTheme.ibm(size: 12, color: LegalTheme.primary, weight: FontWeight.w600)),
        ],
        const SizedBox(height: 12),
        Text(loc.structures, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
        Text(j.structures.join(' · ')),
        const SizedBox(height: 12),
        Text(loc.floors, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        for (final f in j.floors)
          ListTile(
            title: Text(f.names.ar, style: LegalTheme.ibm(size: 15, weight: FontWeight.w600)),
            subtitle: Text('${loc.area}: ${f.areaM2} م² · ${loc.rooms}: ${f.rooms.length} · ${loc.height}: ${f.ceilingHeightM} م'),
            trailing: LegalStatusChip(label: labelStatus(loc, f.status), tone: toneForStatus(f.status)),
            selected: ws.selectedFloorId == f.id,
            onTap: () => ws.selectFloor(f.id),
          ),
        if (j.infoNotes != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${loc.infoEmp}: ${j.infoNotes}')),
        if (j.photoNotes != null) Text('${loc.photoEmp}: ${j.photoNotes}'),
        const SizedBox(height: 12),
        Text(loc.site, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
        Text('${loc.north}: ${j.metrics.north} · ${loc.entrance}: ${j.metrics.entranceDir} · ${loc.street}: ${j.metrics.streetDir} ${j.metrics.streetWidthM} م'),
        Text('${loc.land}: ${j.metrics.landM2} م² · ${loc.footprint}: ${j.metrics.footprintM2} م² · ${loc.built}: ${j.metrics.totalBuiltM2} م²'),
        Text('${loc.setbacks}: ${j.metrics.frontSetbackM} / ${j.metrics.rearSetbackM} / ${j.metrics.sideSetbackM} م'),
        const SizedBox(height: 8),
        Text(loc.metric, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
      ],
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
}

class _CanvasTab extends StatelessWidget {
  const _CanvasTab({required this.j, required this.loc, required this.ws});
  final MappingJob j;
  final MappingStrings loc;
  final MappingWorkspaceController ws;

  @override
  Widget build(BuildContext context) {
    final floor = ws.floorOf(j);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final canvas = Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _tool(loc.select, ws.selectedTool == 'select', () => ws.setTool('select')),
              _tool(loc.addRoom, ws.selectedTool == 'room', () => ws.setTool('room')),
              _tool(loc.grid, ws.showGrid, ws.toggleGrid),
              _tool(loc.snapGrid, ws.snap, ws.toggleSnap),
              _tool(loc.undo, ws.canUndo, () => ws.undo(j.id)),
              _tool(loc.redo, ws.canRedo, () => ws.redo(j.id)),
              for (final f in j.floors)
                _tool(f.names.ar, ws.selectedFloorId == f.id, () => ws.selectFloor(f.id)),
            ],
          ),
        ),
        if (floor?.sourceFile != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text('${loc.source}: ${floor!.sourceFile} · ${loc.preserve}', style: LegalTheme.ibm(size: 11, color: LegalTheme.muted)),
          ),
        Expanded(
          child: FloorPlanCanvas(
            floor: floor,
            selectedRoomId: ws.selectedRoomId,
            showGrid: ws.showGrid,
            dark: dark,
            tool: ws.selectedTool ?? 'select',
            onSelectRoom: ws.selectRoom,
            onAddRoom: (m) {
              final x = ws.snap ? (m.dx * 2).round() / 2 : m.dx;
              final y = ws.snap ? (m.dy * 2).round() / 2 : m.dy;
              ws.addRoomRect(j.id, x: x, y: y, w: 4, h: 3, kind: RoomKind.custom);
            },
          ),
        ),
      ],
    );

    final inspector = _Inspector(j: j, loc: loc, ws: ws, floor: floor);

    if (wide) {
      return Row(
        children: [
          Expanded(flex: 3, child: canvas),
          SizedBox(width: 320, child: inspector),
        ],
      );
    }
    return Column(
      children: [
        Expanded(flex: 3, child: canvas),
        SizedBox(height: 220, child: inspector),
      ],
    );
  }

  Widget _tool(String label, bool on, VoidCallback tap) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: OutlinedButton(
        onPressed: tap,
        style: OutlinedButton.styleFrom(
          backgroundColor: on ? LegalTheme.softBlue : null,
          minimumSize: const Size(48, 40),
        ),
        child: Text(label, style: LegalTheme.ibm(size: 11, weight: FontWeight.w600)),
      ),
    );
  }
}

class _Inspector extends StatelessWidget {
  const _Inspector({required this.j, required this.loc, required this.ws, required this.floor});
  final MappingJob j;
  final MappingStrings loc;
  final MappingWorkspaceController ws;
  final MappingFloor? floor;

  @override
  Widget build(BuildContext context) {
    MappingRoom? room;
    if (floor != null && ws.selectedRoomId != null) {
      try {
        room = floor!.rooms.firstWhere((r) => r.id == ws.selectedRoomId);
      } catch (_) {}
    }
    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? LegalTheme.darkSurface : LegalTheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(loc.rooms, style: LegalTheme.ibm(size: 14, weight: FontWeight.w700)),
          if (room == null) Text(loc.select, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
          if (room != null) ...[
            Text('${room.names.ar} / ${room.names.en} / ${room.names.ku}', style: LegalTheme.ibm(size: 13, weight: FontWeight.w600)),
            Text(labelRoom(loc, room.kind), style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
            Text('${loc.calcArea}: ${room.calculatedAreaM2.toStringAsFixed(1)} م²'),
            Text('${loc.measArea}: ${room.measuredAreaM2 ?? '—'} م²'),
            Text('${loc.diff}: ${room.areaDifference?.toStringAsFixed(1) ?? '—'} م²'),
            if (room.needsMeasurementReview)
              Text(loc.reviewMeas, style: LegalTheme.ibm(size: 12, color: LegalTheme.warning, weight: FontWeight.w700)),
            Text('${loc.length}: ${room.lengthM ?? '—'}'),
            Text('${loc.width}: ${room.widthM ?? '—'}'),
            Text('${loc.height}: ${room.heightM ?? '—'}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                OutlinedButton(
                  onPressed: () => ws.setRoomDims(j.id, room!.id, height: 2.8),
                  child: Text(loc.height),
                ),
              ],
            ),
            Text('${loc.photos}: ${room.photoIds.join(', ')}'),
            Text('${loc.tour}: ${room.tourPointIds.join(', ')}'),
          ],
          const Divider(),
          Text(loc.doors, style: LegalTheme.ibm(size: 13, weight: FontWeight.w700)),
          Text('${floor?.doors.length ?? 0}'),
          Text(loc.windows),
          Text('${floor?.windows.length ?? 0}'),
          Text(loc.stairs),
          Text('${floor?.stairs.length ?? 0}'),
          Text(loc.points),
          Text('${floor?.points.length ?? 0}'),
        ],
      ),
    );
  }
}

class _MeasTab extends StatelessWidget {
  const _MeasTab({required this.j, required this.loc, required this.ws});
  final MappingJob j;
  final MappingStrings loc;
  final MappingWorkspaceController ws;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(ws.measurementReport(j), style: LegalTheme.mono(size: 12)),
        const SizedBox(height: 12),
        for (final f in j.floors) ...[
          Text(f.names.ar, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
          for (final r in f.rooms)
            ListTile(
              dense: true,
              title: Text(r.names.ar),
              subtitle: Text('${r.lengthM ?? '—'} × ${r.widthM ?? '—'} م · ${r.calculatedAreaM2.toStringAsFixed(1)} م²'),
              trailing: r.needsMeasurementReview ? LegalStatusChip(label: loc.warning, tone: LegalTone.warning) : null,
            ),
          for (final d in f.doors) Text('${loc.doors}: ${d.kind.name} ${d.widthM}×${d.heightM} م'),
          for (final w in f.windows) Text('${loc.windows}: ${w.kind.name} ${w.widthM}×${w.heightM} م'),
        ],
      ],
    );
  }
}

class _ConnectTab extends StatelessWidget {
  const _ConnectTab({required this.j, required this.loc, required this.ws, required this.msg, required this.ch, required this.onCh});
  final MappingJob j;
  final MappingStrings loc;
  final MappingWorkspaceController ws;
  final TextEditingController msg;
  final MappingChannel ch;
  final ValueChanged<MappingChannel> onCh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${j.propertyId} · ${j.requestNumber}', style: LegalTheme.mono(size: 13, color: LegalTheme.primary)),
        Text(loc.connections, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        for (final f in j.floors)
          for (final r in f.rooms)
            Card(
              child: ListTile(
                title: Text(r.names.ar),
                subtitle: Text('صور: ${r.photoIds.join(', ')}\n3D: ${r.tourPointIds.join(', ')}'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v.startsWith('p:')) ws.connectPhoto(j.id, r.id, v.substring(2));
                    if (v.startsWith('t:')) ws.connectTour(j.id, r.id, v.substring(2));
                  },
                  itemBuilder: (_) => [
                    ...j.photos.map((p) => PopupMenuItem(value: 'p:${p.id}', child: Text('${loc.photos}: ${p.label}'))),
                    ...j.tourPoints.map((t) => PopupMenuItem(value: 't:${t.id}', child: Text('${loc.tour}: ${t.label}'))),
                  ],
                  child: Text(loc.connect, style: LegalTheme.ibm(size: 12, color: LegalTheme.primary)),
                ),
              ),
            ),
        const Divider(),
        Text(loc.navMsg, style: LegalTheme.ibm(size: 15, weight: FontWeight.w700)),
        DropdownButton<MappingChannel>(
          value: ch,
          isExpanded: true,
          items: MappingChannel.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
          onChanged: (v) {
            if (v != null) onCh(v);
          },
        ),
        TextField(controller: msg, decoration: InputDecoration(hintText: loc.navMsg)),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () {
              if (msg.text.trim().isEmpty) return;
              ws.addMessage(j.id, ch, msg.text.trim());
              msg.clear();
            },
            child: Text(loc.send),
          ),
        ),
        for (final m in j.messages) ListTile(dense: true, title: Text(m.body), subtitle: Text('${m.author} · ${fmtWhen(m.at)}')),
      ],
    );
  }
}

class _ValidTab extends StatelessWidget {
  const _ValidTab({required this.j, required this.loc, required this.ws, required this.corr, required this.note});
  final MappingJob j;
  final MappingStrings loc;
  final MappingWorkspaceController ws;
  final TextEditingController corr;
  final TextEditingController note;

  @override
  Widget build(BuildContext context) {
    final items = ws.validate(j);
    final pass = items.where((i) => i.ok).length;
    final warn = items.where((i) => i.warning && !i.ok).length;
    final fail = items.where((i) => !i.ok && !i.warning).length;
    final can = ws.canSubmit(j);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(loc.validation, style: LegalTheme.ibm(size: 18, weight: FontWeight.w700)),
        Text('${items.length} · $pass ${loc.passed} · $warn ${loc.warning} · $fail ${loc.failed}'),
        const SizedBox(height: 8),
        for (final i in items)
          ListTile(
            dense: true,
            leading: Icon(
              i.ok ? Icons.check_box : Icons.error_outline,
              color: i.ok ? LegalTheme.success : (i.warning ? LegalTheme.warning : LegalTheme.danger),
            ),
            title: Text(i.label),
          ),
        const SizedBox(height: 8),
        Text(loc.notPublish, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        FilledButton(
          onPressed: can ? () => ws.submitToPublisher(j.id) : null,
          child: Text(loc.submit),
        ),
        if (!can) Text(loc.cannotSubmit, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        const Divider(height: 32),
        Text(loc.correction, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        for (final c in j.corrections) ...[
          Text(c.issue, style: LegalTheme.ibm(size: 13)),
          Text('${c.requestedBy} · ${fmtWhen(c.at)}', style: LegalTheme.ibm(size: 11, color: LegalTheme.muted)),
          if (c.response != null) Text(c.response!),
          TextField(controller: corr, decoration: InputDecoration(hintText: loc.respond)),
          TextButton(
            onPressed: () {
              if (corr.text.trim().isEmpty) return;
              ws.respondCorrection(j.id, c.id, corr.text.trim());
              corr.clear();
            },
            child: Text(loc.respond),
          ),
        ],
        Text(loc.versions, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        for (final v in j.versions)
          ListTile(
            title: Text('V${v.number} · ${v.reason}'),
            subtitle: Text('${v.createdBy} · ${fmtWhen(v.at)} · ${v.changes}'),
            trailing: v.approved ? LegalStatusChip(label: labelStatus(loc, MappingPlanStatus.approved), tone: LegalTone.success) : null,
          ),
        Text(loc.notes, style: LegalTheme.ibm(size: 16, weight: FontWeight.w700)),
        Text(loc.notPublicNotes, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
        for (final n in j.notes) Text('${n.author}: ${n.body}'),
        TextField(controller: note, decoration: InputDecoration(hintText: loc.notes)),
        TextButton(
          onPressed: () {
            if (note.text.trim().isEmpty) return;
            ws.addNote(j.id, note.text.trim());
            note.clear();
          },
          child: Text(loc.save),
        ),
        OutlinedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText(ws.measurementReport(j), style: LegalTheme.mono(size: 12)),
              ),
            );
          },
          child: Text(loc.report),
        ),
      ],
    );
  }
}

class _AuditTab extends StatelessWidget {
  const _AuditTab({required this.j});
  final MappingJob j;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: j.audit.length,
      itemBuilder: (_, i) {
        final a = j.audit[j.audit.length - 1 - i];
        return ListTile(
          title: Text(a.action),
          subtitle: Text('${a.employeeName} · ${a.employeeId} · ${a.propertyId} · ${a.requestId}\n${fmtWhen(a.at)}'),
          isThreeLine: true,
        );
      },
    );
  }
}
