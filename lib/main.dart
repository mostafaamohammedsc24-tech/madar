import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import './core/localization/app_localizations.dart';
import './core/localization/locale_provider.dart';
import './providers/country_context_provider.dart';
import './features/authentication/routing/auth_globals.dart';
import './features/office/routing/office_globals.dart';
import './features/legal/routing/legal_globals.dart';
import './features/closing/routing/closing_globals.dart';
import './features/mapping/routing/mapping_globals.dart';
import './features/field/routing/field_globals.dart';
import './services/mixpanel_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';
import 'core/app_export.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  try {
    await MixpanelService.instance.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Mixpanel: $e');
  }

  wireOfficeAuthIntoRouter();
  wireLegalAuthIntoRouter();
  wireClosingAuthIntoRouter();
  wireMappingAuthIntoRouter();
  wireFieldAuthIntoRouter();
  await officeAuthNotifier.initialize();
  await legalAuthNotifier.initialize();
  await closingAuthNotifier.initialize();
  await mappingAuthNotifier.initialize();
  await fieldAuthNotifier.initialize();

  bool hasShownError = false;

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;
      Future.delayed(const Duration(seconds: 5), () {
        hasShownError = false;
      });
      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
          provider.ChangeNotifierProvider.value(value: legalAuthNotifier),
          provider.ChangeNotifierProvider.value(value: closingAuthNotifier),
          provider.ChangeNotifierProvider.value(value: mappingAuthNotifier),
          provider.ChangeNotifierProvider.value(value: fieldAuthNotifier),
        ],
        child: const MyApp(),
      ),
    ),
  );
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
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(1.0)),
                    child: child!,
                  );
                },
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
