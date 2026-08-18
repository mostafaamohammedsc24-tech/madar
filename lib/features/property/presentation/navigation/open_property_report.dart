import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../routes/app_routes.dart';

/// Opens the full Property Intelligence Report for a listing map payload.
void openPropertyReport(
  BuildContext context, {
  required Map<String, dynamic> propertyMap,
  bool popSheetFirst = false,
}) {
  void navigate() {
    try {
      appRouter.push(AppRoutes.propertyDetail, extra: Map<String, dynamic>.from(propertyMap));
    } catch (e, st) {
      debugPrint('openPropertyReport failed: $e\n$st');
    }
  }

  if (popSheetFirst && Navigator.canPop(context)) {
    Navigator.pop(context);
    // Sheet context is disposed after pop — wait two frames so the sheet
    // route fully settles before pushing the report (avoids web hang).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
    });
    return;
  }

  navigate();
}

/// Copy a shareable property link (used from preview sheets / cards).
Future<void> sharePropertyLink(
  BuildContext context, {
  required String propertyId,
  required String title,
  required String priceLine,
}) async {
  final loc = AppLocalizations.of(context);
  final text = '$title\n$priceLine\nmadar://property/$propertyId';
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(loc.linkCopied),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
