import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_bounds.dart';
class MarkerClusterEngine {
  MarkerClusterEngine({
    this.clusterZoomThreshold = 14.0,
    this.minClusterSize = 2,
  });

  final double clusterZoomThreshold;
  final int minClusterSize;

  List<ClusterItem> cluster({
    required List<ClusterPoint> points,
    required double zoom,
    required MapBounds bounds,
  }) {
    if (zoom >= clusterZoomThreshold || points.length <= minClusterSize) {
      return points
          .map((p) => ClusterItem.single(p))
          .where((c) => bounds.contains(c.position))
          .toList();
    }

    final cell = _cellSizeForZoom(zoom);
    final buckets = <String, List<ClusterPoint>>{};

    for (final p in points) {
      if (!bounds.contains(p.position)) continue;
      final key = '${(p.position.latitude / cell).floor()}_'
          '${(p.position.longitude / cell).floor()}';
      buckets.putIfAbsent(key, () => []).add(p);
    }

    final out = <ClusterItem>[];
    for (final group in buckets.values) {
      if (group.length < minClusterSize) {
        out.addAll(group.map(ClusterItem.single));
        continue;
      }
      var lat = 0.0;
      var lng = 0.0;
      for (final p in group) {
        lat += p.position.latitude;
        lng += p.position.longitude;
      }
      lat /= group.length;
      lng /= group.length;
      out.add(
        ClusterItem(
          position: LatLng(lat, lng),
          count: group.length,
          members: group,
        ),
      );
    }
    return out;
  }

  double _cellSizeForZoom(double zoom) {
    if (zoom < 10) return 0.08;
    if (zoom < 12) return 0.04;
    if (zoom < 13) return 0.02;
    return 0.012;
  }
}

class ClusterPoint {
  const ClusterPoint({required this.id, required this.position});
  final String id;
  final LatLng position;
}

class ClusterItem {
  const ClusterItem({
    required this.position,
    required this.count,
    this.members = const [],
  });

  factory ClusterItem.single(ClusterPoint p) =>
      ClusterItem(position: p.position, count: 1, members: [p]);

  final LatLng position;
  final int count;
  final List<ClusterPoint> members;

  bool get isCluster => count > 1;
}
