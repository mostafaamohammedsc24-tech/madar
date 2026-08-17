import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../core/layout/directional_layout.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/supabase_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const EditProfileScreen({this.profile, super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _displayNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _bioCtrl;
  bool _isSaving = false;
  XFile? _pickedImage;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _firstNameCtrl = TextEditingController(
      text: p?['first_name'] as String? ?? '',
    );
    _lastNameCtrl = TextEditingController(
      text: p?['last_name'] as String? ?? '',
    );
    _displayNameCtrl = TextEditingController(
      text: p?['display_name'] as String? ?? '',
    );
    _emailCtrl = TextEditingController(text: p?['email'] as String? ?? '');
    _bioCtrl = TextEditingController(text: p?['bio'] as String? ?? '');
    _currentPhotoUrl = p?['profile_photo_url'] as String?;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _displayNameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _pickedImage = picked);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? photoUrl = _currentPhotoUrl;

      // Upload new photo if picked
      if (_pickedImage != null) {
        try {
          final bytes = await _pickedImage!.readAsBytes();
          final ext = _pickedImage!.name.split('.').last;
          final fileName =
              'profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
          final supabase = SupabaseService.instance.client;
          await supabase.storage
              .from('profile-photos')
              .uploadBinary(
                fileName,
                bytes,
                fileOptions: FileOptions(upsert: true),
              );
          photoUrl = supabase.storage
              .from('profile-photos')
              .getPublicUrl(fileName);
        } catch (_) {}
      }

      await SupabaseService.instance.updateUserProfile({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'display_name': _displayNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        if (photoUrl != null) 'profile_photo_url': photoUrl,
      });

      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.profileSaved,
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.isRTL
                  ? 'حدث خطأ، حاول مجدداً'
                  : 'An error occurred, please try again',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const DirectionalBackIcon(color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.isRTL ? 'تعديل الملف الشخصي' : 'Edit Profile',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    loc.isRTL ? 'حفظ' : 'Save',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile photo
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withAlpha(20),
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(80),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: _pickedImage != null
                              ? (kIsWeb
                                    ? Image.network(
                                        _pickedImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_pickedImage!.path),
                                        fit: BoxFit.cover,
                                      ))
                              : _currentPhotoUrl != null
                              ? Image.network(
                                  _currentPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    color: AppTheme.primary,
                                    size: 48,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: AppTheme.primary,
                                  size: 48,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.isRTL ? 'اضغط لتغيير الصورة' : 'Tap to change photo',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 28),

              // Form fields
              _buildSection(
                theme,
                loc.isRTL ? 'المعلومات الشخصية' : 'Personal Information',
                [
                  _buildTextField(
                    controller: _firstNameCtrl,
                    label: loc.isRTL ? 'الاسم الأول' : 'First Name',
                    icon: Icons.person_outline,
                    theme: theme,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _lastNameCtrl,
                    label: loc.isRTL ? 'اسم العائلة' : 'Last Name',
                    icon: Icons.person_outline,
                    theme: theme,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _displayNameCtrl,
                    label: loc.isRTL ? 'الاسم المعروض' : 'Display Name',
                    icon: Icons.badge_outlined,
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSection(
                theme,
                loc.isRTL ? 'معلومات التواصل' : 'Contact Information',
                [
                  _buildTextField(
                    controller: _emailCtrl,
                    label: loc.isRTL ? 'البريد الإلكتروني' : 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSection(theme, loc.isRTL ? 'نبذة شخصية' : 'Bio', [
                _buildTextField(
                  controller: _bioCtrl,
                  label: loc.isRTL
                      ? 'اكتب نبذة عنك...'
                      : 'Write something about yourself...',
                  icon: Icons.info_outline,
                  maxLines: 4,
                  theme: theme,
                  required: false,
                ),
              ]),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
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
        fillColor: theme.scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) {
                return AppLocalizations.of(context).isRTL
                    ? 'هذا الحقل مطلوب'
                    : 'This field is required';
              }
              return null;
            }
          : null,
    );
  }
}
