import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;

import 'package:madar/core/localization/app_localizations.dart';
import 'package:madar/core/localization/locale_provider.dart';
import 'package:madar/features/property/presentation/screens/property_report_screen.dart';
import 'package:madar/providers/country_context_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PropertyReportScreen builds from property map', (tester) async {
    const title = 'Test Residence Karrada';
    final seed = <String, dynamic>{
      'id': 'test-property-001',
      'title': title,
      'asking_price': 250000,
      'currency': 'USD',
      'total_area_sqm': 180,
      'bedrooms_count': 3,
      'bathrooms_count': 2,
      'property_type': 'apartment',
      'listing_type': 'sale',
      'latitude': 33.3,
      'longitude': 44.4,
      'address_text': 'Karrada, Baghdad',
      'district': 'Karrada',
      'country_code': 'IQ',
      'is_verified': false,
      'is_featured': false,
      'property_media_v3': const <Map<String, dynamic>>[],
      'property_features_v3': const <Map<String, dynamic>>[],
    };

    FlutterError.onError = (details) {
      // ignore: avoid_print
      print('FLUTTER_ERROR: ${details.exceptionAsString()}');
      // ignore: avoid_print
      print(details.stack);
      FlutterError.presentError(details);
    };

    await tester.pumpWidget(
      ProviderScope(
        child: provider.MultiProvider(
          providers: [
            provider.ChangeNotifierProvider(create: (_) => LocaleProvider()),
            provider.ChangeNotifierProvider(
              create: (_) => CountryContextProvider(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizationsDelegate(AppLanguage.arabic),
            ],
            home: PropertyReportScreen(property: seed),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(PropertyReportScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Test'), findsWidgets);
  });
}
