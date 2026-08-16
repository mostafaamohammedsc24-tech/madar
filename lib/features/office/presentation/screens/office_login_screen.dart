import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../../../authentication/presentation/theme/auth_theme.dart';
import '../../../authentication/presentation/widgets/auth_container.dart';
import '../../../authentication/presentation/widgets/auth_error_banner.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/primary_auth_button.dart';
import '../providers/office_auth_notifier.dart';

class OfficeLoginScreen extends StatefulWidget {
  const OfficeLoginScreen({super.key});

  @override
  State<OfficeLoginScreen> createState() => _OfficeLoginScreenState();
}

class _OfficeLoginScreenState extends State<OfficeLoginScreen> {
  final _codeCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(OfficeAuthNotifier auth) async {
    final ok = await auth.login(
      officeCode: _codeCtrl.text,
      secretCode: _secretCtrl.text,
    );
    if (!mounted) return;
    if (ok) context.go('/office/home');
  }

  String _friendlyError(AppLocalizations loc, String? code) {
    switch (code) {
      case 'rate_limited':
        return loc.officeLoginRateLimited;
      case 'invalid_credentials':
        return loc.officeLoginInvalid;
      case 'login_unavailable':
        return loc.officeLoginUnavailable;
      default:
        return loc.officeLoginInvalid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = context.watch<OfficeAuthNotifier>();
    final canSubmit =
        _codeCtrl.text.trim().isNotEmpty &&
        _secretCtrl.text.isNotEmpty &&
        !auth.isBusy;

    return AuthContainer(
      onLanguageTap: () => LanguageSelectorSheet.show(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: loc.officeLoginTitle,
              subtitle: loc.officeLoginSubtitle,
            ),
            const SizedBox(height: AuthSpacing.xl),
            Text(loc.officeCodeLabel, style: AuthTypography.caption(context)),
            const SizedBox(height: AuthSpacing.sm),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: loc.officeCodeHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AuthSpacing.lg),
            Text(loc.officeSecretLabel, style: AuthTypography.caption(context)),
            const SizedBox(height: AuthSpacing.sm),
            TextField(
              controller: _secretCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: loc.officeSecretHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: canSubmit ? (_) => _submit(auth) : null,
            ),
            if (auth.message != null) ...[
              const SizedBox(height: AuthSpacing.md),
              AuthErrorBanner(message: _friendlyError(loc, auth.message)),
            ],
            const SizedBox(height: AuthSpacing.xl),
            PrimaryAuthButton(
              label: loc.officeSignIn,
              isLoading: auth.isBusy,
              enabled: canSubmit,
              onPressed: () => _submit(auth),
            ),
            const SizedBox(height: AuthSpacing.md),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.officeForgotCredentialsHint)),
                );
              },
              child: Text(loc.officeForgotCredentials),
            ),
            const SizedBox(height: AuthSpacing.lg),
            TextButton(
              onPressed: () => context.go('/auth'),
              child: Text(
                loc.officeBackToUserLogin,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
