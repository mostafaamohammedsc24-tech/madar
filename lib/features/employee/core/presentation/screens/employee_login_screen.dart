import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/locale_provider.dart';
import '../../../../../services/bank_seed.dart';
import '../../../../../services/publisher_seed.dart';
import '../../../../../widgets/language_selector_sheet.dart';
import '../../../../authentication/presentation/theme/auth_theme.dart';
import '../../../../authentication/presentation/widgets/auth_container.dart';
import '../../../../authentication/presentation/widgets/auth_error_banner.dart';
import '../../../../authentication/presentation/widgets/auth_header.dart';
import '../../../../authentication/presentation/widgets/auth_text_field.dart';
import '../../../../authentication/presentation/widgets/primary_auth_button.dart';
import '../providers/employee_auth_notifier.dart';

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final _idCtrl = TextEditingController(text: BankSeed.code);
  final _secretCtrl = TextEditingController(text: BankSeed.secret);
  bool _obscure = true;

  String _homeFor(EmployeeAuthNotifier auth) {
    if (auth.employee?.isPublishing == true || auth.employee?.isBank == true) {
      return '/employee/work';
    }
    return '/employee/home';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<EmployeeAuthNotifier>();
      await auth.ensureInitialized();
      if (!mounted) return;
      if (auth.isAuthenticated) {
        context.go(_homeFor(auth));
      }
    });
  }

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
    if (ok) {
      if (auth.employee?.isBank == true) {
        await context.read<LocaleProvider>().setLanguage(AppLanguage.arabic);
      }
      if (!mounted) return;
      context.go(_homeFor(auth));
    }
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
    final canSubmit =
        _idCtrl.text.trim().isNotEmpty &&
        _secretCtrl.text.isNotEmpty &&
        !auth.isBusy;

    return AuthContainer(
      onLanguageTap: () => LanguageSelectorSheet.show(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(title: loc.empLoginTitle, subtitle: loc.empLoginSubtitle),
          const SizedBox(height: AuthSpacing.xl),
          Text(loc.empIdLabel, style: AuthTypography.caption(context)),
          const SizedBox(height: AuthSpacing.sm),
          AuthTextField(
            controller: _idCtrl,
            hintText: loc.empIdHint,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AuthSpacing.lg),
          Text(loc.empSecretLabel, style: AuthTypography.caption(context)),
          const SizedBox(height: AuthSpacing.sm),
          AuthTextField(
            controller: _secretCtrl,
            hintText: loc.empSecretHint,
            obscureText: _obscure,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: canSubmit ? (_) => _submit(auth) : null,
          ),
          const SizedBox(height: AuthSpacing.md),
          Text(
            'Bank: ${BankSeed.code} / ${BankSeed.secret}  ·  Publisher: ${PublisherSeed.code}',
            textAlign: TextAlign.center,
            style: AuthTypography.caption(context).copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
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
    );
  }
}
