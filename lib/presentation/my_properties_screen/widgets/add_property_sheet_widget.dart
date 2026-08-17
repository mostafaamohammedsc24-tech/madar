import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/demo/demo_mode.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/madar_drag_handle.dart';
import '../models/owned_property.dart';

class AddPropertySheetWidget extends StatefulWidget {
  const AddPropertySheetWidget({super.key, required this.onSubmitted});

  final ValueChanged<OwnedProperty> onSubmitted;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<OwnedProperty> onSubmitted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: AddPropertySheetWidget(
          onSubmitted: (property) {
            Navigator.of(ctx).pop();
            onSubmitted(property);
          },
        ),
      ),
    );
  }

  @override
  State<AddPropertySheetWidget> createState() => _AddPropertySheetWidgetState();
}

class _AddPropertySheetWidgetState extends State<AddPropertySheetWidget> {
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _busy = false;
  bool _locating = false;
  double? _lat;
  double? _lng;
  XFile? _image;
  Uint8List? _imageBytes;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    final loc = AppLocalizations.of(context);
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _toast(loc.locationDisabled);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _toast(loc.locationDenied);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        if (_addressCtrl.text.trim().isEmpty) {
          _addressCtrl.text =
              '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        }
      });
    } catch (_) {
      _toast(loc.locationFailed);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _image = file;
      _imageBytes = bytes;
    });
  }

  void _chooseSource() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MadarDragHandle(),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(loc.takePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(loc.chooseFromGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    final address = _addressCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final hasLocation = (_lat != null && _lng != null) || address.isNotEmpty;

    if (!hasLocation) {
      _toast(loc.locationRequired);
      return;
    }
    if (_image == null && !DemoMode.enabled) {
      _toast(loc.photoRequired);
      return;
    }
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      _toast(loc.phoneRequired);
      return;
    }

    setState(() => _busy = true);
    String? imageUrl;
    try {
      if (_imageBytes != null) {
        imageUrl = await SupabaseService.instance.uploadPropertyImage(
          bytes: _imageBytes!,
          fileName: 'property_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
      await SupabaseService.instance.submitPropertyRequest(
        latitude: _lat ?? 33.3152,
        longitude: _lng ?? 44.3932,
        address: address.isEmpty ? loc.gpsLocationFallback : address,
        contactPhone: phone,
        imageUrl: imageUrl,
      );
    } catch (_) {}

    if (!mounted) return;
    final property = OwnedProperty(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      titleAr: address.isEmpty ? loc.gpsLocationFallback : address,
      titleEn: address.isEmpty ? loc.gpsLocationFallback : address,
      titleKu: address.isEmpty ? loc.gpsLocationFallback : address,
      addressAr: address.isEmpty ? loc.gpsLocationFallback : address,
      addressEn: address.isEmpty ? loc.gpsLocationFallback : address,
      addressKu: address.isEmpty ? loc.gpsLocationFallback : address,
      kind: OwnedListingKind.titled,
      status: OwnedListingStatus.underReview,
      marketValueUsd: 0,
      imageUrl: imageUrl,
      imageBytes: _imageBytes,
      contactPhone: phone,
    );
    widget.onSubmitted(property);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MadarDragHandle(),
              const SizedBox(height: 16),
              Text(
                loc.addPropertySheetTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                loc.addPropertySheetHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                loc.propertyLocationLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF344054),
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: _lat != null
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _locating ? null : _captureLocation,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _lat != null
                              ? AppTheme.success
                              : AppTheme.primary,
                          child: _locating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _lat != null
                                      ? Icons.check
                                      : Icons.my_location,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _lat != null
                                ? loc.locationCaptured
                                : loc.useCurrentLocation,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _lat != null
                                  ? AppTheme.success
                                  : AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                loc.enterAddressManually,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: loc.addressHint,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF7F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.propertyPhotoLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF344054),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _chooseSource,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  height: 148,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE4E7EC)),
                    image: _imageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_imageBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppTheme.primary.withValues(alpha: 0.8),
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loc.addPropertyPhoto,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        )
                      : Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: IconButton(
                            onPressed: () => setState(() {
                              _image = null;
                              _imageBytes = null;
                            }),
                            icon: const CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.contactNumberLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF344054),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+964 7XX XXX XXXX',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF7F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          loc.submitPropertyRequest,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
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
