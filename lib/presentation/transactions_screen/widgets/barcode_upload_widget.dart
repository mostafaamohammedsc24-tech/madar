
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/app_export.dart';
import '../../../core/layout/directional_layout.dart';

class BarcodeUploadWidget extends StatefulWidget {
  final VoidCallback onUpload;
  final Function(String)? onBarcodeScanned;

  const BarcodeUploadWidget({
    super.key,
    required this.onUpload,
    this.onBarcodeScanned,
  });

  @override
  State<BarcodeUploadWidget> createState() => _BarcodeUploadWidgetState();
}

class _BarcodeUploadWidgetState extends State<BarcodeUploadWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isCameraOpen = false;
  MobileScannerController? _scannerController;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _openCamera() {
    if (kIsWeb) {
      // Web: fallback to upload
      _pickImageFromGallery();
      return;
    }
    setState(() {
      _isCameraOpen = true;
      _hasScanned = false;
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    });
  }

  void _closeCamera() {
    _scannerController?.dispose();
    setState(() {
      _isCameraOpen = false;
      _scannerController = null;
    });
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _hasScanned = true);
    _scannerController?.stop();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _closeCamera();
        if (widget.onBarcodeScanned != null) {
          widget.onBarcodeScanned!(code);
        } else {
          widget.onUpload();
        }
      }
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return;

      // Try to scan barcode from image using mobile_scanner
      if (!kIsWeb) {
        try {
          final result = await MobileScannerController().analyzeImage(
            image.path,
          );
          if (result != null && result.barcodes.isNotEmpty) {
            final code = result.barcodes.first.rawValue;
            if (code != null && code.isNotEmpty) {
              if (widget.onBarcodeScanned != null) {
                widget.onBarcodeScanned!(code);
              } else {
                widget.onUpload();
              }
              return;
            }
          }
        } catch (_) {}
      }

      // If no barcode found in image, trigger demo upload
      widget.onUpload();
    } catch (e) {
      widget.onUpload();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCameraOpen) {
      return _buildCameraScanner(context);
    }
    return _buildMainView(context);
  }

  Widget _buildCameraScanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          MobileScanner(
            controller: _scannerController!,
            onDetect: _onBarcodeDetected,
          ),
          // Overlay with scan frame
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 48, 8, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(180), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const DirectionalBackIcon(color: Colors.white),
                    onPressed: _closeCamera,
                  ),
                  const Expanded(
                    child: Text(
                      'مسح رمز الصفقة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flash_off, color: Colors.white),
                    onPressed: () => _scannerController?.toggleTorch(),
                  ),
                ],
              ),
            ),
          ),
          // Bottom instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withAlpha(180), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'وجّه الكاميرا نحو رمز الباركود',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text(
                      'اختر من المعرض',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withAlpha(30),
                      AppTheme.primaryLight.withAlpha(20),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withAlpha(80),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 72,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'مسح رمز الصفقة',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'احصل على رمز الباركود من الوكيل أو المكتب العقاري\nوامسحه لبدء صفقتك',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openCamera,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(
                  kIsWeb ? 'رفع صورة الباركود' : 'مسح الباركود بالكاميرا',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.upload_file),
              label: const Text('رفع صورة الباركود'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary.withAlpha(80)),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  Text(
                    'كيف يعمل؟',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    '1',
                    'يولّد الوكيل/المكتب رمز باركود خاص بالصفقة',
                    theme,
                  ),
                  _buildStep(
                    '2',
                    'يرسل الرمز لكلا الطرفين عبر تطبيق مدار',
                    theme,
                  ),
                  _buildStep(
                    '3',
                    'يرفع كلا الطرفين الرمز لبدء سلسلة الصفقة',
                    theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String num, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(130)
      ..style = PaintingStyle.fill;

    final frameSize = size.width * 0.7;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2;
    final frameRect = Rect.fromLTWH(left, top, frameSize, frameSize);

    // Draw dark overlay with hole
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;
    const r = 16.0;

    // Top-left
    canvas.drawLine(
      Offset(left + r, top),
      Offset(left + r + cornerLen, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + r),
      Offset(left, top + r + cornerLen),
      cornerPaint,
    );
    // Top-right
    canvas.drawLine(
      Offset(left + frameSize - r, top),
      Offset(left + frameSize - r - cornerLen, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameSize, top + r),
      Offset(left + frameSize, top + r + cornerLen),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawLine(
      Offset(left + r, top + frameSize),
      Offset(left + r + cornerLen, top + frameSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + frameSize - r),
      Offset(left, top + frameSize - r - cornerLen),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawLine(
      Offset(left + frameSize - r, top + frameSize),
      Offset(left + frameSize - r - cornerLen, top + frameSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameSize, top + frameSize - r),
      Offset(left + frameSize, top + frameSize - r - cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
