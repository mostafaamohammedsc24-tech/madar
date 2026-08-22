import 'package:flutter/material.dart';

import '../../../legal/presentation/theme/legal_theme.dart';
import '../../domain/enums/mapping_enums.dart';
import '../../domain/models/mapping_models.dart';

const double kMetersToPx = 28;

class FloorPlanCanvas extends StatelessWidget {
  const FloorPlanCanvas({
    super.key,
    required this.floor,
    required this.selectedRoomId,
    required this.showGrid,
    required this.dark,
    required this.onSelectRoom,
    required this.onAddRoom,
    required this.tool,
  });

  final MappingFloor? floor;
  final String? selectedRoomId;
  final bool showGrid;
  final bool dark;
  final ValueChanged<String?> onSelectRoom;
  final void Function(Offset meters) onAddRoom;
  final String tool;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: dark ? const Color(0xFF121A28) : const Color(0xFFF4F6F8),
        child: InteractiveViewer(
          minScale: 0.4,
          maxScale: 4,
          boundaryMargin: const EdgeInsets.all(400),
          child: GestureDetector(
            onTapUp: (d) {
              final m = Offset(d.localPosition.dx / kMetersToPx, d.localPosition.dy / kMetersToPx);
              if (tool == 'room') {
                onAddRoom(m);
                return;
              }
              final hit = _hit(m);
              onSelectRoom(hit);
            },
            child: CustomPaint(
              size: const Size(720, 520),
              painter: _PlanPainter(
                floor: floor,
                selectedRoomId: selectedRoomId,
                showGrid: showGrid,
                dark: dark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _hit(Offset m) {
    final f = floor;
    if (f == null) return null;
    for (final r in f.rooms.reversed) {
      if (r.hidden || r.polygon.length < 3) continue;
      if (_inside(m, r.polygon)) return r.id;
    }
    return null;
  }

  bool _inside(Offset m, List<MappingPoint> poly) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final pi = poly[i];
      final pj = poly[j];
      final intersect = ((pi.y > m.dy) != (pj.y > m.dy)) &&
          (m.dx < (pj.x - pi.x) * (m.dy - pi.y) / ((pj.y - pi.y) == 0 ? 1 : (pj.y - pi.y)) + pi.x);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}

class _PlanPainter extends CustomPainter {
  _PlanPainter({
    required this.floor,
    required this.selectedRoomId,
    required this.showGrid,
    required this.dark,
  });

  final MappingFloor? floor;
  final String? selectedRoomId;
  final bool showGrid;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final grid = Paint()
        ..color = (dark ? Colors.white : LegalTheme.charcoal).withValues(alpha: 0.06)
        ..strokeWidth = 1;
      const step = kMetersToPx * 0.5;
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }

    final f = floor;
    if (f == null) return;

    for (final r in f.rooms) {
      if (r.hidden || r.polygon.length < 3) continue;
      final path = Path()
        ..addPolygon(
          r.polygon.map((p) => Offset(p.x * kMetersToPx, p.y * kMetersToPx)).toList(),
          true,
        );
      final selected = r.id == selectedRoomId;
      canvas.drawPath(
        path,
        Paint()
          ..color = selected
              ? LegalTheme.primary.withValues(alpha: 0.22)
              : _fill(r.kind).withValues(alpha: dark ? 0.28 : 0.18),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.4 : 1.2
          ..color = selected ? LegalTheme.primary : _stroke(r.kind),
      );
      final c = _centroid(r.polygon);
      final tp = TextPainter(
        text: TextSpan(
          text: '${r.names.ar}\n${r.calculatedAreaM2.toStringAsFixed(0)} م²',
          style: TextStyle(
            color: dark ? LegalTheme.darkText : LegalTheme.charcoal,
            fontSize: 10,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 90);
      tp.paint(canvas, Offset(c.dx * kMetersToPx - tp.width / 2, c.dy * kMetersToPx - tp.height / 2));
    }

    for (final w in f.walls) {
      final paint = Paint()
        ..strokeWidth = (w.thicknessM * kMetersToPx).clamp(2, 8)
        ..strokeCap = StrokeCap.square
        ..color = switch (w.kind) {
          WallKind.exterior => dark ? const Color(0xFFD7DCE4) : const Color(0xFF1A2333),
          WallKind.structural => const Color(0xFF3D4A63),
          WallKind.interior => const Color(0xFF6B7384),
          WallKind.partition => const Color(0xFF9AA3B2),
        };
      canvas.drawLine(
        Offset(w.start.x * kMetersToPx, w.start.y * kMetersToPx),
        Offset(w.end.x * kMetersToPx, w.end.y * kMetersToPx),
        paint,
      );
    }

    for (final d in f.doors) {
      canvas.drawCircle(
        Offset(d.at.x * kMetersToPx, d.at.y * kMetersToPx),
        5,
        Paint()..color = const Color(0xFF2E7D32),
      );
    }
    for (final w in f.windows) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(w.at.x * kMetersToPx, w.at.y * kMetersToPx), width: 10, height: 4),
        Paint()..color = const Color(0xFF1565C0),
      );
    }
    for (final s in f.stairs) {
      final o = Offset(s.at.x * kMetersToPx, s.at.y * kMetersToPx);
      canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 18, 28), Paint()..color = LegalTheme.muted.withValues(alpha: 0.45));
    }
    for (final pt in f.points) {
      canvas.drawCircle(
        Offset(pt.at.x * kMetersToPx, pt.at.y * kMetersToPx),
        6,
        Paint()..color = LegalTheme.primary,
      );
    }
  }

  Offset _centroid(List<MappingPoint> poly) {
    var x = 0.0, y = 0.0;
    for (final p in poly) {
      x += p.x;
      y += p.y;
    }
    return Offset(x / poly.length, y / poly.length);
  }

  Color _fill(RoomKind k) {
    switch (k) {
      case RoomKind.kitchen:
        return const Color(0xFF5C6BC0);
      case RoomKind.bathroom:
      case RoomKind.guestBathroom:
        return const Color(0xFF26A69A);
      case RoomKind.bedroom:
      case RoomKind.masterBedroom:
        return const Color(0xFF7E57C2);
      case RoomKind.living:
      case RoomKind.family:
        return const Color(0xFF003EC7);
      case RoomKind.garage:
        return const Color(0xFF78909C);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  Color _stroke(RoomKind k) => _fill(k).withValues(alpha: 0.9);

  @override
  bool shouldRepaint(covariant _PlanPainter old) {
    return old.floor != floor || old.selectedRoomId != selectedRoomId || old.showGrid != showGrid || old.dark != dark;
  }
}
