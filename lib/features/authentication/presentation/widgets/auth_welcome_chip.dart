import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../theme/auth_theme.dart';

class AuthWelcomeChip extends StatelessWidget {
  const AuthWelcomeChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: AuthTypography.welcome(context)),
      ),
    );
  }
}
