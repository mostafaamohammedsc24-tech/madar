import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/madar_drag_handle.dart';

/// Static, scrollable deal-barcode sheet with a single primary action.
class BarcodeUploadWidget extends StatefulWidget {
  const BarcodeUploadWidget({
    super.key,
    required this.onUpload,
    this.onBarcodeScanned,
    this.showDragHandle = true,
  });

  final VoidCallback onUpload;
  final ValueChanged<String>? onBarcodeScanned;
  final bool showDragHandle;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onUpload,
    ValueChanged<String>? onBarcodeScanned,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: BarcodeUploadWidget(
          onUpload: () {
            Navigator.of(ctx).pop();
            onUpload();
          },
          onBarcodeScanned: (code) {
            Navigator.of(ctx).pop();
            onBarcodeScanned?.call(code);
          },
        ),
      ),
    );
  }

  @override
  State<BarcodeUploadWidget> createState() => _BarcodeUploadWidgetState();
}

class _BarcodeUploadWidgetState extends State<BarcodeUploadWidget> {
  bool _busy = false;

  Future<void> _pickBarcodeImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;

      if (!kIsWeb) {
        try {
          final result = await MobileScannerController().analyzeImage(
            image.path,
          );
          final barcodes = result?.barcodes ?? [];
          final code = barcodes.isEmpty ? null : barcodes.first.rawValue;
          if (code != null && code.isNotEmpty) {
            if (widget.onBarcodeScanned != null) {
              widget.onBarcodeScanned!(code);
            } else {
              widget.onUpload();
            }
            return;
          }
        } catch (_) {}
      }

      widget.onUpload();
    } catch (_) {
      widget.onUpload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 10, 24, 20 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showDragHandle) ...[
                  const MadarDragHandle(),
                  const SizedBox(height: 28),
                ],
                const _BarcodeHeroIcon(),
                const SizedBox(height: 20),
                Text(
                  loc.barcodeScanTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.barcodeScanSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _pickBarcodeImage,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.photo_library_outlined, size: 20),
                    label: Text(
                      loc.barcodeUploadImage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.primary.withValues(
                        alpha: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _HowItWorksCard(
                  title: loc.barcodeHowItWorks,
                  steps: [
                    loc.barcodeHowStep1,
                    loc.barcodeHowStep2,
                    loc.barcodeHowStep3,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarcodeHeroIcon extends StatelessWidget {
  const _BarcodeHeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        color: Color(0xFFE3F2FD),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.qr_code_2_rounded,
        size: 44,
        color: AppTheme.primary,
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            _HowStep(index: '${i + 1}', text: steps[i]),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({required this.index, required this.text});

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              index,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF475467),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
