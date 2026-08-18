import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../routes/app_routes.dart';
import '../theme/auth_theme.dart';

enum AuthRoleLoginVariant { filled, outlineOnBlue }

/// Employee and office login actions matching the auth pill buttons.
class AuthRoleLoginButtons extends StatelessWidget {
  const AuthRoleLoginButtons({
    super.key,
    this.variant = AuthRoleLoginVariant.filled,
  });

  final AuthRoleLoginVariant variant;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoleButton(
          label: loc.authEmployeeLoginCta,
          variant: variant,
          onPressed: () => context.push(AppRoutes.employeeLogin),
        ),
        const SizedBox(height: 12),
        _RoleButton(
          label: loc.authOfficeLoginCta,
          variant: variant,
          onPressed: () => context.push(AppRoutes.officeLogin),
        ),
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.variant,
    required this.onPressed,
  });

  final String label;
  final AuthRoleLoginVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isOutline = variant == AuthRoleLoginVariant.outlineOnBlue;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AuthSpacing.radiusPill),
    );

    if (isOutline) {
      return SizedBox(
        height: AuthSpacing.buttonHeight,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 1.6),
            shape: shape,
          ),
          child: Text(
            label,
            style: AuthTypography.button(context).copyWith(color: Colors.white),
          ),
        ),
      );
    }

    return SizedBox(
      height: AuthSpacing.buttonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AuthColors.canvas,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: shape,
        ),
        child: Text(label, style: AuthTypography.button(context)),
      ),
    );
  }
}
