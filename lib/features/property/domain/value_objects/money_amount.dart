import '../enums/data_provenance.dart';

class MoneyAmount {
  const MoneyAmount({
    required this.amount,
    required this.currencyCode,
    this.provenance = DataProvenance.publisherProvided,
  });

  final double amount;
  final String currencyCode;
  final DataProvenance provenance;

  bool get hasValue => amount > 0;

  String format({bool compact = false}) {
    final code = currencyCode.toUpperCase();
    if (compact) {
      if (amount >= 1000000) {
        return '$code ${(amount / 1000000).toStringAsFixed(1)}M';
      }
      if (amount >= 1000) {
        return '$code ${(amount / 1000).toStringAsFixed(0)}K';
      }
    }
    final whole = amount.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$code $whole';
  }

  static MoneyAmount? maybe(
    num? value,
    String? currency, {
    DataProvenance? provenance,
  }) {
    if (value == null) return null;
    final d = value.toDouble();
    if (d <= 0) return null;
    return MoneyAmount(
      amount: d,
      currencyCode: currency ?? 'USD',
      provenance: provenance ?? DataProvenance.publisherProvided,
    );
  }
}
