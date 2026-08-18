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
            const Center(child: _FaceFrameMark()),
            const SizedBox(height: AuthSpacing.xl),
            AuthHeader(
              title: loc.authFaceTitle,
              subtitle: loc.authFaceSubtitle,
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
    );
  }
}

class _FaceFrameMark extends StatelessWidget {
  const _FaceFrameMark();

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0D47A1);
    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(148, 148),
            painter: _ViewfinderPainter(color: ink),
          ),
          const Icon(Icons.person_outline_rounded, size: 78, color: ink),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const arm = 28.0;
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, arm)
      ..lineTo(0, 0)
      ..lineTo(arm, 0)
      ..moveTo(w - arm, 0)
      ..lineTo(w, 0)
      ..lineTo(w, arm)
      ..moveTo(w, h - arm)
      ..lineTo(w, h)
      ..lineTo(w - arm, h)
      ..moveTo(arm, h)
      ..lineTo(0, h)
      ..lineTo(0, h - arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) =>
      oldDelegate.color != color;
}
