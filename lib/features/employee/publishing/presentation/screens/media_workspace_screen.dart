import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../theme/app_theme.dart';
import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/publishing_repository.dart';
import '../../domain/publishing_models.dart';

/// Photography / 3D specialist workspace — mobile-first media production.
class MediaWorkspaceScreen extends StatefulWidget {
  const MediaWorkspaceScreen({super.key, required this.propertyAssetId});

  final String propertyAssetId;

  @override
  State<MediaWorkspaceScreen> createState() => _MediaWorkspaceScreenState();
}

class _MediaWorkspaceScreenState extends State<MediaWorkspaceScreen> {
  late PublishingRepository _repo;
  PropertyAsset? _asset;
  List<Map<String, dynamic>> _photos = const [];
  List<Map<String, dynamic>> _points = const [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

  static const _checklist = [
    'exterior',
    'street',
    'front_facade',
    'entrance',
    'living_room',
    'kitchen',
    'dining_room',
    'bedrooms',
    'bathrooms',
    'corridors',
    'stairs',
    'balcony',
    'garden',
    'roof',
    'garage',
    'basement',
    'storage',
    'surrounding_area',
  ];

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final asset = await _repo.getAsset(widget.propertyAssetId);
      if (asset == null) throw StateError('Property not found');
      final photos = await _repo.listMedia(asset.id);
      final points = await _repo.list3dPoints(asset.id);
      if (!mounted) return;
      setState(() {
        _asset = asset;
        _photos = photos;
        _points = points;
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

  Future<void> _registerPhoto(String category) async {
    final asset = _asset;
    if (asset == null) return;
    final seq =
        _photos.where((p) => p['category']?.toString() == category).length + 1;
    setState(() => _busy = true);
    try {
      final ok = await _repo.registerMedia(
        propertyAssetId: asset.id,
        category: category,
        roomLabel: category,
        sequence: seq,
        caption: 'Field capture — $category',
        mediaUrl: 'pending/${asset.publicPropertyId}/$category/$seq',
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not register photo'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addCapturePoint() async {
    final asset = _asset;
    if (asset == null) return;
    final roomCtrl = TextEditingController();
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add 3D capture point',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roomCtrl,
              decoration: const InputDecoration(
                labelText: 'Room / position',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add point'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || roomCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final code =
          'POINT-${(_points.length + 1).toString().padLeft(3, '0')}';
      final saved = await _repo.add3dPoint(
        propertyAssetId: asset.id,
        pointCode: code,
        roomLabel: roomCtrl.text.trim(),
        sequence: _points.length + 1,
      );
      if (!mounted) return;
      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not add capture point'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final asset = _asset;
    if (asset == null) return;
    setState(() => _busy = true);
    try {
      final res = await _repo.submitMediaPackage(
        propertyAssetId: asset.id,
        photoCount: _photos.length,
        threeDPoints: _points.length,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.success
                ? 'Media package submitted'
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          asset == null
              ? 'Media workspace'
              : 'Media · #${asset.publicPropertyId}',
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
                    Text(
                      'Photography checklist',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Register each category after capture. Quality gates run before publishing review.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF757575),
                          ),
                    ),
                    const SizedBox(height: 12),
                    ..._checklist.map((c) {
                      final count = _photos
                          .where((p) => p['category']?.toString() == c)
                          .length;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          count > 0
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: count > 0
                              ? AppTheme.success
                              : const Color(0xFF757575),
                        ),
                        title: Text(c.replaceAll('_', ' ')),
                        subtitle: Text('$count registered'),
                        trailing: TextButton(
                          onPressed: _busy ? null : () => _registerPhoto(c),
                          child: const Text('Add'),
                        ),
                      );
                    }),
                    const Divider(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '3D capture points',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _busy ? null : _addCapturePoint,
                          icon: const Icon(Icons.add),
                          label: const Text('Point'),
                        ),
                      ],
                    ),
                    if (_points.isEmpty)
                      Text(
                        'No capture points yet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF757575),
                            ),
                      ),
                    ..._points.map(
                      (p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.threed_rotation),
                        title: Text(p['point_code']?.toString() ?? '—'),
                        subtitle: Text(p['room_label']?.toString() ?? '—'),
                        trailing: Text('#${p['sequence_no'] ?? ''}'),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _busy || _photos.isEmpty ? null : _submit,
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
                : Text(
                    'Submit media (${_photos.length} photos · ${_points.length} 3D)',
                  ),
          ),
        ),
      ),
    );
  }
}
