import 'package:flutter/material.dart';

final Set<IconData> kDirectionalIcons = {
  Icons.arrow_back,
  Icons.arrow_back_ios,
  Icons.arrow_back_ios_new,
  Icons.arrow_forward,
  Icons.arrow_forward_ios,
  Icons.chevron_right,
  Icons.chevron_right_rounded,
  Icons.chevron_left,
  Icons.chevron_left_rounded,
};

/// Generic icon that mirrors under RTL when the glyph is direction-sensitive.
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
  });

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (!kDirectionalIcons.contains(icon)) {
      return Icon(icon, size: size, color: color);
    }
    return mirrorForDirection(
      context,
      Icon(icon, size: size, color: color),
    );
  }
}

/// Icons that should mirror under RTL (chevrons, arrows, back/forward).
const Set<String> kDirectionalIconPrefixes = {
  'arrow_',
  'chevron_',
};

bool isDirectionalIconName(String iconName) {
  return kDirectionalIconPrefixes.any(iconName.startsWith);
}

bool _isRtl(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl;

Widget mirrorForDirection(BuildContext context, Widget child) {
  if (!_isRtl(context)) return child;
  return Transform.flip(flipX: true, child: child);
}

/// Chevron indicating navigation forward (mirrors in RTL).
class DirectionalChevronIcon extends StatelessWidget {
  const DirectionalChevronIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return mirrorForDirection(
      context,
      Icon(
        Icons.chevron_right,
        size: size,
        color: color,
      ),
    );
  }
}

/// Small list-tile trailing arrow (mirrors in RTL).
class DirectionalListArrow extends StatelessWidget {
  const DirectionalListArrow({super.key, this.color, this.size = 14});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return mirrorForDirection(
      context,
      Icon(
        Icons.arrow_forward_ios,
        size: size,
        color: color ?? Colors.grey,
      ),
    );
  }
}

/// Standard back navigation icon (mirrors in RTL).
class DirectionalBackIcon extends StatelessWidget {
  const DirectionalBackIcon({
    super.key,
    this.color,
    this.size = 24,
  });

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return mirrorForDirection(
      context,
      Icon(
        Icons.arrow_back,
        color: color,
        size: size,
      ),
    );
  }
}

/// Forward arrow icon (mirrors in RTL).
class DirectionalForwardIcon extends StatelessWidget {
  const DirectionalForwardIcon({
    super.key,
    this.color,
    this.size = 14,
  });

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return mirrorForDirection(
      context,
      Icon(Icons.arrow_forward, size: size, color: color),
    );
  }
}
