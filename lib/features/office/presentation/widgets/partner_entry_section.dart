import 'package:flutter/material.dart';

import '../../../authentication/presentation/widgets/auth_role_login_buttons.dart';

/// Backward-compatible alias for partner login actions on auth screens.
class PartnerEntrySection extends StatelessWidget {
  const PartnerEntrySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthRoleLoginButtons();
  }
}
