import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sizer/sizer.dart';

import './core/localization/app_localizations.dart';
import './core/localization/locale_provider.dart';
import './theme/app_theme.dart';
import './presentation/property_detail/zillow_property_detail_screen.dart';
import './providers/country_context_provider.dart';
import './services/mixpanel_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';

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

  bool hasShownError = false;

  // Custom error handling
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

  // Device orientation lock
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    const ProviderScope(
      child: ZillowDemoApp(),
    ),
  );
}

class ZillowDemoApp extends StatelessWidget {
  const ZillowDemoApp({super.key});

  static const Map<String, dynamic> mockProperty = {
    'id': '7761_sagemeadow_ct',
    'title': '7761 Sagemeadow Ct',
    'address': '7761 Sagemeadow Ct, Columbus, OH 43235',
    'asking_price': 342000,
    'estimatedValue': 338600,
    'bedrooms': 3,
    'bathrooms': 2,
    'total_area_sqm': 144.7, // ~1,558 sqft
    'sqft': 1558,
    'yearBuilt': 1983,
    'property_type': 'Single Family Residence',
    'listing_type': 'sale',
    'imageUrl':
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&q=80',
    'description':
        'Welcome home to 7761 Sagemeadow Ct! Beautifully maintained single family home in a peaceful cul-de-sac location in Columbus. Features a spacious open concept layout with high ceilings, updated kitchen with granite countertops, cozy fireplace, large private backyard with mature trees, and an attached two-car garage. Conveniently located near top-rated schools, parks, shopping, and dining.',
    'facts': {
      'Zestimate': '\$338,600',
      'Type': 'Single family',
      'PriceSqft': '\$220/sqft',
      'Built': '1983',
      'HOA': '\$50/mo',
      'Lot': '0.3-acre lot',
    },
    'openHouses': [
      {'date': 'Tue, Aug 18', 'time': '9am-7pm'},
      {'date': 'Wed, Aug 19', 'time': '9am-7pm'},
    ],
    'offerInsights': {
      'listPrice': '\$342K',
      'targetPrice': '\$351K+',
      'winChance': 'Over 90% chance of a winning offer',
      'marketState': 'Sellers market',
    },
    'monthlyEst': 2477,
    'principalAndInterest': 1753,
    'taxes': 610,
    'otherCosts': 114,
  };

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => LocaleProvider()),
        provider.ChangeNotifierProvider(
          create: (_) => CountryContextProvider(),
        ),
      ],
      child: provider.Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return Sizer(
            builder: (context, orientation, screenType) {
              return Directionality(
                textDirection: localeProvider.textDirection,
                child: MaterialApp(
                  title: 'Zillow Property Detail',
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
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.0),
                      ),
                      child: child!,
                    );
                  },
                  debugShowCheckedModeBanner: false,
                  home: const ZillowPropertyDetailScreen(
                    propertyData: mockProperty,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
