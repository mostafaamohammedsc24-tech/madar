import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/legal_strings.dart';
import '../providers/user_auth_notifier.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_container.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/primary_auth_button.dart';
import '../widgets/security_setup_card.dart';

class FaceVerificationSetupScreen extends StatefulWidget {
  const FaceVerificationSetupScreen({super.key});

  @override
  State<FaceVerificationSetupScreen> createState() =>
      _FaceVerificationSetupScreenState();
}

class _FaceVerificationSetupScreenState
    extends State<FaceVerificationSetupScreen> {
  Uint8List? _photo;
  String? _localError;
  bool _capturing = false;

  Future<void> _capture() async {
    setState(() {
      _capturing = true;
      _localError = null;
    });
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (file == null) {
        setState(() {
          _capturing = false;
          _localError = LegalStrings.of(AppLocalizations.of(context)).faceCaptureFailed;
        });
        return;
      }
      final bytes = await file.readAsBytes();
      setState(() {
        _photo = bytes;
        _capturing = false;
      });
    } catch (_) {
      setState(() {
        _capturing = false;
        _localError = LegalStrings.of(AppLocalizations.of(context)).faceCaptureFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final legal = LegalStrings.of(loc);
    final auth = context.watch<UserAuthNotifier>();
    final state = auth.state;

    return AuthContainer(
      showLanguageAction: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: loc.authFaceTitle,
              subtitle: legal.faceRequired,
            ),
            const SizedBox(height: AuthSpacing.xl),
            SecuritySetupCard(
              title: loc.authFaceCardTitle,
              description: loc.authFaceCardDescription,
            ),
            const SizedBox(height: AuthSpacing.lg),
            if (_photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_photo!, height: 220, fit: BoxFit.cover),
              ),
            if (state.userMessage != null) ...[
              const SizedBox(height: AuthSpacing.md),
              AuthErrorBanner(message: state.userMessage!),
            ],
            if (_localError != null) ...[
              const SizedBox(height: AuthSpacing.md),
              AuthErrorBanner(message: _localError!),
            ],
            const SizedBox(height: AuthSpacing.xl),
            if (_photo == null)
              PrimaryAuthButton(
                label: legal.captureFace,
                isLoading: _capturing || state.isBusy,
                onPressed: _capture,
              )
            else ...[
              PrimaryAuthButton(
                label: legal.confirmPhoto,
                isLoading: state.isBusy,
                onPressed: () => auth.completeFaceCapture(_photo!),
              ),
              const SizedBox(height: AuthSpacing.md),
              OutlinedButton(
                onPressed: state.isBusy ? null : _capture,
                child: Text(legal.retakePhoto),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
