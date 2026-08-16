import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../authentication/presentation/theme/auth_theme.dart';
import '../../../../authentication/presentation/widgets/auth_container.dart';
import '../../../../authentication/presentation/widgets/auth_error_banner.dart';
import '../../../../authentication/presentation/widgets/auth_header.dart';
import '../../../../authentication/presentation/widgets/primary_auth_button.dart';
import '../../../../../widgets/language_selector_sheet.dart';
import '../providers/employee_auth_notifier.dart';

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final _idCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _idCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(EmployeeAuthNotifier auth) async {
    final ok = await auth.login(
      employeeCode: _idCtrl.text,
      secretCode: _secretCtrl.text,
    );
    if (!mounted) return;
    if (ok) context.go('/employee/home');
  }

  String _error(AppLocalizations loc, String? code) {
    switch (code) {
      case 'rate_limited':
        return loc.empLoginRateLimited;
      case 'login_unavailable':
        return loc.empLoginUnavailable;
      default:
        return loc.empLoginInvalid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = context.watch<EmployeeAuthNotifier>();
    final canSubmit = _idCtrl.text.trim().isNotEmpty &&
        _secretCtrl.text.isNotEmpty &&
        !auth.isBusy;

    return AuthContainer(
      onLanguageTap: () => LanguageSelectorSheet.show(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: loc.empLoginTitle,
              subtitle: loc.empLoginSubtitle,
            ),
            const SizedBox(height: AuthSpacing.xl),
            Text(loc.empIdLabel, style: AuthTypography.caption(context)),
            const SizedBox(height: AuthSpacing.sm),
            TextField(
              controller: _idCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: loc.empIdHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AuthSpacing.lg),
            Text(loc.empSecretLabel, style: AuthTypography.caption(context)),
            const SizedBox(height: AuthSpacing.sm),
            TextField(
              controller: _secretCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: loc.empSecretHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: canSubmit ? (_) => _submit(auth) : null,
            ),
            if (auth.message != null) ...[
              const SizedBox(height: AuthSpacing.md),
              AuthErrorBanner(message: _error(loc, auth.message)),
            ],
            const SizedBox(height: AuthSpacing.xl),
            PrimaryAuthButton(
              label: loc.empSignIn,
              isLoading: auth.isBusy,
              enabled: canSubmit,
              onPressed: () => _submit(auth),
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
