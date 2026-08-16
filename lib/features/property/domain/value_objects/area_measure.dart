import '../enums/area_unit.dart';
import '../enums/data_provenance.dart';

/// Area always stored in square meters; display can convert.
class AreaMeasure {
  const AreaMeasure({
    required this.squareMeters,
    this.provenance = DataProvenance.publisherProvided,
    this.label,
  });

  final double squareMeters;
  final DataProvenance provenance;
  final String? label;

  bool get hasValue => squareMeters > 0;

  String format({AreaUnit unit = AreaUnit.squareMeter, int decimals = 0}) {
    final v = unit.fromSquareMeters(squareMeters);
    final formatted = decimals == 0
        ? v.round().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          )
        : v.toStringAsFixed(decimals);
    return '$formatted ${unit.symbol}';
  }

  static AreaMeasure? maybe(num? value, {DataProvenance? provenance}) {
    if (value == null) return null;
    final d = value.toDouble();
    if (d <= 0) return null;
    return AreaMeasure(
      squareMeters: d,
      provenance: provenance ?? DataProvenance.publisherProvided,
    );
  }
}
