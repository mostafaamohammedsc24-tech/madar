import 'package:flutter/material.dart';

import '../../../../routes/app_routes.dart';
import '../../domain/models/deal_transaction.dart';

/// Opens the deal detail on a root GoRouter page (not nested in the shell).
void openTransactionDetail(
  BuildContext context, {
  required String transactionId,
  DealTransaction? initial,
}) {
  appRouter.push(
    AppRoutes.transactionDetail,
    extra: <String, dynamic>{
      'id': transactionId,
      if (initial != null) 'transaction': initial,
    },
  );
}
