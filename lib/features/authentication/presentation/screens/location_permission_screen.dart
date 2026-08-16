import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../providers/user_auth_notifier.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_container.dart';
import '../widgets/auth_header.dart';
import '../widgets/permission_card.dart';
import '../widgets/primary_auth_button.dart';
import '../widgets/secondary_auth_button.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<UserAuthNotifier>();
    final state = auth.state;

    return AuthContainer(
      showLanguageAction: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: loc.authLocationTitle,
            subtitle: loc.authLocationSubtitle,
          ),
          const Spacer(),
          PermissionCard(
            icon: Icons.location_on_outlined,
            title: loc.authLocationCardTitle,
            description: loc.authLocationCardDescription,
          ),
          const Spacer(),
          PrimaryAuthButton(
            label: loc.authAllowLocation,
            isLoading: state.isBusy,
            onPressed: auth.requestLocationPermission,
          ),
          const SizedBox(height: AuthSpacing.md),
          SecondaryAuthButton(
            label: loc.authNotNow,
            onPressed: state.isBusy ? null : auth.skipLocationPermission,
          ),
        ],
      ),
    );
  }
}
