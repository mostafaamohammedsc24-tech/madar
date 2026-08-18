import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../widgets/country_flag_widget.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../../../../widgets/madar_country_selector_sheet.dart';
import '../../domain/models/auth_country.dart';
import '../providers/user_auth_notifier.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_container.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_privacy_agreement.dart';
import '../widgets/auth_role_login_buttons.dart';
import '../widgets/demo_auto_advance.dart';
import '../widgets/phone_input_field.dart';
import '../widgets/primary_auth_button.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  bool _agreed = true;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<UserAuthNotifier>();
    final state = auth.state;
    final digits = state.phoneNumber.replaceAll(RegExp(r'\D'), '');
    final canContinue =
        digits.length >= state.selectedCountry.minPhoneLength &&
        !state.isBusy &&
        _agreed;

    return DemoAutoAdvance(
      delay: const Duration(milliseconds: 2800),
      onAdvance: () {
        if (canContinue) auth.sendOtp();
      },
      child: AuthContainer(
        onLanguageTap: () => LanguageSelectorSheet.show(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: loc.authPhoneTitle,
              subtitle: loc.authPhoneSubtitle,
            ),
            const SizedBox(height: AuthSpacing.lg),
            Text(loc.authCountryField, style: AuthTypography.caption(context)),
            const SizedBox(height: 8),
            Material(
              color: Colors.white,
              elevation: 2,
              shadowColor: const Color(0x1A000000),
              borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
              child: InkWell(
                onTap: () async {
                  final selected = await MadarCountrySelectorSheet.show(
                    context,
                    selectedCountry: state.selectedCountry,
                  );
                  if (selected != null) auth.selectCountry(selected);
                },
                borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
                child: Container(
                  height: AuthSpacing.inputHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
                    border: Border.all(color: const Color(0xFFE6EAF0)),
                  ),
                  child: Row(
                    children: [
                      CountryFlagWidget(
                        countryCode: state.selectedCountry.isoCode,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.selectedCountry.localizedNameFromLoc(loc),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.expand_more,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AuthSpacing.md),
            Text(loc.authPhoneField, style: AuthTypography.caption(context)),
            const SizedBox(height: 8),
            PhoneInputField(
              country: state.selectedCountry,
              phoneNumber: state.phoneNumber,
              autofocus: false,
              showCountrySelector: false,
              onCountryTap: () {},
              onPhoneChanged: auth.updatePhoneNumber,
              onSubmitted: canContinue ? () => auth.sendOtp() : null,
            ),
            const SizedBox(height: AuthSpacing.md),
            AuthPrivacyAgreement(
              agreed: _agreed,
              onChanged: (v) => setState(() => _agreed = v),
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
            const SizedBox(height: AuthSpacing.md),
            const AuthRoleLoginButtons(),
          ],
        ),
      ),
    );
  }
}
