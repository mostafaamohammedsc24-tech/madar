import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/legal_strings.dart';
import '../../../theme/app_theme.dart';

/// Electronic signature pad: undo stroke, re-sign, confirm, then Done.
class ElectronicSignaturePad extends StatefulWidget {
  const ElectronicSignaturePad({
    super.key,
    this.onConfirmed,
    this.onDone,
  });

  final VoidCallback? onConfirmed;
  final VoidCallback? onDone;

  @override
  State<ElectronicSignaturePad> createState() => _ElectronicSignaturePadState();
}

class _ElectronicSignaturePadState extends State<ElectronicSignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  bool _drawing = false;
  bool _confirmed = false;
  bool _done = false;

  bool get _hasInk =>
      _strokes.any((s) => s.length > 2) || _current.length > 2;

  void _undo() {
    if (_confirmed || _done) return;
    setState(() {
      if (_current.isNotEmpty) {
        _current = [];
      } else if (_strokes.isNotEmpty) {
        _strokes.removeLast();
      }
    });
  }

  void _resign() {
    setState(() {
      _strokes.clear();
      _current = [];
      _confirmed = false;
      _done = false;
      _drawing = false;
    });
  }

  void _confirm() {
    if (!_hasInk) return;
    setState(() => _confirmed = true);
    widget.onConfirmed?.call();
  }

  void _finish() {
    if (!_confirmed) return;
    setState(() => _done = true);
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LegalStrings.of(AppLocalizations.of(context));
    final theme = Theme.of(context);

    if (_done) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.success.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.success.withAlpha(60)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified, color: AppTheme.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc.signatureDone,
                style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(onPressed: _resign, child: Text(loc.resign)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.draw, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.drawSignature,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (!_confirmed && _hasInk)
                  TextButton(onPressed: _undo, child: Text(loc.undoStroke)),
                if (_confirmed)
                  TextButton(onPressed: _resign, child: Text(loc.resign)),
              ],
            ),
          ),
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _drawing ? AppTheme.primary : theme.dividerColor,
                width: _drawing ? 2 : 1,
              ),
            ),
            child: AbsorbPointer(
              absorbing: _confirmed,
              child: GestureDetector(
                onPanStart: (d) {
                  setState(() {
                    _drawing = true;
                    _current = [d.localPosition];
                  });
                },
                onPanUpdate: (d) {
                  setState(() => _current.add(d.localPosition));
                },
                onPanEnd: (_) {
                  setState(() {
                    _drawing = false;
                    if (_current.length > 1) _strokes.add(List.of(_current));
                    _current = [];
                  });
                },
                child: CustomPaint(
                  painter: _StrokePainter(
                    strokes: [
                      ..._strokes,
                      if (_current.isNotEmpty) _current,
                    ],
                    color: AppTheme.primary,
                  ),
                  child: !_hasInk
                      ? Center(
                          child: Text(
                            loc.drawSignature,
                            style: TextStyle(color: Colors.grey.withAlpha(150), fontSize: 13),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _confirmed
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finish,
                      child: Text(loc.done),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasInk ? _confirm : null,
                      child: Text(loc.confirmSignature),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter({required this.strokes, required this.color});
  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
