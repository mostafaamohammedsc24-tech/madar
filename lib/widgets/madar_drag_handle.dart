import 'package:flutter/material.dart';

/// Standard grey grabber used at the top of Madar bottom sheets.
class MadarDragHandle extends StatelessWidget {
  const MadarDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFD0D5DD),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
