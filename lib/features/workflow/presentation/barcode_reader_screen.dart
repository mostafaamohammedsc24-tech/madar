import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/deal_workflow_store.dart';
import '../domain/deal_workflow_models.dart';

/// Live camera + manual entry barcode reader for deal / published property codes.
class BarcodeReaderScreen extends StatefulWidget {
  const BarcodeReaderScreen({super.key});

  @override
  State<BarcodeReaderScreen> createState() => _BarcodeReaderScreenState();
}

class _BarcodeReaderScreenState extends State<BarcodeReaderScreen> {
  final _manualCtrl = TextEditingController();
  MobileScannerController? _camera;
  bool _cameraReady = false;
  bool _handling = false;
  String? _lastRaw;
  String? _status;
  ResolvedBarcode? _resolved;

  @override
  void initState() {
    super.initState();
    DealWorkflowStore.instance.ensureSeeded();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final c = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128],
      );
      await c.start();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _camera = c;
        _cameraReady = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraReady = false;
          _status = 'Camera unavailable — use manual entry or gallery.';
        });
      }
    }
  }

  @override
  void dispose() {
    _manualCtrl.dispose();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue?.trim())
        .whereType<String>()
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (raw.isEmpty || raw == _lastRaw) return;
    await _resolve(raw);
  }

  Future<void> _resolve(String raw) async {
    setState(() {
      _handling = true;
      _lastRaw = raw;
      _status = 'Looking up…';
      _resolved = null;
    });
    HapticFeedback.mediumImpact();
    final hit = DealWorkflowStore.instance.resolve(raw);
    if (!mounted) return;
    setState(() {
      _handling = false;
      _resolved = hit;
      _status = hit == null
          ? 'No match for “$raw”. Try BUY-/SEL-/PUB- published codes.'
          : null;
    });
  }

  Future<void> _pickGallery() async {
    final loc = AppLocalizations.of(context);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;

      if (!kIsWeb) {
        try {
          final result =
              await MobileScannerController().analyzeImage(image.path);
          final code = result?.barcodes
              .map((b) => b.rawValue)
              .whereType<String>()
              .firstWhere((v) => v.trim().isNotEmpty, orElse: () => '');
          if (code != null && code.isNotEmpty) {
            await _resolve(code);
            return;
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _status = loc.barcodeNotFound;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = 'Could not read image — paste the code below.';
      });
    }
  }

  void _openResolved(ResolvedBarcode hit) {
    switch (hit.kind) {
      case BarcodeKind.buyerDeal:
      case BarcodeKind.sellerDeal:
      case BarcodeKind.transactionNumber:
        final id = hit.transactionId;
        if (id != null && id.isNotEmpty) {
          context.push(
            '/transaction-detail',
            extra: {'id': id},
          );
        } else {
          context.push('/deal-workflow?deal=${Uri.encodeComponent(hit.rawCode)}');
        }
      case BarcodeKind.publishingAsset:
        final assetId = hit.publishingAssetId;
        if (assetId != null && assetId.isNotEmpty) {
          context.push('/employee/publishing/property/$assetId');
        } else {
          context.push('/deal-workflow');
        }
      case BarcodeKind.unknown:
        context.push('/deal-workflow');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(loc.scanBarcode),
        actions: [
          IconButton(
            tooltip: 'Workflow board',
            onPressed: () => context.push('/deal-workflow'),
            icon: const Icon(Icons.account_tree_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'Scan any published deal or property barcode across offices, lawyers, publishers, and parties.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: Colors.black,
                child: _cameraReady && _camera != null
                    ? MobileScanner(
                        controller: _camera!,
                        onDetect: _onDetect,
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _status ??
                                'Starting camera… You can also enter a code manually.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(loc.chooseFromGallery),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/deal-workflow'),
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text('Workflow'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _manualCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: loc.enterBarcodeManually,
              hintText: 'BUY-… / SEL-… / PUB-…',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  final v = _manualCtrl.text.trim();
                  if (v.isNotEmpty) _resolve(v);
                },
              ),
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) _resolve(v.trim());
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in const [
                'BUY-SEED-001',
                'SEL-SEED-001',
                'BUY-SEED-002',
                'PUB-88421011',
                'PUB-88421022',
              ])
                ActionChip(
                  label: Text(code),
                  onPressed: () {
                    _manualCtrl.text = code;
                    _resolve(code);
                  },
                ),
            ],
          ),
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(
              _status!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (_resolved != null) ...[
            const SizedBox(height: 20),
            _ResolvedCard(
              hit: _resolved!,
              onOpen: () => _openResolved(_resolved!),
              onWorkflow: () {
                final id = _resolved!.transactionId ?? _resolved!.rawCode;
                context.push('/deal-workflow?deal=${Uri.encodeComponent(id)}');
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ResolvedCard extends StatelessWidget {
  const _ResolvedCard({
    required this.hit,
    required this.onOpen,
    required this.onWorkflow,
  });

  final ResolvedBarcode hit;
  final VoidCallback onOpen;
  final VoidCallback onWorkflow;

  String get _kindLabel {
    switch (hit.kind) {
      case BarcodeKind.buyerDeal:
        return 'Buyer deal barcode';
      case BarcodeKind.sellerDeal:
        return 'Seller deal barcode';
      case BarcodeKind.publishingAsset:
        return 'Published property barcode';
      case BarcodeKind.transactionNumber:
        return 'Transaction number';
      case BarcodeKind.unknown:
        return 'Barcode';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = hit.lifecycleState;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hit.label ?? _kindLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _kindLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hit.rawCode,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (stage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Stage: ${stage.wireValue}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onOpen,
              child: const Text('Open record'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onWorkflow,
              child: const Text('View cross-role workflow'),
            ),
          ],
        ),
      ),
    );
  }
}
