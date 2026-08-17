import 'package:flutter/material.dart';

import '../theme/auth_theme.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
  });

  final String title;
  final String subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(height: AuthSpacing.lg),
        ],
        Text(title, style: AuthTypography.display(context)),
        const SizedBox(height: AuthSpacing.md),
        Text(subtitle, style: AuthTypography.body(context)),
      ],
    );
  }
}
