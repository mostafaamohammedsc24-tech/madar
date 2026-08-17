import 'package:flutter/material.dart';

import '../theme/auth_theme.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AuthSpacing.md),
      decoration: BoxDecoration(
        color: AuthColors.errorSurface,
        borderRadius: BorderRadius.circular(AuthSpacing.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AuthColors.errorText,
            size: 18,
          ),
          const SizedBox(width: AuthSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AuthTypography.caption(context).copyWith(
                color: AuthColors.errorText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
