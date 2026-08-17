import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapBounds {
  const MapBounds({
    required this.southwest,
    required this.northeast,
  });

  final LatLng southwest;
  final LatLng northeast;

  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
        point.latitude <= northeast.latitude &&
        point.longitude >= southwest.longitude &&
        point.longitude <= northeast.longitude;
  }

  bool containsProperty(double lat, double lng) =>
      contains(LatLng(lat, lng));

  String cacheKey({String? filter, int? zoomBucket}) {
    final z = zoomBucket ?? 0;
    return '${southwest.latitude.toStringAsFixed(3)}_'
        '${southwest.longitude.toStringAsFixed(3)}_'
        '${northeast.latitude.toStringAsFixed(3)}_'
        '${northeast.longitude.toStringAsFixed(3)}_'
        '${filter ?? 'all'}_$z';
  }

  static MapBounds? fromLatLngBounds(LatLngBounds? bounds) {
    if (bounds == null) return null;
    return MapBounds(
      southwest: bounds.southwest,
      northeast: bounds.northeast,
    );
  }

  /// Expand bounds slightly so edge pins appear before panning again.
  MapBounds padded([double factor = 0.08]) {
    final latSpan = northeast.latitude - southwest.latitude;
    final lngSpan = northeast.longitude - southwest.longitude;
    return MapBounds(
      southwest: LatLng(
        southwest.latitude - latSpan * factor,
        southwest.longitude - lngSpan * factor,
      ),
      northeast: LatLng(
        northeast.latitude + latSpan * factor,
        northeast.longitude + lngSpan * factor,
      ),
    );
  }
}

int zoomBucket(double zoom) => zoom.floor();
