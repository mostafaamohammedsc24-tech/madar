import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../theme/app_theme.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';
import '../../domain/publishing_models.dart';

/// Mapping / floor-plan engineer workspace.
class EngineeringWorkspaceScreen extends StatefulWidget {
  const EngineeringWorkspaceScreen({super.key, required this.propertyAssetId});

  final String propertyAssetId;

  @override
  State<EngineeringWorkspaceScreen> createState() =>
      _EngineeringWorkspaceScreenState();
}

class _EngineeringWorkspaceScreenState
    extends State<EngineeringWorkspaceScreen> {
  late PublishingRepository _repo;
  PropertyAsset? _asset;
  Map<String, dynamic>? _plan;
  List<Map<String, dynamic>> _floors = const [];
  List<Map<String, dynamic>> _points3d = const [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

  final _scaleCtrl = TextEditingController(text: '1:100');
  final _northCtrl = TextEditingController(text: 'N');

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
    _scaleCtrl.dispose();
    _northCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _allRooms {
    final rooms = <Map<String, dynamic>>[];
    for (final f in _floors) {
      final nested = f['floor_plan_rooms'];
      if (nested is List) {
        for (final r in nested) {
          rooms.add({
            ...Map<String, dynamic>.from(r as Map),
            '_floor_id': f['id']?.toString(),
            '_floor_label': f['floor_label']?.toString(),
          });
        }
      }
    }
    return rooms;
  }

  List<Map<String, dynamic>> get _allPoints {
    final points = <Map<String, dynamic>>[];
    for (final f in _floors) {
      final nested = f['floor_plan_points'];
      if (nested is List) {
        for (final p in nested) {
          points.add(Map<String, dynamic>.from(p as Map));
        }
      }
    }
    return points;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final asset = await _repo.getAsset(widget.propertyAssetId);
      if (asset == null) throw StateError('Property not found');
      final plan = await _repo.ensureFloorPlan(asset.id);
      final floors = plan == null
          ? <Map<String, dynamic>>[]
          : await _repo.listFloors(plan['id'].toString());
      final points3d = await _repo.list3dPoints(asset.id);
      if (!mounted) return;
      setState(() {
        _asset = asset;
        _plan = plan;
        _floors = floors;
        _points3d = points3d;
        if (plan != null) {
          _scaleCtrl.text = plan['scale']?.toString() ?? '1:100';
          _northCtrl.text = plan['north_direction']?.toString() ?? 'N';
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addFloor() async {
    final plan = _plan;
    if (plan == null) {
      await _load();
      return;
    }
    final labelCtrl = TextEditingController(text: 'Ground Floor');
    final keyCtrl = TextEditingController(text: 'ground');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Floor label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'Floor key (basement/ground/1/roof)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add floor'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _repo.addFloor(
        floorPlanId: plan['id'].toString(),
        floorKey: keyCtrl.text.trim().isEmpty ? 'ground' : keyCtrl.text.trim(),
        floorLabel: labelCtrl.text.trim(),
        sortOrder: _floors.length,
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addRoom() async {
    if (_floors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a floor first')),
      );
      return;
    }
    final nameCtrl = TextEditingController();
    final lenCtrl = TextEditingController();
    final widCtrl = TextEditingController();
    final heightCtrl = TextEditingController(text: '3.0');
    var floor = _floors.first;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: floor,
                decoration: const InputDecoration(
                  labelText: 'Floor',
                  border: OutlineInputBorder(),
                ),
                items: _floors
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(f['floor_label']?.toString() ?? 'Floor'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setModal(() => floor = v ?? floor),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Room name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: lenCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Length (m)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: widCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Width (m)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: heightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Height (m)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add room'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await _repo.addFloorRoom(
        floorId: floor['id'].toString(),
        roomName: nameCtrl.text.trim(),
        lengthM: double.tryParse(lenCtrl.text.trim()),
        widthM: double.tryParse(widCtrl.text.trim()),
        heightM: double.tryParse(heightCtrl.text.trim()),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _linkPoint() async {
    final rooms = _allRooms;
    if (rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add rooms before linking 3D points')),
      );
      return;
    }
    var room = rooms.first;
    Map<String, dynamic>? capture =
        _points3d.isEmpty ? null : _points3d.first;
    final labelCtrl = TextEditingController(text: 'Point 01');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: room,
                decoration: const InputDecoration(
                  labelText: 'Floor plan room',
                  border: OutlineInputBorder(),
                ),
                items: rooms
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          '${r['room_name']} · ${r['_floor_label'] ?? ''}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setModal(() => room = v ?? room),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Map<String, dynamic>?>(
                initialValue: capture,
                decoration: const InputDecoration(
                  labelText: '3D capture point',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._points3d.map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${p['point_code']} · ${p['room_label'] ?? ''}',
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setModal(() => capture = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Point label',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Link point'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    final floorId = room['_floor_id']?.toString();
    if (floorId == null) return;
    setState(() => _busy = true);
    try {
      await _repo.addFloorPoint(
        floorId: floorId,
        pointLabel: labelCtrl.text.trim(),
        roomName: room['room_name']?.toString(),
        linked3dPointId: capture?['id']?.toString(),
        xPct: 50,
        yPct: 50,
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final plan = _plan;
    if (plan == null) return;
    setState(() => _busy = true);
    try {
      final res = await _repo.submitFloorPlan(plan['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.success
                ? 'Floor plan submitted'
                : (res.message ?? 'Submit failed'),
          ),
          backgroundColor: res.success ? null : AppTheme.error,
        ),
      );
      if (res.success) context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    final rooms = _allRooms;
    final points = _allPoints;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          asset == null
              ? 'Floor plan'
              : 'Floor plan · #${asset.publicPropertyId}',
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    TextField(
                      controller: _scaleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Scale',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _northCtrl,
                      decoration: const InputDecoration(
                        labelText: 'North direction',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Measurement unit: meters / m²',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF757575),
                          ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              try {
                                await _repo.ensureFloorPlan(
                                  widget.propertyAssetId,
                                  scale: _scaleCtrl.text.trim(),
                                  northDirection: _northCtrl.text.trim(),
                                );
                                await _load();
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                      child: const Text('Save plan metadata'),
                    ),
                    const Divider(height: 28),
                    _sectionHeader('Floors', _addFloor),
                    if (_floors.isEmpty)
                      const Text('No floors yet — add Basement / Ground / …'),
                    ..._floors.map(
                      (f) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.layers_outlined),
                        title: Text(f['floor_label']?.toString() ?? 'Floor'),
                        subtitle: Text('Key: ${f['floor_key'] ?? '—'}'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionHeader('Rooms (m / m²)', _addRoom),
                    ...rooms.map(
                      (r) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(r['room_name']?.toString() ?? 'Room'),
                        subtitle: Text(
                          [
                            if (r['length_m'] != null) 'L ${r['length_m']}m',
                            if (r['width_m'] != null) 'W ${r['width_m']}m',
                            if (r['area_m2'] != null) '${r['area_m2']} m²',
                            if (r['_floor_label'] != null)
                              r['_floor_label'].toString(),
                          ].join(' · '),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionHeader('Interactive 3D points', _linkPoint),
                    ...points.map(
                      (p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.place_outlined),
                        title: Text(p['point_label']?.toString() ?? 'Point'),
                        subtitle: Text(
                          p['linked_3d_point_id'] == null
                              ? 'No 3D link'
                              : 'Linked to 3D capture',
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed:
                _busy || _floors.isEmpty || rooms.isEmpty ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppTheme.primary,
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit floor plan for review'),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onAdd) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        TextButton.icon(
          onPressed: _busy ? null : onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }
}
