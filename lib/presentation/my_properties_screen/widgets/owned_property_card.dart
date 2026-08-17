import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/currency/currency_registry.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/country_context_provider.dart';
import '../../../theme/app_theme.dart';
import '../models/owned_property.dart';
import 'property_status_chip.dart';

class OwnedPropertyCard extends StatelessWidget {
  const OwnedPropertyCard({super.key, required this.property});

  final OwnedProperty property;

  @override
  Widget build(BuildContext context) {
    if (property.kind == OwnedListingKind.managed) {
      return _ManagedPropertyCard(property: property);
    }
    return _TitledPropertyCard(property: property);
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _TitledPropertyCard extends StatelessWidget {
  const _TitledPropertyCard({required this.property});

  final OwnedProperty property;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currency = context.watch<CountryContextProvider>().activeCurrency;
    final value = CurrencyRegistry.convert(
      property.marketValueUsd,
      from: 'USD',
      to: currency,
    );

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PropertyPhoto(property: property),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.title(loc),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ),
                    PropertyStatusChip(status: property.status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF667085),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.address(loc),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (property.marketValueUsd > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    loc.marketValue,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyRegistry.formatAmount(value, currency),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
                if (property.areaSqm > 0 || property.bedrooms > 0) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (property.areaSqm > 0)
                        _SpecChip(
                          icon: Icons.square_foot_outlined,
                          label: '${property.areaSqm.toInt()} m²',
                        ),
                      if (property.bedrooms > 0)
                        _SpecChip(
                          icon: Icons.bed_outlined,
                          label: '${property.bedrooms}',
                        ),
                    ],
                  ),
                ],
                if (property.insights.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _InsightPanel(insights: property.insights),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagedPropertyCard extends StatelessWidget {
  const _ManagedPropertyCard({required this.property});

  final OwnedProperty property;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currency = context.watch<CountryContextProvider>().activeCurrency;
    final income = CurrencyRegistry.convert(
      property.monthlyIncomeUsd ?? 0,
      from: 'USD',
      to: currency,
    );
    final fee = CurrencyRegistry.convert(
      property.managementFeeUsd ?? 0,
      from: 'USD',
      to: currency,
    );

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PropertyPhoto(property: property),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.title(loc),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ),
                    PropertyStatusChip(status: property.status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF667085),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.address(loc),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.apartment_outlined,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.managedByCompany,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  loc.monthlyIncome,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyRegistry.formatAmount(income, currency)} ${loc.perMonth}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEF2F6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_outlined,
                        size: 18,
                        color: Color(0xFF667085),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.managementFee,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475467),
                          ),
                        ),
                      ),
                      Text(
                        '${CurrencyRegistry.formatAmount(fee, currency)} ${loc.perMonth}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyPhoto extends StatelessWidget {
  const _PropertyPhoto({required this.property});

  final OwnedProperty property;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (property.imageBytes != null) {
      image = Image.memory(
        property.imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 168,
      );
    } else if (property.imageUrl != null && property.imageUrl!.isNotEmpty) {
      image = Image.network(
        property.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 168,
        errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
      );
    } else {
      image = const _PhotoPlaceholder();
    }

    return SizedBox(
      height: 168,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x33000000)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.home_work_outlined, color: Colors.white, size: 48),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEF2F6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.insights});

  final List<OwnedPriceInsight> insights;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_outlined,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loc.priceInsightsTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final insight in insights)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.label(loc),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
