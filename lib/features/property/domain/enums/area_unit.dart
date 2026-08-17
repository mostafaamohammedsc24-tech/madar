/// Primary area unit is square meters. Large land can convert to dunum/hectare.
enum AreaUnit {
  squareMeter,
  dunum,
  hectare;

  /// 1 dunum ≈ 2500 m² (common MENA convention; configurable later).
  static const double metersPerDunum = 2500;

  /// 1 hectare = 10_000 m²
  static const double metersPerHectare = 10000;

  double toSquareMeters(double value) {
    switch (this) {
      case AreaUnit.squareMeter:
        return value;
      case AreaUnit.dunum:
        return value * metersPerDunum;
      case AreaUnit.hectare:
        return value * metersPerHectare;
    }
  }

  double fromSquareMeters(double sqm) {
    switch (this) {
      case AreaUnit.squareMeter:
        return sqm;
      case AreaUnit.dunum:
        return sqm / metersPerDunum;
      case AreaUnit.hectare:
        return sqm / metersPerHectare;
    }
  }

  String get symbol {
    switch (this) {
      case AreaUnit.squareMeter:
        return 'm²';
      case AreaUnit.dunum:
        return 'dunum';
      case AreaUnit.hectare:
        return 'ha';
    }
  }
}
