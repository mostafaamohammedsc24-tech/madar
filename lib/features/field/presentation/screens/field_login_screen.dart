import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/field_strings.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../../../authentication/presentation/theme/auth_theme.dart';
import '../../../authentication/presentation/widgets/auth_container.dart';
import '../../../authentication/presentation/widgets/auth_error_banner.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/primary_auth_button.dart';
import '../../../legal/presentation/theme/legal_theme.dart';
import '../providers/field_auth_notifier.dart';

class FieldLoginScreen extends StatefulWidget {
  const FieldLoginScreen({super.key});
  @override
  State<FieldLoginScreen> createState() => _FieldLoginScreenState();
}

class _FieldLoginScreenState extends State<FieldLoginScreen> {
  final _id = TextEditingController();
  final _secret = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _id.dispose();
    _secret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = FieldStrings.of(AppLocalizations.of(context));
    final auth = context.watch<FieldAuthNotifier>();
    final can = _id.text.trim().isNotEmpty && _secret.text.isNotEmpty && !auth.isBusy;
    return AuthContainer(
      onLanguageTap: () => LanguageSelectorSheet.show(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(title: loc.loginTitle, subtitle: loc.loginSubtitle),
            const SizedBox(height: 12),
            Text(loc.notOthers, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
            const SizedBox(height: 8),
            Text(loc.notPublish, style: LegalTheme.ibm(size: 12, color: LegalTheme.muted)),
            const SizedBox(height: AuthSpacing.xl),
            Text(loc.employeeId, style: AuthTypography.caption(context)),
            const SizedBox(height: 8),
            TextField(
              controller: _id,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(hintText: loc.employeeHint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(4))),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(loc.secret, style: AuthTypography.caption(context)),
            const SizedBox(height: 8),
            TextField(
              controller: _secret,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: loc.secret,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: can ? (_) => _submit(auth) : null,
            ),
            if (auth.message != null) ...[const SizedBox(height: 12), AuthErrorBanner(message: loc.invalid)],
            const SizedBox(height: 24),
            PrimaryAuthButton(label: loc.signIn, isLoading: auth.isBusy, enabled: can, onPressed: () => _submit(auth)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => context.go('/employee-portal'), child: Text(AppLocalizations.of(context).officeBackToUserLogin)),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(FieldAuthNotifier auth) async {
    final ok = await auth.login(employeeId: _id.text, secret: _secret.text);
    if (!mounted) return;
    if (ok) context.go('/field/work');
  }
}
