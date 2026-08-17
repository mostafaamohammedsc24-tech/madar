import 'package:flutter/material.dart';

import '../theme/auth_theme.dart';

class SecuritySetupCard extends StatelessWidget {
  const SecuritySetupCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.face_retouching_natural_outlined,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AuthSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AuthSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AuthSpacing.radiusSm),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: AuthSpacing.md),
          Text(title, style: AuthTypography.heading(context)),
          const SizedBox(height: AuthSpacing.sm),
          Text(description, style: AuthTypography.body(context)),
        ],
      ),
    );
  }
}
