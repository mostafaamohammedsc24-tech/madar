import 'package:flutter_test/flutter_test.dart';
import 'package:madar/features/workflow/data/deal_workflow_store.dart';
import 'package:madar/features/workflow/domain/deal_workflow_models.dart';
import 'package:madar/features/transaction/domain/enums/transaction_enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DealWorkflowStore', () {
    test('resolves seed buyer/seller and published barcodes', () {
      final store = DealWorkflowStore.instance;
      store.ensureSeeded();

      final buy = store.resolve('BUY-SEED-001');
      expect(buy, isNotNull);
      expect(buy!.kind, BarcodeKind.buyerDeal);
      expect(buy.transactionId, isNotNull);

      final pub = store.resolve('PUB-88421011');
      expect(pub, isNotNull);
      expect(pub!.kind, BarcodeKind.publishingAsset);
      expect(pub.publishingAssetId, isNotNull);
    });

    test('advance moves deal to next owner stage', () {
      final store = DealWorkflowStore.instance;
      store.ensureSeeded();
      final deals = store.boardDeals();
      expect(deals, isNotEmpty);
      final id = deals.firstWhere(
        (d) => d['lifecycle_state'] == 'waiting_for_parties',
        orElse: () => deals.first,
      )['id']!
          .toString();

      // Force known start.
      store.registerLiveDealBarcodes(
        transactionId: 'test-advance-tx',
        buyerBarcode: 'BUY-TEST-ADV',
        sellerBarcode: 'SEL-TEST-ADV',
        transactionMap: {
          'id': 'test-advance-tx',
          'property_address_snapshot': 'Test',
          'lifecycle_state': 'waiting_for_parties',
        },
      );
      final r = store.advance('test-advance-tx');
      expect(r.ok, isTrue);
      expect(r.next, TransactionState.partiesVerified);
      expect(r.owner, WorkflowRoleOwner.office);
      expect(id, isNotEmpty);
    });
  });
}
