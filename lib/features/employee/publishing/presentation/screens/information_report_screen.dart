import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';
import '../../domain/publishing_models.dart';

/// Mobile-first collapsible Property Intelligence Report for field specialists.
class InformationReportScreen extends StatefulWidget {
  const InformationReportScreen({super.key, required this.propertyAssetId});

  final String propertyAssetId;

  @override
  State<InformationReportScreen> createState() =>
      _InformationReportScreenState();
}

class _InformationReportScreenState extends State<InformationReportScreen> {
  late PublishingRepository _repo;
  bool _loading = true;
  PropertyAsset? _asset;
  Map<String, dynamic> _basic = {};
  Map<String, dynamic> _location = {};
  Map<String, dynamic> _dimensions = {};
  Map<String, dynamic> _utilities = {};
  Map<String, dynamic> _neighborhood = {};
  Map<String, dynamic> _condition = {};
  Map<String, dynamic> _construction = {};
  final _notes = TextEditingController();
  final List<PropertyRoomDraft> _rooms = [];
  int _requiredCompleted = 0;
  static const _requiredTotal = 92;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = PublishingRepository(
        context.read<EmployeeAuthNotifier>().repository,
      );
      _load();
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final asset = await _repo.getAsset(widget.propertyAssetId);
    final info = await _repo.loadInformation(widget.propertyAssetId);
    final rooms = await _repo.listRooms(widget.propertyAssetId);
    if (!mounted) return;
    setState(() {
      _asset = asset;
      if (info != null) {
        _basic = Map<String, dynamic>.from(info['basic'] as Map? ?? {});
        _location = Map<String, dynamic>.from(info['location'] as Map? ?? {});
        _dimensions =
            Map<String, dynamic>.from(info['dimensions'] as Map? ?? {});
        _utilities =
            Map<String, dynamic>.from(info['utilities'] as Map? ?? {});
        _neighborhood =
            Map<String, dynamic>.from(info['neighborhood'] as Map? ?? {});
        _condition =
            Map<String, dynamic>.from(info['condition'] as Map? ?? {});
        _construction =
            Map<String, dynamic>.from(info['construction'] as Map? ?? {});
        _notes.text = info['field_notes'] as String? ?? '';
        _requiredCompleted =
            (info['required_completed'] as num?)?.toInt() ?? 0;
      }
      _rooms
        ..clear()
        ..addAll(
          rooms.map(
            (r) => PropertyRoomDraft(
              id: r['id']?.toString(),
              roomType: r['room_type'] as String? ?? 'bedroom',
              roomName: r['room_name'] as String? ?? '',
              floorLabel: r['floor_label'] as String? ?? 'ground',
              lengthM: (r['length_m'] as num?)?.toDouble(),
              widthM: (r['width_m'] as num?)?.toDouble(),
              heightM: (r['height_m'] as num?)?.toDouble(),
              windowsCount: (r['windows_count'] as num?)?.toInt(),
              doorsCount: (r['doors_count'] as num?)?.toInt(),
              flooring: r['flooring'] as String?,
              condition: r['condition'] as String?,
              orientation: r['orientation'] as String?,
              notes: r['notes'] as String?,
            ),
          ),
        );
      _loading = false;
    });
  }

  int _computeCompleted() {
    var n = 0;
    void countMap(Map<String, dynamic> m, int weight) {
      final filled = m.values.where((v) => v != null && '$v'.trim().isNotEmpty).length;
      n += filled.clamp(0, weight);
    }
    countMap(_basic, 10);
    countMap(_location, 14);
    countMap(_dimensions, 12);
    countMap(_utilities, 12);
    countMap(_neighborhood, 8);
    countMap(_condition, 6);
    countMap(_construction, 8);
    n += _rooms.length.clamp(0, 20);
    if (_notes.text.trim().isNotEmpty) n += 10;
    return n.clamp(0, _requiredTotal);
  }

  Future<void> _saveSection(String key, Map<String, dynamic> data) async {
    final completed = _computeCompleted();
    await _repo.saveInformationSection(
      propertyAssetId: widget.propertyAssetId,
      sectionKey: key,
      data: data,
      requiredCompleted: completed,
    );
    setState(() => _requiredCompleted = completed);
  }

  Future<void> _startVisit() async {
    await _repo.startFieldVisit(
      propertyAssetId: widget.propertyAssetId,
      visitType: 'information',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Field visit started')),
    );
  }

  Future<void> _addRoom() async {
    final draft = PropertyRoomDraft(roomName: 'Room ${_rooms.length + 1}');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RoomEditor(
        draft: draft,
        onSave: () async {
          await _repo.upsertRoom(draft, widget.propertyAssetId);
          if (ctx.mounted) Navigator.pop(ctx, true);
        },
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _submit() async {
    final completed = _computeCompleted();
    await _repo.saveInformationSection(
      propertyAssetId: widget.propertyAssetId,
      sectionKey: 'condition',
      data: _condition,
      requiredCompleted: completed,
      fieldNotes: _notes.text.trim(),
    );
    final res = await _repo.submitInformationReport(
      propertyAssetId: widget.propertyAssetId,
      requiredCompleted: completed,
      requiredTotal: _requiredTotal,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.success
              ? 'Report submitted (${res.pct}%)'
              : 'Incomplete: $completed/$_requiredTotal — ${res.message}',
        ),
      ),
    );
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = ((_requiredCompleted / _requiredTotal) * 100).round();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Material(
          elevation: 0,
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROPERTY #${_asset?.publicPropertyId ?? ''}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text('PROPERTY REPORT · Completion $pct%'),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: pct / 100, minHeight: 8),
                Text(
                  '$_requiredCompleted / $_requiredTotal required fields',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              FilledButton.tonal(
                onPressed: _startVisit,
                child: const Text('Start field visit'),
              ),
              const SizedBox(height: 8),
              _Section(
                title: 'Basic information',
                child: _MapForm(
                  fields: const [
                    'property_type',
                    'transaction_type',
                    'construction_status',
                    'ownership_type',
                    'year_built',
                    'developer',
                    'builder_company',
                  ],
                  data: _basic,
                  onChanged: (m) {
                    setState(() => _basic = m);
                    _saveSection('basic', m);
                  },
                ),
              ),
              _Section(
                title: 'Exact location (m)',
                child: _MapForm(
                  fields: const [
                    'country',
                    'city',
                    'province',
                    'district',
                    'neighborhood',
                    'street',
                    'street_width_m',
                    'road_type',
                    'latitude',
                    'longitude',
                  ],
                  data: _location,
                  onChanged: (m) {
                    setState(() => _location = m);
                    _saveSection('location', m);
                  },
                ),
              ),
              _Section(
                title: 'Dimensions (m / m²)',
                child: _MapForm(
                  fields: const [
                    'total_land_area_m2',
                    'building_area_m2',
                    'front_width_m',
                    'depth_m',
                    'garden_area_m2',
                    'roof_area_m2',
                    'basement_area_m2',
                    'garage_area_m2',
                  ],
                  data: _dimensions,
                  onChanged: (m) {
                    setState(() => _dimensions = m);
                    _saveSection('dimensions', m);
                  },
                ),
              ),
              _Section(
                title: 'Rooms (${_rooms.length})',
                child: Column(
                  children: [
                    ..._rooms.map(
                      (r) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.roomName.isEmpty ? r.roomType : r.roomName),
                        subtitle: Text(
                          '${r.lengthM ?? '—'}m × ${r.widthM ?? '—'}m · '
                          '${r.areaM2 ?? '—'} m² · ${r.floorLabel}',
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addRoom,
                      icon: const Icon(Icons.add),
                      label: const Text('Add room'),
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Construction & builder',
                child: _MapForm(
                  fields: const [
                    'construction_status',
                    'construction_material',
                    'structure_type',
                    'foundation_type',
                    'roof_type',
                    'exterior_material',
                    'interior_material',
                    'architect',
                    'engineering_office',
                    'last_renovation',
                    'last_maintenance',
                  ],
                  data: _construction,
                  onChanged: (m) {
                    setState(() => _construction = m);
                    _saveSection('construction', m);
                  },
                ),
              ),
              _Section(
                title: 'Utilities',
                child: _MapForm(
                  fields: const [
                    'electricity',
                    'water',
                    'sewer',
                    'gas',
                    'internet',
                    'heating',
                    'cooling',
                    'generator',
                    'solar',
                    'water_tank',
                  ],
                  data: _utilities,
                  onChanged: (m) {
                    setState(() => _utilities = m);
                    _saveSection('utilities', m);
                  },
                ),
              ),
              _Section(
                title: 'Neighborhood intelligence',
                child: _MapForm(
                  fields: const [
                    'street_quality',
                    'noise_level',
                    'traffic',
                    'parking_availability',
                    'safety_notes',
                    'public_transport',
                  ],
                  data: _neighborhood,
                  onChanged: (m) {
                    setState(() => _neighborhood = m);
                    _saveSection('neighborhood', m);
                  },
                ),
              ),
              _Section(
                title: 'Condition',
                child: _MapForm(
                  fields: const [
                    'structural_condition',
                    'interior_condition',
                    'exterior_condition',
                    'maintenance_condition',
                    'renovation_required',
                  ],
                  data: _condition,
                  onChanged: (m) {
                    setState(() => _condition = m);
                    _saveSection('condition', m);
                  },
                ),
              ),
              _Section(
                title: 'Professional field report',
                child: TextField(
                  controller: _notes,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Detailed field notes…',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: FilledButton(
              onPressed: _submit,
              child: Text('Submit report ($_requiredCompleted/$_requiredTotal)'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    );
  }
}

class _MapForm extends StatelessWidget {
  const _MapForm({
    required this.fields,
    required this.data,
    required this.onChanged,
  });

  final List<String> fields;
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final f in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              initialValue: data[f]?.toString() ?? '',
              decoration: InputDecoration(
                labelText: f.replaceAll('_', ' '),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                final next = Map<String, dynamic>.from(data)..[f] = v;
                onChanged(next);
              },
            ),
          ),
      ],
    );
  }
}

class _RoomEditor extends StatelessWidget {
  const _RoomEditor({required this.draft, required this.onSave});
  final PropertyRoomDraft draft;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Room details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: draft.roomName,
              decoration: const InputDecoration(
                labelText: 'Room name',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => draft.roomName = v,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: draft.roomType,
              decoration: const InputDecoration(
                labelText: 'Room type',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => draft.roomType = v,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: draft.lengthM?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Length (m)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => draft.lengthM = double.tryParse(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: draft.widthM?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Width (m)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => draft.widthM = double.tryParse(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: draft.heightM?.toString() ?? '',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height (m)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => draft.heightM = double.tryParse(v),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSave, child: const Text('Save room')),
          ],
        ),
      ),
    );
  }
}
