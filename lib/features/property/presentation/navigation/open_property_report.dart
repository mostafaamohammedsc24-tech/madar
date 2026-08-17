import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the full Property Intelligence Report for a listing map payload.
void openPropertyReport(
  BuildContext context, {
  required Map<String, dynamic> propertyMap,
  bool popSheetFirst = false,
}) {
  if (popSheetFirst && Navigator.canPop(context)) {
    Navigator.pop(context);
  }
  context.push('/property-detail', extra: propertyMap);
}
