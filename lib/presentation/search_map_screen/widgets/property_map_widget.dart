import 'dart:ui' as ui;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/app_export.dart';
import '../search_map_screen.dart';

// Full-screen GoogleMap with custom property type icons, polygon draw support
class PropertyMapWidget extends StatefulWidget {
  final List<PropertyData> properties;
  final Function(PropertyData) onPropertyTap;
  final String mapType;
  final bool isDrawingMode;
  final Function(List<LatLng>)? onPolygonDrawn;

  const PropertyMapWidget({
    required this.properties,
    required this.onPropertyTap,
    required this.mapType,
    this.isDrawingMode = false,
    this.onPolygonDrawn,
    super.key,
  });

  @override
  State<PropertyMapWidget> createState() => PropertyMapWidgetState();
}

class PropertyMapWidgetState extends State<PropertyMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Polyline> _polylines = {};
  final List<LatLng> _drawingPoints = [];
  bool _isDrawing = false;
  double _currentZoom = 12.5;

  // Cache for custom marker bitmaps — keyed by type_listingType_size
  final Map<String, BitmapDescriptor> _markerCache = {};

  static const CameraPosition _baghdadCenter = CameraPosition(
    target: LatLng(33.3152, 44.3932),
    zoom: 12.5,
  );

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(PropertyMapWidget old) {
    super.didUpdateWidget(old);
    if (old.properties != widget.properties) {
      _buildMarkers();
    }
    if (!widget.isDrawingMode && old.isDrawingMode) {
      _clearDrawing();
    }
  }

  /// Compute marker pixel size based on zoom level
  double _markerSizeForZoom(double zoom) {
    // At zoom 10 → 28px, zoom 14 → 44px, zoom 18 → 64px
    // Linear interpolation clamped between 20 and 72
    final size = 20.0 + (zoom - 8.0) * 4.0;
    return size.clamp(20.0, 72.0);
  }

  // Returns the icon name and color for each property type/listing type
  Map<String, dynamic> _getIconSpec(String type, String listingType) {
    switch (type) {
      case 'apartment':
        return {
          'icon': Icons.apartment,
          'color': listingType == 'rent'
              ? const Color(0xFF00BCD4)
              : const Color(0xFF1565C0),
          'label': listingType == 'rent' ? 'Rent' : 'Apt',
        };
      case 'villa':
        return {
          'icon': Icons.villa,
          'color': listingType == 'mortgage'
              ? const Color(0xFFE91E63)
              : const Color(0xFF388E3C),
          'label': listingType == 'mortgage' ? 'Mortgage' : 'Villa',
        };
      case 'land':
        return {
          'icon': Icons.landscape,
          'color': const Color(0xFFF57C00),
          'label': 'Land',
        };
      case 'commercial':
        return {
          'icon': Icons.store,
          'color': const Color(0xFF7B1FA2),
          'label': 'Shop',
        };
      case 'building':
        return {
          'icon': Icons.domain,
          'color': const Color(0xFFFFB300),
          'label': 'Bldg',
        };
      case 'investment':
        return {
          'icon': Icons.trending_up,
          'color': const Color(0xFFE91E63),
          'label': 'Invest',
        };
      default:
        if (listingType == 'mortgage') {
          return {
            'icon': Icons.account_balance,
            'color': const Color(0xFFE91E63),
            'label': 'Mortgage',
          };
        }
        return {
          'icon': Icons.home,
          'color': const Color(0xFF1565C0),
          'label': 'Sale',
        };
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(
    String type,
    String listingType,
    double markerSize,
  ) async {
    final cacheKey = '${type}_${listingType}_${markerSize.toInt()}';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final spec = _getIconSpec(type, listingType);
    final color = spec['color'] as Color;
    final iconData = spec['icon'] as IconData;

    // Canvas size is 2x the marker size for crisp rendering
    final canvasSize = markerSize * 2.0;
    final circleRadius = markerSize * 0.55;
    final center = Offset(canvasSize / 2, canvasSize / 2 - markerSize * 0.1);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(70)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, markerSize * 0.12);
    canvas.drawCircle(
      Offset(center.dx, center.dy + markerSize * 0.05),
      circleRadius,
      shadowPaint,
    );

    // Circle background
    final bgPaint = Paint()..color = color;
    canvas.drawCircle(center, circleRadius, bgPaint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = markerSize * 0.08;
    canvas.drawCircle(center, circleRadius, borderPaint);

    // Draw icon
    final iconFontSize = circleRadius * 1.0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconFontSize,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Pin triangle at bottom
    final pinPaint = Paint()..color = color;
    final pinWidth = circleRadius * 0.4;
    final pinHeight = circleRadius * 0.6;
    final pinTop = center.dy + circleRadius - 2;
    final path = Path()
      ..moveTo(center.dx - pinWidth, pinTop)
      ..lineTo(center.dx + pinWidth, pinTop)
      ..lineTo(center.dx, pinTop + pinHeight)
      ..close();
    canvas.drawPath(path, pinPaint);

    final picture = recorder.endRecording();
    final imgSize = canvasSize.toInt();
    final image = await picture.toImage(imgSize, imgSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    // Display size = markerSize (screen pixels)
    final descriptor = BitmapDescriptor.bytes(
      bytes,
      width: markerSize,
      height: markerSize + markerSize * 0.3,
    );
    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  Future<void> _buildMarkers() async {
    final size = _markerSizeForZoom(_currentZoom);
    final markerFutures = widget.properties.map((p) async {
      final icon = await _createCustomMarker(p.type, p.listingType, size);
      return Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.lat, p.lng),
        icon: icon,
        infoWindow: InfoWindow(title: p.title, snippet: p.formattedPrice),
        onTap: () => widget.onPropertyTap(p),
      );
    });

    final markers = await Future.wait(markerFutures);
    if (mounted) setState(() => _markers = markers.toSet());
  }

  MapType _getMapType() {
    switch (widget.mapType) {
      case 'satellite':
        return MapType.satellite;
      case 'terrain':
        return MapType.terrain;
      case 'hybrid':
        return MapType.hybrid;
      default:
        return MapType.normal;
    }
  }

  void _onMapTap(LatLng position) {
    if (!widget.isDrawingMode) return;
    setState(() {
      _drawingPoints.add(position);
      _isDrawing = true;
      _updateDrawingOverlays();
    });
  }

  void _updateDrawingOverlays() {
    if (_drawingPoints.isEmpty) return;

    _polylines = {
      Polyline(
        polylineId: const PolylineId('drawing'),
        points: _drawingPoints,
        color: AppTheme.primary,
        width: 3,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };

    if (_drawingPoints.length >= 3) {
      _polygons = {
        Polygon(
          polygonId: const PolygonId('selection'),
          points: _drawingPoints,
          fillColor: AppTheme.primary.withAlpha(40),
          strokeColor: AppTheme.primary,
          strokeWidth: 2,
        ),
      };
    }
  }

  void _clearDrawing() {
    setState(() {
      _drawingPoints.clear();
      _polygons = {};
      _polylines = {};
      _isDrawing = false;
    });
  }

  void _onCameraMove(CameraPosition position) {
    // Track zoom but don't rebuild on every frame
    _currentZoom = position.zoom;
  }

  void _onCameraIdle() {
    // Rebuild markers when camera stops moving (zoom changed)
    _buildMarkers();
  }

  void completeDrawing() {
    if (_drawingPoints.length >= 3) {
      widget.onPolygonDrawn?.call(_drawingPoints);
    }
    _clearDrawing();
  }

  void moveToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: _baghdadCenter,
      mapType: _getMapType(),
      markers: _markers,
      polygons: _polygons,
      polylines: _polylines,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        _buildMarkers();
      },
      onTap: _onMapTap,
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
