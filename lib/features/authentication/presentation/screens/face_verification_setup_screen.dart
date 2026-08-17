import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../providers/user_auth_notifier.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_container.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/demo_auto_advance.dart';
import '../widgets/primary_auth_button.dart';
import '../widgets/secondary_auth_button.dart';

class FaceVerificationSetupScreen extends StatelessWidget {
  const FaceVerificationSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<UserAuthNotifier>();
    final state = auth.state;

    return DemoAutoAdvance(
      delay: const Duration(milliseconds: 2800),
      onAdvance: () {
        if (!state.isBusy) auth.skipFaceVerification();
      },
      child: AuthContainer(
        onLanguageTap: () => LanguageSelectorSheet.show(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: loc.authFaceTitle,
              subtitle: loc.authFaceSubtitle,
            ),
            const SizedBox(height: AuthSpacing.xl),
            const Center(child: _FaceFrameMark()),
            if (state.userMessage != null) ...[
              const SizedBox(height: AuthSpacing.md),
              AuthErrorBanner(message: state.userMessage!),
            ],
            const SizedBox(height: AuthSpacing.xl),
            PrimaryAuthButton(
              label: loc.authSetupFaceVerification,
              isLoading: state.isBusy,
              onPressed: auth.setupFaceVerification,
            ),
            const SizedBox(height: AuthSpacing.md),
            SecondaryAuthButton(
              label: loc.authSkipForNow,
              onPressed: state.isBusy ? null : auth.skipFaceVerification,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceFrameMark extends StatelessWidget {
  const _FaceFrameMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF90CAF9), width: 2),
            ),
            child: const Icon(
              Icons.face_retouching_natural,
              size: 64,
              color: Color(0xFF1565C0),
            ),
          ),
          const Positioned(
            right: 8,
            bottom: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2E7D32),
              child: Icon(Icons.check, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
