import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../theme/auth_theme.dart';

class AuthPrivacyAgreement extends StatefulWidget {
  const AuthPrivacyAgreement({
    super.key,
    required this.agreed,
    required this.onChanged,
  });

  final bool agreed;
  final ValueChanged<bool> onChanged;

  @override
  State<AuthPrivacyAgreement> createState() => _AuthPrivacyAgreementState();
}

class _AuthPrivacyAgreementState extends State<AuthPrivacyAgreement> {
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()..onTap = () => _openPrivacy();
    _termsTap = TapGestureRecognizer()..onTap = () => _openTerms();
  }

  void _openPrivacy() {
    if (!mounted) return;
    _showPolicy(AppLocalizations.of(context).authPrivacyPolicy);
  }

  void _openTerms() {
    if (!mounted) return;
    _showPolicy(AppLocalizations.of(context).authTermsOfUse);
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  void _showPolicy(String title) {
    final loc = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(loc.authLegalPlaceholder),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.authContinue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const linkStyle = TextStyle(
      color: AuthColors.canvasSoft,
      fontWeight: FontWeight.w700,
      fontSize: 13,
      height: 1.4,
    );
    const bodyStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: AuthColors.muted,
      fontWeight: FontWeight.w500,
    );

    return InkWell(
      onTap: () => widget.onChanged(!widget.agreed),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: widget.agreed,
              onChanged: (v) => widget.onChanged(v ?? false),
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AuthColors.accent;
                }
                return Colors.white;
              }),
              side: const BorderSide(color: Color(0xFF98A2B3)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: bodyStyle,
                children: [
                  TextSpan(text: loc.authAgreeLead),
                  TextSpan(
                    text: loc.authPrivacyPolicy,
                    style: linkStyle,
                    recognizer: _privacyTap,
                  ),
                  TextSpan(text: loc.authAgreeConjunction),
                  TextSpan(
                    text: loc.authTermsOfUse,
                    style: linkStyle,
                    recognizer: _termsTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
