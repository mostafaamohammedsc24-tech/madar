import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../providers/user_auth_notifier.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_container.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_welcome_chip.dart';
import '../widgets/demo_auto_advance.dart';
import '../widgets/primary_auth_button.dart';
import '../widgets/secondary_auth_button.dart';
import '../widgets/security_setup_card.dart';

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
      showLanguageAction: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthWelcomeChip(label: loc.authWelcome),
            const SizedBox(height: AuthSpacing.lg),
            AuthHeader(
              title: loc.authFaceTitle,
              subtitle: loc.authFaceSubtitle,
            ),
            const SizedBox(height: AuthSpacing.xl),
            SecuritySetupCard(
              title: loc.authFaceCardTitle,
              description: loc.authFaceCardDescription,
            ),
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
    ),
    );
  }
}
