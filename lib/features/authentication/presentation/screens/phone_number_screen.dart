import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../../../office/presentation/widgets/partner_entry_section.dart';
import '../../domain/models/auth_country.dart';
import '../providers/user_auth_notifier.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_container.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/country_selector_sheet.dart';
import '../widgets/demo_auto_advance.dart';
import '../widgets/phone_input_field.dart';
import '../widgets/primary_auth_button.dart';

class PhoneNumberScreen extends StatelessWidget {
  const PhoneNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<UserAuthNotifier>();
    final state = auth.state;
    final digits = state.phoneNumber.replaceAll(RegExp(r'\D'), '');
    final canContinue =
        digits.length >= state.selectedCountry.minPhoneLength && !state.isBusy;

    return DemoAutoAdvance(
      delay: const Duration(milliseconds: 2800),
      onAdvance: () {
        if (canContinue) auth.sendOtp();
      },
      child: AuthContainer(
      onLanguageTap: () => LanguageSelectorSheet.show(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.authWelcome,
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AuthSpacing.sm),
            AuthHeader(
              title: loc.authPhoneTitle,
              subtitle: loc.authPhoneSubtitle,
            ),
            const SizedBox(height: AuthSpacing.xl),
            PhoneInputField(
              country: state.selectedCountry,
              phoneNumber: state.phoneNumber,
              autofocus: true,
              onCountryTap: () async {
                final selected = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CountrySelectorSheet(
                    selectedCountry: state.selectedCountry,
                  ),
                );
                if (selected != null) auth.selectCountry(selected);
              },
              onPhoneChanged: auth.updatePhoneNumber,
              onSubmitted: canContinue ? () => auth.sendOtp() : null,
            ),
            if (state.userMessage != null) ...[
              const SizedBox(height: AuthSpacing.md),
              AuthErrorBanner(message: state.userMessage!),
            ],
            const SizedBox(height: AuthSpacing.xl),
            PrimaryAuthButton(
              label: loc.authContinue,
              isLoading: state.isBusy,
              enabled: canContinue,
              onPressed: auth.sendOtp,
            ),
            const PartnerEntrySection(),
          ],
        ),
      ),
    ),
    );
  }
}
