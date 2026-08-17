import 'package:flutter/material.dart';

import '../theme/auth_theme.dart';

class PrimaryAuthButton extends StatelessWidget {
  const PrimaryAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: AuthSpacing.buttonHeight,
      child: FilledButton(
        onPressed: (!enabled || isLoading) ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AuthColors.canvas,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AuthColors.canvas.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthSpacing.radiusMd),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Text(label, style: AuthTypography.button(context)),
      ),
    );
  }
}
