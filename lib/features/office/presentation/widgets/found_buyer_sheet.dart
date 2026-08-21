import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../presentation/search_map_screen/models/property_data.dart';

/// Stitch-style “Found a Buyer” capture sheet (Arabic-first).
class FoundBuyerSheet extends StatefulWidget {
  const FoundBuyerSheet({
    super.key,
    required this.property,
    required this.onSubmit,
  });

  final PropertyData property;
  final Future<void> Function(String phoneOrId) onSubmit;

  static Future<void> show(
    BuildContext context, {
    required PropertyData property,
    required Future<void> Function(String phoneOrId) onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FoundBuyerSheet(
        property: property,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<FoundBuyerSheet> createState() => _FoundBuyerSheetState();
}

class _FoundBuyerSheetState extends State<FoundBuyerSheet> {
  final _phone = TextEditingController();
  final _buyerId = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _buyerId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _phone.text.trim().isNotEmpty
        ? _phone.text.trim()
        : _buyerId.text.trim();
    if (value.isEmpty) return;
    setState(() => _busy = true);
    await widget.onSubmit(value);
    if (mounted) {
      setState(() => _busy = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final p = widget.property;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: p.imageUrl.isEmpty
                            ? ColoredBox(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.home_work_outlined),
                              )
                            : Image.network(p.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID: ${p.id}',
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            p.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            p.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      p.formattedPrice,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.officeFoundBuyerTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.officeFoundBuyerHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: loc.officeFoundBuyerPhone,
                  hintText: '7X XXX XXXX',
                  prefixText: '+964 ',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(loc.orLabel),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _buyerId,
                decoration: InputDecoration(
                  labelText: loc.officeFoundBuyerId,
                  hintText: 'BYR-8821',
                  suffixIcon: const Icon(Icons.badge_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.officeFoundBuyerInfo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: const Color(0xFF0B1C30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: const Icon(Icons.send),
                label: Text(loc.officeFoundBuyerSubmit),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: const Color(0xFF0041C8),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: const Color(0xFF0041C8),
                ),
                child: Text(loc.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
