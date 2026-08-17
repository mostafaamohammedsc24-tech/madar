import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../theme/app_theme.dart';
import '../theme/auth_theme.dart';

/// Blue canvas + centered white card used by every auth / partner login screen.
class AuthContainer extends StatelessWidget {
  const AuthContainer({
    super.key,
    required this.child,
    this.footer,
    this.showLanguageAction = true,
    this.onLanguageTap,
  });

  final Widget child;
  final Widget? footer;
  final bool showLanguageAction;
  final VoidCallback? onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AuthColors.canvas,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        loc.authBrandName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AuthSpacing.maxContentWidth,
                          ),
                          child: Material(
                            color: Colors.white,
                            elevation: 0,
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showLanguageAction &&
                                      onLanguageTap != null)
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: AuthLanguageButton(
                                        onTap: onLanguageTap!,
                                      ),
                                    ),
                                  child,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AuthSpacing.maxContentWidth,
                            ),
                            child: footer!,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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
