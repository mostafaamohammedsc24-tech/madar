import 'package:flutter/material.dart';

import '../theme/auth_theme.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: AuthSpacing.md),
            Text(
              'مدار',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1565C0),
              ),
            ),
            Text(
              'عقارات',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
