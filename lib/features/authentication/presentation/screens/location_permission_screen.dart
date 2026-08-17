import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../providers/country_context_provider.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../providers/user_auth_notifier.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_container.dart';
import '../widgets/auth_header.dart';
import '../widgets/primary_auth_button.dart';
import '../widgets/secondary_auth_button.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestNow());
  }

  Future<void> _requestNow() async {
    if (_requested || !mounted) return;
    _requested = true;
    await _applyAfter(
      context.read<UserAuthNotifier>().requestLocationPermission,
    );
  }

  Future<void> _applyAfter(Future<void> Function() action) async {
    await action();
    if (!mounted) return;
    final state = context.read<UserAuthNotifier>().state;
    await context.read<LocaleProvider>().setLanguage(state.selectedLanguage);
    if (!mounted) return;
    await context.read<CountryContextProvider>().setCountry(
      state.selectedCountry,
    );
    if (!mounted) return;
    await context.read<CountryContextProvider>().setCurrency(
      state.selectedCurrencyCode,
      overridden: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<UserAuthNotifier>();
    final state = auth.state;

    return AuthContainer(
      onLanguageTap: () => LanguageSelectorSheet.show(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: loc.authLocationTitle,
            subtitle: loc.authLocationSubtitle,
          ),
          const SizedBox(height: AuthSpacing.xl),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 48,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: AuthSpacing.xl),
          PrimaryAuthButton(
            label: loc.authAllowLocation,
            isLoading: state.isBusy,
            onPressed: () => _applyAfter(auth.requestLocationPermission),
          ),
          const SizedBox(height: AuthSpacing.md),
          SecondaryAuthButton(
            label: loc.authNotNow,
            onPressed: state.isBusy
                ? null
                : () => _applyAfter(auth.skipLocationPermission),
          ),
        ],
      ),
    );
  }
}
