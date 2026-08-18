import 'package:flutter/material.dart';

/// Zillow-style sheet handle: a short horizontal pill, never a chevron.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
      child: Center(
        child: SizedBox(
          width: 36,
          height: 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFBDBDBD),
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
        ),
      ),
    );
  }
}
