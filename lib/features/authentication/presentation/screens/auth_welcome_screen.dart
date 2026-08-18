import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../widgets/language_selector_sheet.dart';
import '../theme/auth_theme.dart';
import '../widgets/auth_brand_mark.dart';
import '../widgets/auth_language_button.dart';
import '../widgets/auth_role_login_buttons.dart';
import '../widgets/demo_auto_advance.dart';

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return DemoAutoAdvance(
      delay: const Duration(milliseconds: 3200),
      onAdvance: onStart,
      child: Scaffold(
        backgroundColor: AuthColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 12, 0),
                  child: AuthLanguageButton(
                    onTap: () => LanguageSelectorSheet.show(context),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 8,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AuthSpacing.maxContentWidth,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  loc.authWelcomeTo,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const AuthBrandMark(
                                  fontSize: 52,
                                  showIcon: true,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  loc.authWelcomeTagline,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    loc.authWelcomeMessageTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      width: 1.4,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 16,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    loc.authWelcomeMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      height: 1.55,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: AuthSpacing.buttonHeight,
                                  child: FilledButton(
                                    onPressed: onStart,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AuthColors.ink,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AuthSpacing.radiusPill,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      loc.authLetsStart,
                                      style: AuthTypography.button(
                                        context,
                                      ).copyWith(color: AuthColors.ink),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const AuthRoleLoginButtons(
                                  variant: AuthRoleLoginVariant.outlineOnBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
