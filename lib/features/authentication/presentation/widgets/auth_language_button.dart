import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../theme/app_theme.dart';

class AuthLanguageButton extends StatelessWidget {
  const AuthLanguageButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LocaleProvider>().language;
    final badge = switch (language) {
      AppLanguage.arabic => 'ع',
      AppLanguage.kurdish => 'ک',
      AppLanguage.english => 'En',
    };

    return Material(
      color: const Color(0xFFE3F2FD),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              badge,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
