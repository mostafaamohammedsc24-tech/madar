import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../providers/user_auth_notifier.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_container.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_role_login_buttons.dart';
import '../widgets/demo_auto_advance.dart';
import '../widgets/otp_input_field.dart';
import '../widgets/primary_auth_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpKey = GlobalKey<OtpInputFieldState>();
  bool _hasError = false;
  String _code = '';

  String _timer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

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

    return DemoAutoAdvance(
      delay: const Duration(milliseconds: 2800),
      onAdvance: () {
        if (!state.isBusy) auth.verifyOtp('123456');
      },
      child: AuthContainer(
        onLanguageTap: () => LanguageSelectorSheet.show(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: loc.authOtpTitle,
              subtitle: state.otpDeliveryChannel == 'sms'
                  ? loc.authOtpSentViaSms
                  : loc.authOtpSubtitle(state.maskedPhoneNumber),
            ),
            const SizedBox(height: AuthSpacing.md),
            InkWell(
              onTap: state.isBusy ? null : auth.goBackToPhoneEntry,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.fullPhoneNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AuthColors.ink,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AuthColors.canvasSoft,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuthSpacing.xl),
            OtpInputField(
              key: _otpKey,
              length: 6,
              enabled: !state.isBusy,
              hasError: _hasError && state.userMessage != null,
              onChanged: (value) {
                _code = value;
                if (_hasError) setState(() => _hasError = false);
              },
              onCompleted: (code) {
                if (!state.isBusy) auth.verifyOtp(code);
              },
            ),
            const SizedBox(height: AuthSpacing.lg),
            Text(
              _timer(state.otpResendSeconds),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AuthColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: state.canResendOtp ? auth.resendOtp : null,
                child: Text(
                  loc.authResendOtp,
                  style: TextStyle(
                    color: state.canResendOtp
                        ? AuthColors.canvasSoft
                        : AuthColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (state.otpDeliveryChannel != 'sms')
              Center(
                child: TextButton(
                  onPressed: state.canResendOtp && !state.isBusy
                      ? auth.sendOtpViaSms
                      : null,
                  child: Text(
                    loc.authSendViaSms,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: state.canResendOtp
                          ? AuthColors.canvasSoft
                          : AuthColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            if (state.userMessage != null) ...[
              const SizedBox(height: AuthSpacing.md),
              AuthErrorBanner(message: state.userMessage!),
            ],
            const SizedBox(height: AuthSpacing.lg),
            PrimaryAuthButton(
              label: loc.authVerifyContinue,
              isLoading: state.isBusy,
              onPressed: () {
                final code = _code;
                if (code.isNotEmpty) auth.verifyOtp(code);
              },
            ),
            const SizedBox(height: AuthSpacing.md),
            const AuthRoleLoginButtons(),
          ],
        ),
      ),
    );
  }
}
