import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../providers/user_auth_notifier.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_container.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/otp_input_field.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpKey = GlobalKey<OtpInputFieldState>();
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<UserAuthNotifier>();
    final state = auth.state;

    if (state.userMessage != null && !_hasError) {
      _hasError = true;
      _otpKey.currentState?.clear();
    } else if (state.userMessage == null) {
      _hasError = false;
    }

    return AuthContainer(
      showLanguageAction: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                onPressed: state.isBusy ? null : auth.goBackToPhoneEntry,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: AuthSpacing.md),
            AuthHeader(
              title: loc.authOtpTitle,
              subtitle: loc.authOtpSubtitle(state.maskedPhoneNumber),
            ),
            const SizedBox(height: AuthSpacing.xl),
            OtpInputField(
              key: _otpKey,
              length: 6,
              enabled: !state.isBusy,
              hasError: _hasError && state.userMessage != null,
              onChanged: (_) {
                if (_hasError) {
                  setState(() => _hasError = false);
                }
              },
              onCompleted: (code) {
                if (!state.isBusy) auth.verifyOtp(code);
              },
            ),
            if (state.userMessage != null) ...[
              const SizedBox(height: AuthSpacing.md),
              AuthErrorBanner(message: state.userMessage!),
            ],
            const SizedBox(height: AuthSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: state.canResendOtp ? auth.resendOtp : null,
                  child: Text(
                    state.otpResendSeconds > 0
                        ? loc.authResendIn(state.otpResendSeconds)
                        : loc.authResendOtp,
                    style: AuthTypography.caption(context).copyWith(
                      color: state.canResendOtp
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  ' · ',
                  style: AuthTypography.caption(context),
                ),
                TextButton(
                  onPressed: state.isBusy ? null : auth.goBackToPhoneEntry,
                  child: Text(
                    loc.authChangePhone,
                    style: AuthTypography.caption(context).copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
