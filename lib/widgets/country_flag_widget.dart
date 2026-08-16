import 'package:circle_flags/circle_flags.dart';
import 'package:flutter/material.dart';

/// Renders a country flag using SVG assets (not emoji).
class CountryFlagWidget extends StatelessWidget {
  const CountryFlagWidget({
    super.key,
    required this.countryCode,
    this.size = 24,
  });

  final String countryCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.35,
      height: size,
      child: CircleFlag(
        countryCode.toLowerCase(),
        size: size,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size * 0.15),
        ),
      ),
    );
  }
}
