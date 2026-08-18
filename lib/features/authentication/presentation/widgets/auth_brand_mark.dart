import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/localization/app_localizations.dart';

class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({
    super.key,
    this.fontSize = 40,
    this.showIcon = false,
    this.iconSize = 40,
  });

  final double fontSize;
  final bool showIcon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final name = Text(
      loc.authBrandName,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 1.1,
        shadows: const [
          Shadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
    );

    if (!showIcon) return name;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/images/madar_mark.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        const SizedBox(height: 10),
        name,
      ],
    );
  }
}
