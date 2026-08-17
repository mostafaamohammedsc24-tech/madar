import 'dart:ui' as ui;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/app_export.dart';
import '../search_map_screen.dart';

// Full-screen GoogleMap with custom property type icons, polygon draw support.
// On web without Maps JS, falls back to a local map canvas so the user shell stays usable.
class PropertyMapWidget extends StatefulWidget {
  final List<PropertyData> properties;
  final Function(PropertyData) onPropertyTap;
  final String mapType;
  final bool isDrawingMode;
  final Function(List<LatLng>)? onPolygonDrawn;
  final String? selectedPropertyId;
  final ValueChanged<double>? onZoomChanged;
  final VoidCallback? onBackgroundTap;

  const PropertyMapWidget({
    required this.properties,
    required this.onPropertyTap,
    required this.mapType,
    this.isDrawingMode = false,
    this.onPolygonDrawn,
    this.selectedPropertyId,
    this.onZoomChanged,
    this.onBackgroundTap,
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
  double _currentZoom = 12.5;
  DateTime? _lastPinSelectAt;
  static const bool _useWebMapFallback = false;

  static const String _cleanMapStyle = '''
[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.attraction","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"transit.station","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]}
]
''';

  // Cache for custom marker bitmaps — keyed by type_listingType_size
  final Map<String, BitmapDescriptor> _markerCache = {};

  static const CameraPosition _baghdadCenter = CameraPosition(
    target: LatLng(33.3152, 44.3932),
    zoom: 12.5,
  );

  @override
  void initState() {
    super.initState();
    if (!_useWebMapFallback) {
      _buildMarkers();
    }
  }

  @override
  void didUpdateWidget(PropertyMapWidget old) {
    super.didUpdateWidget(old);
    if (_useWebMapFallback) return;
    if (old.properties != widget.properties ||
        old.selectedPropertyId != widget.selectedPropertyId) {
      _buildMarkers();
    }
    if (!widget.isDrawingMode && old.isDrawingMode) {
      _clearDrawing();
    }
  }

  /// Compute marker pixel size based on zoom level — large circular pins.
  double _markerSizeForZoom(double zoom) {
    final size = 64.0 + (zoom - 8.0) * 6.0;
    return size.clamp(68.0, 118.0);
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
    double markerSize, {
    bool selected = false,
  }) async {
    final cacheKey =
        '${type}_${listingType}_${markerSize.toInt()}_${selected ? 's' : 'n'}';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final spec = _getIconSpec(type, listingType);
    final color = spec['color'] as Color;
    final iconData = spec['icon'] as IconData;
    final size = selected ? markerSize * 1.18 : markerSize;

    final canvasSize = size * 2.0;
    final circleRadius = size * 0.42;
    final center = Offset(canvasSize / 2, canvasSize / 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(0, 2), circleRadius + 1, shadowPaint);

    canvas.drawCircle(center, circleRadius + (selected ? 4 : 0), Paint()..color = Colors.white);
    canvas.drawCircle(center, circleRadius, Paint()..color = color);

    final iconFontSize = circleRadius * 0.95;
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

    final picture = recorder.endRecording();
    final imgSize = canvasSize.toInt();
    final image = await picture.toImage(imgSize, imgSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.bytes(
      bytes,
      width: size,
      height: size,
    );
    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  Future<void> _buildMarkers() async {
    final size = _markerSizeForZoom(_currentZoom);
    final markerFutures = widget.properties.map((p) async {
      final selected = p.id == widget.selectedPropertyId;
      final icon = await _createCustomMarker(
        p.type,
        p.listingType,
        size,
        selected: selected,
      );
      return Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.lat, p.lng),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: selected ? 10 : 1,
        consumeTapEvents: true,
        onTap: () => _emitPinTap(p),
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
    if (widget.isDrawingMode) {
      setState(() {
        _drawingPoints.add(position);
        _updateDrawingOverlays();
      });
      return;
    }
    _selectNearestPin(position);
  }

  Future<void> _selectNearestPin(LatLng position) async {
    final controller = _mapController;
    if (controller == null || widget.properties.isEmpty) {
      widget.onBackgroundTap?.call();
      return;
    }

    try {
      final tap = await controller.getScreenCoordinate(position);
      PropertyData? nearest;
      var best = 70.0 * 70.0;
      for (final property in widget.properties) {
        final coord = await controller.getScreenCoordinate(
          LatLng(property.lat, property.lng),
        );
        final dx = (coord.x - tap.x).toDouble();
        final dy = (coord.y - tap.y).toDouble();
        final dist = dx * dx + dy * dy;
        if (dist < best) {
          best = dist;
          nearest = property;
        }
      }
      if (nearest != null) {
        _emitPinTap(nearest);
        return;
      }
    } catch (_) {}
    if (_lastPinSelectAt != null &&
        DateTime.now().difference(_lastPinSelectAt!) <
            const Duration(milliseconds: 400)) {
      return;
    }
    widget.onBackgroundTap?.call();
  }

  void _emitPinTap(PropertyData property) {
    _lastPinSelectAt = DateTime.now();
    widget.onPropertyTap(property);
  }

  void _onCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;
  }

  void _onCameraIdle() {
    widget.onZoomChanged?.call(_currentZoom);
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

  /// Place the pin in the upper third so the preview card does not cover it.
  void focusOnPin(LatLng location) {
    final shifted = LatLng(location.latitude - 0.0045, location.longitude);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: shifted, zoom: _currentZoom.clamp(13.5, 16.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_useWebMapFallback) {
      return _WebMapFallback(
        properties: widget.properties,
        onPropertyTap: widget.onPropertyTap,
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _baghdadCenter,
          mapType: _getMapType(),
          style: _cleanMapStyle,
          markers: _markers,
          polygons: _polygons,
          polylines: _polylines,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          buildingsEnabled: false,
          indoorViewEnabled: false,
          trafficEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            _buildMarkers();
          },
          onTap: _onMapTap,
          onCameraMove: _onCameraMove,
          onCameraIdle: _onCameraIdle,
        ),
      ],
    );
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
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _CircularPropertyPin extends StatelessWidget {
  const _CircularPropertyPin({
    required this.property,
    required this.selected,
    required this.diameter,
    required this.onTap,
  });

  final PropertyData property;
  final bool selected;
  final double diameter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spec = _pinSpec(property);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: spec.color,
          border: Border.all(color: Colors.white, width: selected ? 5 : 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.28 : 0.18),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(spec.icon, color: Colors.white, size: diameter * 0.46),
      ),
    );
  }
}

({IconData icon, Color color}) _pinSpec(PropertyData property) {
  switch (property.type.toLowerCase()) {
    case 'villa':
      return (
        icon: Icons.villa,
        color: property.listingType == 'mortgage'
            ? const Color(0xFFE91E63)
            : const Color(0xFF388E3C),
      );
    case 'land':
      return (icon: Icons.landscape, color: const Color(0xFFF57C00));
    case 'commercial':
      return (icon: Icons.store, color: const Color(0xFF7B1FA2));
    case 'building':
      return (icon: Icons.domain, color: const Color(0xFFFFB300));
    case 'apartment':
      return (
        icon: Icons.apartment,
        color: property.listingType == 'rent'
            ? const Color(0xFF00BCD4)
            : const Color(0xFF1565C0),
      );
    default:
      return (
        icon: Icons.home,
        color: property.listingType == 'rent'
            ? const Color(0xFF00BCD4)
            : const Color(0xFF1565C0),
      );
  }
}

/// Lightweight map stand-in for Flutter web when Google Maps JS is unavailable.
class _WebMapFallback extends StatelessWidget {
  const _WebMapFallback({
    required this.properties,
    required this.onPropertyTap,
  });

  final List<PropertyData> properties;
  final Function(PropertyData) onPropertyTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pins = properties.take(24).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final pinAreaWidth = (width - 80).clamp(120.0, 900.0);
        final pinAreaHeight = (height - 220).clamp(120.0, 900.0);

        return Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFD7E4EC),
                Color(0xFFE8F0E9),
                Color(0xFFD9E2D4),
                Color(0xFFC5D4C8),
              ],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _WebMapGridPainter()),
              ),
              Positioned(
                top: 120,
                left: 24,
                right: 24,
                child: Text(
                  'Baghdad · map preview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF3A4A42),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              ...List.generate(pins.length, (index) {
                final property = pins[index];
                final left =
                    28.0 + ((index * 67) % pinAreaWidth.toInt()).toDouble();
                final top =
                    170.0 + ((index * 53) % pinAreaHeight.toInt()).toDouble();
                return Positioned(
                  left: left.clamp(8.0, width - 8.0),
                  top: top.clamp(8.0, height - 8.0),
                  child: _CircularPropertyPin(
                    property: property,
                    selected: false,
                    diameter: 64,
                    onTap: () => onPropertyTap(property),
                  ),
                );
              }),
              if (pins.isEmpty)
                Center(
                  child: Text(
                    'No listings in this area yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF4A5B52),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WebMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8AA396).withValues(alpha: 0.18)
      ..strokeWidth = 1;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final river = Paint()
      ..color = const Color(0xFF7BA7C2).withValues(alpha: 0.35)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.15, 0)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.35,
        size.width * 0.55,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.8,
        size.width * 0.85,
        size.height,
      );
    canvas.drawPath(path, river);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
