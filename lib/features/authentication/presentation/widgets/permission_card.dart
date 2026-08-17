import 'package:flutter/material.dart';

import '../theme/auth_theme.dart';

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AuthSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AuthSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(height: AuthSpacing.lg),
          Text(
            title,
            style: AuthTypography.heading(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AuthSpacing.sm),
          Text(
            description,
            style: AuthTypography.body(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
