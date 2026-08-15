import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class AddPropertySheetWidget extends StatefulWidget {
  final VoidCallback? onSubmitted;
  const AddPropertySheetWidget({super.key, this.onSubmitted});

  @override
  State<AddPropertySheetWidget> createState() => _AddPropertySheetWidgetState();
}

class _AddPropertySheetWidgetState extends State<AddPropertySheetWidget> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();

  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _selectedPropertyType;
  String? _selectedListingType;
  double? _latitude;
  double? _longitude;
  bool _locationGranted = false;
  bool _isGettingLocation = false;
  XFile? _pickedImage;
  String? _uploadedImageUrl;

  final List<Map<String, String>> _propertyTypes = [
    {'key': 'apartment', 'label': 'شقة', 'icon': '🏢'},
    {'key': 'villa', 'label': 'فيلا', 'icon': '🏡'},
    {'key': 'land', 'label': 'أرض', 'icon': '🌿'},
    {'key': 'commercial', 'label': 'تجاري', 'icon': '🏪'},
    {'key': 'building', 'label': 'عمارة', 'icon': '🏗️'},
    {'key': 'office', 'label': 'مكتب', 'icon': '🖥️'},
  ];

  final List<Map<String, String>> _listingTypes = [
    {'key': 'sale', 'label': 'للبيع', 'icon': '💰'},
    {'key': 'rent', 'label': 'للإيجار', 'icon': '🔑'},
    {'key': 'mortgage', 'label': 'رهن', 'icon': '🏦'},
    {'key': 'investment', 'label': 'استثمار', 'icon': '📈'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('خدمة الموقع غير مفعّلة');
        setState(() => _isGettingLocation = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('تم رفض إذن الموقع');
          setState(() => _isGettingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('الموقع محظور — يرجى تفعيله من الإعدادات');
        setState(() => _isGettingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _locationGranted = true;
        _isGettingLocation = false;
        _addressController.text =
            '${pos.latitude.toStringAsFixed(4)}°N, ${pos.longitude.toStringAsFixed(4)}°E';
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
      _showSnack('تعذّر الحصول على الموقع');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (e) {
      _showSnack('تعذّر اختيار الصورة');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (e) {
      _showSnack('تعذّر فتح الكاميرا');
    }
  }

  bool _canProceedStep0() {
    return _locationGranted || _addressController.text.trim().isNotEmpty;
  }

  bool _canProceedStep1() {
    return _selectedPropertyType != null && _selectedListingType != null;
  }

  void _nextStep() {
    if (_currentStep == 0 && !_canProceedStep0()) {
      _showSnack('يرجى تحديد موقع العقار أو إدخال العنوان');
      return;
    }
    if (_currentStep == 1 && !_canProceedStep1()) {
      _showSnack('يرجى اختيار نوع العقار والغرض من الإدراج');
      return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitProperty();
    }
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      // Upload image if picked
      String? imageUrl;
      if (_pickedImage != null) {
        try {
          final bytes = await _pickedImage!.readAsBytes();
          final fileName =
              'property_${DateTime.now().millisecondsSinceEpoch}.jpg';
          imageUrl = await SupabaseService.instance.uploadPropertyImage(
            bytes: bytes,
            fileName: fileName,
          );
        } catch (_) {
          // Image upload failed — continue without image
        }
      }

      final result = await SupabaseService.instance.submitPropertyRequest(
        latitude: _latitude ?? 33.3152,
        longitude: _longitude ?? 44.3932,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : 'موقع GPS محدد',
        contactPhone: _phoneController.text.trim(),
        propertyType: _selectedPropertyType,
        listingType: _selectedListingType,
        notes: _notesController.text.trim(),
        imageUrl: imageUrl,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });
        widget.onSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack('حدث خطأ أثناء الإرسال، يرجى المحاولة مرة أخرى');
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isSubmitted
          ? _buildSuccessState(theme)
          : Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryDark, AppTheme.primary],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add_home,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إضافة عقار جديد',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                // Step indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _StepIndicator(
                    currentStep: _currentStep,
                    steps: const ['الموقع', 'التفاصيل', 'التواصل'],
                  ),
                ),
                const Divider(height: 24),
                // Content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
                      child: _buildStepContent(theme),
                    ),
                  ),
                ),
                // Navigation
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _currentStep--),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'رجوع',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _currentStep == 2 ? 'إرسال الطلب' : 'التالي',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 60,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'تم إرسال طلبك بنجاح!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.warning.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending, color: AppTheme.warning, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'قيد التدقيق',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'سيتواصل معك فريق المبيعات خلال 24 ساعة لترتيب زيارة التصوير والتقييم.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'حسناً',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildLocationStep(theme);
      case 1:
        return _buildDetailsStep(theme);
      case 2:
        return _buildContactStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLocationStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أين يقع عقارك؟',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'شارك موقعك أو اكتب عنوان العقار.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        // GPS button
        GestureDetector(
          onTap: _isGettingLocation ? null : _getCurrentLocation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _locationGranted
                  ? AppTheme.success.withAlpha(15)
                  : AppTheme.primary.withAlpha(13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _locationGranted
                    ? AppTheme.success
                    : AppTheme.primary.withAlpha(51),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _locationGranted
                        ? AppTheme.success
                        : AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isGettingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          _locationGranted ? Icons.check : Icons.my_location,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationGranted
                            ? 'تم تحديد الموقع'
                            : 'استخدام موقعي الحالي',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _locationGranted
                              ? AppTheme.success
                              : AppTheme.primary,
                        ),
                      ),
                      Text(
                        _locationGranted
                            ? '${_latitude?.toStringAsFixed(4)}°N, ${_longitude?.toStringAsFixed(4)}°E'
                            : 'اضغط لمشاركة إحداثيات GPS',
                        style: TextStyle(
                          fontSize: 11,
                          color: _locationGranted
                              ? AppTheme.success
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'أو أدخل العنوان يدوياً',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'العنوان / المنطقة',
            hintText: 'مثال: الكرادة، بالقرب من شارع النضال',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.location_on, color: AppTheme.primary, size: 20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
          ),
        ),
        const SizedBox(height: 20),
        // Photo upload
        Text(
          'صورة العقار',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showImageSourceSheet(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: _pickedImage != null ? 180 : 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _pickedImage != null
                    ? AppTheme.primary.withAlpha(80)
                    : theme.dividerColor,
                style: _pickedImage != null
                    ? BorderStyle.solid
                    : BorderStyle.solid,
              ),
            ),
            child: _pickedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        kIsWeb
                            ? Image.network(
                                _pickedImage!.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_pickedImage!.path),
                                fit: BoxFit.cover,
                              ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _pickedImage = null),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        color: AppTheme.primary.withAlpha(128),
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'إضافة صورة للعقار',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary.withAlpha(179),
                        ),
                      ),
                      Text(
                        'JPEG, PNG حتى 10MB',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.camera_alt, color: AppTheme.primary),
              ),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_library, color: AppTheme.primary),
              ),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفاصيل العقار',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'المعلومات الأساسية تساعد فريقنا على تجهيز الإعلان بشكل أسرع.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'نوع العقار',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: _propertyTypes.map((t) {
            final isSelected = _selectedPropertyType == t['key'];
            return GestureDetector(
              onTap: () => setState(() => _selectedPropertyType = t['key']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : theme.dividerColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t['icon']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      t['label']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'الغرض من الإدراج',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _listingTypes.map((t) {
            final isSelected = _selectedListingType == t['key'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedListingType = t['key']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryLight
                          : theme.colorScheme.surfaceContainerHighest.withAlpha(
                              60,
                            ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryLight
                            : theme.dividerColor,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(t['icon']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          t['label']!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'ملاحظات إضافية (اختياري)',
            hintText: 'أي معلومات إضافية عن العقار...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildContactStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات التواصل',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'سيتصل بك فريق المبيعات لترتيب زيارة احترافية للتصوير.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'رقم الهاتف',
            hintText: '+964 7XX XXX XXXX',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.phone, color: AppTheme.primary, size: 20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
            helperText: 'سنرسل رمز تحقق لهذا الرقم',
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'رقم الهاتف مطلوب';
            }
            if (v.trim().length < 10) {
              return 'أدخل رقم هاتف صحيح';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withAlpha(38)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.summarize, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'ملخص الطلب',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                label: 'نوع العقار',
                value: _propertyTypes.firstWhere(
                  (t) => t['key'] == _selectedPropertyType,
                  orElse: () => {'label': 'غير محدد'},
                )['label']!,
              ),
              _SummaryRow(
                label: 'الغرض',
                value: _listingTypes.firstWhere(
                  (t) => t['key'] == _selectedListingType,
                  orElse: () => {'label': 'غير محدد'},
                )['label']!,
              ),
              _SummaryRow(
                label: 'الموقع',
                value: _locationGranted
                    ? 'تم تحديد GPS'
                    : (_addressController.text.trim().isNotEmpty
                          ? _addressController.text.trim()
                          : 'غير محدد'),
              ),
              _SummaryRow(
                label: 'الصورة',
                value: _pickedImage != null ? 'تم إرفاق صورة ✓' : 'بدون صورة',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primary.withAlpha(153),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'بعد الإرسال سيكون طلبك في حالة "قيد التدقيق" حتى يتواصل معك الفريق.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary.withAlpha(179),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              color: isCompleted
                  ? AppTheme.primary
                  : Theme.of(context).dividerColor,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isCompleted = stepIndex < currentStep;
        final isCurrent = stepIndex == currentStep;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppTheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted || isCurrent
                      ? AppTheme.primary
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isCurrent
                              ? Colors.white
                              : AppTheme.primary.withAlpha(102),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                color: isCurrent
                    ? AppTheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }
}
