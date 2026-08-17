import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/madar_drag_handle.dart';

/// Scrollable deal-barcode sheet — drag down to dismiss.
class BarcodeUploadWidget extends StatefulWidget {
  const BarcodeUploadWidget({
    super.key,
    required this.onUpload,
    this.onBarcodeScanned,
    this.showDragHandle = true,
    this.scrollController,
  });

  final VoidCallback onUpload;
  final ValueChanged<String>? onBarcodeScanned;
  final bool showDragHandle;
  final ScrollController? scrollController;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onUpload,
    ValueChanged<String>? onBarcodeScanned,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.38,
          maxChildSize: 0.92,
          expand: false,
          snap: true,
          snapSizes: const [0.38, 0.72, 0.92],
          builder: (context, scrollController) {
            return BarcodeUploadWidget(
              scrollController: scrollController,
              onUpload: () {
                Navigator.of(ctx).pop();
                onUpload();
              },
              onBarcodeScanned: (code) {
                Navigator.of(ctx).pop();
                onBarcodeScanned?.call(code);
              },
            );
          },
        );
      },
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
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 10, 24, 20 + bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showDragHandle) ...[
                      const MadarDragHandle(),
                      const SizedBox(height: 28),
                    ],
                    _BarcodeHeroIcon(theme: theme),
                    const SizedBox(height: 20),
                    Text(
                      loc.barcodeScanTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loc.barcodeScanSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.55,
                        color: theme.colorScheme.onSurfaceVariant,
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
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
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
                      theme: theme,
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
          ],
        ),
      ),
    );
  }
}

class _BarcodeHeroIcon extends StatelessWidget {
  const _BarcodeHeroIcon({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: theme.isDarkMode
            ? AppTheme.primary.withValues(alpha: 0.22)
            : const Color(0xFFE3F2FD),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.qr_code_2_rounded,
        size: 44,
        color: theme.isDarkMode ? AppTheme.primaryLight : AppTheme.primary,
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({
    required this.theme,
    required this.title,
    required this.steps,
  });

  final ThemeData theme;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            _HowStep(theme: theme, index: '${i + 1}', text: steps[i]),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({
    required this.theme,
    required this.index,
    required this.text,
  });

  final ThemeData theme;
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
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
