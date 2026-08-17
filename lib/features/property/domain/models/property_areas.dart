import '../value_objects/area_measure.dart';

/// All area fields in m². Only non-null fields are shown in UI.
class PropertyAreas {
  const PropertyAreas({
    this.builtUp,
    this.land,
    this.floor,
    this.net,
    this.gross,
    this.garden,
    this.roof,
    this.pool,
    this.parking,
    this.storage,
    this.basement,
    this.annexes,
    this.shops,
    this.units,
    this.leasable,
    this.investable,
  });

  final AreaMeasure? builtUp;
  final AreaMeasure? land;
  final AreaMeasure? floor;
  final AreaMeasure? net;
  final AreaMeasure? gross;
  final AreaMeasure? garden;
  final AreaMeasure? roof;
  final AreaMeasure? pool;
  final AreaMeasure? parking;
  final AreaMeasure? storage;
  final AreaMeasure? basement;
  final AreaMeasure? annexes;
  final AreaMeasure? shops;
  final AreaMeasure? units;
  final AreaMeasure? leasable;
  final AreaMeasure? investable;

  /// Primary display area: prefer built-up / gross / land.
  AreaMeasure? get primary => builtUp ?? gross ?? net ?? land ?? floor;

  bool get hasAny => primary != null ||
      land != null ||
      garden != null ||
      roof != null ||
      pool != null ||
      parking != null ||
      storage != null ||
      basement != null ||
      annexes != null ||
      leasable != null;

  List<MapEntry<String, AreaMeasure>> get nonEmptyEntries {
    final map = <String, AreaMeasure?>{
      'builtUp': builtUp,
      'land': land,
      'floor': floor,
      'net': net,
      'gross': gross,
      'garden': garden,
      'roof': roof,
      'pool': pool,
      'parking': parking,
      'storage': storage,
      'basement': basement,
      'annexes': annexes,
      'shops': shops,
      'units': units,
      'leasable': leasable,
      'investable': investable,
    };
    return map.entries
        .where((e) => e.value != null)
        .map((e) => MapEntry(e.key, e.value!))
        .toList();
  }
}
