import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;

import 'package:madar/core/localization/app_localizations.dart';
import 'package:madar/core/localization/locale_provider.dart';
import 'package:madar/features/transaction/domain/models/deal_transaction.dart';
import 'package:madar/features/transaction/presentation/screens/transaction_detail_screen.dart';
import 'package:madar/services/app_demo_seed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TransactionDetailScreen opens from demo seed', (tester) async {
    final map = AppDemoSeed.userTransactions().first;
    final tx = DealTransaction.fromMap(map);

    FlutterError.onError = (details) {
      // ignore: avoid_print
      print('FLUTTER_ERROR: ${details.exceptionAsString()}');
      FlutterError.presentError(details);
    };

    await tester.pumpWidget(
      provider.ChangeNotifierProvider(
        create: (_) => LocaleProvider(),
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizationsDelegate(AppLanguage.arabic),
          ],
          home: TransactionDetailScreen(
            transactionId: tx.id,
            initial: tx,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TransactionDetailScreen), findsOneWidget);
    expect(find.text(tx.transactionNumber), findsWidgets);
  });
}
