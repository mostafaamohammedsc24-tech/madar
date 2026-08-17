import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../widgets/madar_drag_handle.dart';
import '../../../authentication/presentation/theme/auth_theme.dart';

/// Lighter blue partner entry that sits outside the white login card.
class PartnerEntrySection extends StatelessWidget {
  const PartnerEntrySection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: () => _openChooser(context),
        style: FilledButton.styleFrom(
          backgroundColor: AuthColors.canvasSoft,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          loc.staffOfficeEntry,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  void _openChooser(BuildContext context) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MadarDragHandle(),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.apartment_outlined),
                title: Text(loc.officeLoginTitle),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/office-login');
                },
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(loc.empLoginTitle),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/employee-login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
