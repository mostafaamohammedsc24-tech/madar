import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import './core/localization/app_localizations.dart';
import './core/localization/locale_provider.dart';
import './providers/country_context_provider.dart';
import './features/authentication/routing/auth_globals.dart';
import './features/office/routing/office_globals.dart';
import './features/employee/core/routing/employee_globals.dart';
import './services/mixpanel_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';
import 'core/app_export.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Initialize Mixpanel
  try {
    await MixpanelService.instance.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Mixpanel: $e');
  }

  wireOfficeAuthIntoRouter();
  wireEmployeeAuthIntoRouter();
  // Partner sessions restore lazily when visiting office/employee routes.

  const demoEnterUserUi = bool.fromEnvironment(
    'DEMO_ENTER_USER_UI',
    defaultValue: false,
  );
  if (demoEnterUserUi) {
    await userAuthNotifier.enterDemoUserInterface();
  }

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });
      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    runApp(
      ProviderScope(
        child: provider.MultiProvider(
          providers: [
            provider.ChangeNotifierProvider(create: (_) => LocaleProvider()),
            provider.ChangeNotifierProvider(
              create: (_) => CountryContextProvider(),
            ),
            provider.ChangeNotifierProvider.value(value: userAuthNotifier),
            provider.ChangeNotifierProvider.value(value: officeAuthNotifier),
            provider.ChangeNotifierProvider.value(value: employeeAuthNotifier),
          ],
          child: const MyApp(),
        ),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return Sizer(
          builder: (context, orientation, screenType) {
            return Directionality(
              textDirection: localeProvider.textDirection,
              child: MaterialApp.router(
                title: 'Madar | مدار',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: localeProvider.isDarkMode
                    ? ThemeMode.dark
                    : ThemeMode.light,
                localizationsDelegates: [
                  AppLocalizationsDelegate(localeProvider.language),
                ],
                // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(1.0)),
                    child: child!,
                  );
                },
                // 🚨 END CRITICAL SECTION
                debugShowCheckedModeBanner: false,
                routerConfig: appRouter,
              ),
            );
          },
        );
      },
    );
  }
}
