import '../enums/data_provenance.dart';
import '../enums/property_status.dart';
import '../value_objects/money_amount.dart';

class PropertyPricing {
  const PropertyPricing({
    this.currentPrice,
    this.pricePerSqm,
    this.previousPrice,
    this.estimatedValue,
    this.estimatedRentalValue,
    this.potentialValue,
    this.changePercent,
    this.status = PropertyStatus.forSale,
  });

  final MoneyAmount? currentPrice;
  final MoneyAmount? pricePerSqm;
  final MoneyAmount? previousPrice;
  final MoneyAmount? estimatedValue;
  final MoneyAmount? estimatedRentalValue;
  final MoneyAmount? potentialValue;
  final double? changePercent;
  final PropertyStatus status;

  bool get hasPrice => currentPrice?.hasValue == true;

  bool get hasEstimates =>
      estimatedValue != null ||
      estimatedRentalValue != null ||
      potentialValue != null;

  List<MapEntry<String, MoneyAmount>> get verifiedAmounts {
    final out = <MapEntry<String, MoneyAmount>>[];
    void add(String key, MoneyAmount? m) {
      if (m != null &&
          m.provenance != DataProvenance.estimated &&
          m.provenance != DataProvenance.mockDemo) {
        out.add(MapEntry(key, m));
      }
    }

    add('current', currentPrice);
    add('previous', previousPrice);
    add('perSqm', pricePerSqm);
    return out;
  }

  List<MapEntry<String, MoneyAmount>> get estimatedAmounts {
    final out = <MapEntry<String, MoneyAmount>>[];
    void add(String key, MoneyAmount? m) {
      if (m != null &&
          (m.provenance == DataProvenance.estimated ||
              m.provenance == DataProvenance.mockDemo)) {
        out.add(MapEntry(key, m));
      }
    }

    add('estimated', estimatedValue);
    add('rental', estimatedRentalValue);
    add('potential', potentialValue);
    return out;
  }
}

class PriceHistoryEntry {
  const PriceHistoryEntry({
    required this.effectiveDate,
    required this.price,
    this.previousPrice,
    this.changePercent,
    this.reason,
    this.provenance = DataProvenance.publisherProvided,
  });

  final DateTime effectiveDate;
  final MoneyAmount price;
  final MoneyAmount? previousPrice;
  final double? changePercent;
  final String? reason;
  final DataProvenance provenance;
}

class TaxHistoryEntry {
  const TaxHistoryEntry({
    required this.taxYear,
    this.assessedValue,
    this.taxAmount,
    this.notes,
    this.provenance = DataProvenance.external,
  });

  final int taxYear;
  final MoneyAmount? assessedValue;
  final MoneyAmount? taxAmount;
  final String? notes;
  final DataProvenance provenance;
}

class SalesHistoryEntry {
  const SalesHistoryEntry({
    required this.soldAt,
    required this.salePrice,
    this.transactionType,
    this.sourceName,
    this.provenance = DataProvenance.external,
  });

  final DateTime soldAt;
  final MoneyAmount salePrice;
  final String? transactionType;
  final String? sourceName;
  final DataProvenance provenance;
}

class PropertyHistory {
  const PropertyHistory({
    this.priceHistory = const [],
    this.taxHistory = const [],
    this.salesHistory = const [],
  });

  final List<PriceHistoryEntry> priceHistory;
  final List<TaxHistoryEntry> taxHistory;
  final List<SalesHistoryEntry> salesHistory;

  bool get hasPriceHistory => priceHistory.isNotEmpty;
  bool get hasTaxHistory => taxHistory.isNotEmpty;
  bool get hasSalesHistory => salesHistory.isNotEmpty;
  bool get hasAny =>
      hasPriceHistory || hasTaxHistory || hasSalesHistory;
}
