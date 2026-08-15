import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../providers/country_context_provider.dart';
import '../../core/localization/app_localizations.dart';

class CountryConfigPanel extends StatefulWidget {
  const CountryConfigPanel({super.key});

  @override
  State<CountryConfigPanel> createState() => _CountryConfigPanelState();
}

class _CountryConfigPanelState extends State<CountryConfigPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppCountry _selectedCountry = kSupportedCountries.first;
  bool _isSaving = false;

  // Per-country config state
  final Map<String, _CountryConfig> _configs = {
    for (final c in kSupportedCountries)
      c.code: _CountryConfig.defaultFor(c.code),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _CountryConfig get _current => _configs[_selectedCountry.code]!;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedCountry.flag} ${_selectedCountry.nameEn} settings saved',
            style: GoogleFonts.dmSans(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1220),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          loc.countryConfig,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(
                    Icons.save_rounded,
                    size: 16,
                    color: Color(0xFF6C63FF),
                  ),
                  label: Text(
                    loc.save,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withAlpha(20)),
        ),
      ),
      body: Column(
        children: [
          // Country selector
          Container(
            color: const Color(0xFF0D1220),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            child: SizedBox(
              height: 5.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kSupportedCountries.length,
                separatorBuilder: (_, __) => SizedBox(width: 2.w),
                itemBuilder: (context, i) {
                  final c = kSupportedCountries[i];
                  final isActive = c.code == _selectedCountry.code;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCountry = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF6C63FF).withAlpha(51)
                            : Colors.white.withAlpha(13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF6C63FF)
                              : Colors.white.withAlpha(26),
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.flag, style: const TextStyle(fontSize: 16)),
                          SizedBox(width: 1.5.w),
                          Text(
                            c.nameEn,
                            style: GoogleFonts.dmSans(
                              color: isActive
                                  ? const Color(0xFF6C63FF)
                                  : Colors.white70,
                              fontSize: 11.sp,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Tab bar
          Container(
            color: const Color(0xFF0D1220),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF6C63FF),
              unselectedLabelColor: Colors.white38,
              indicatorColor: const Color(0xFF6C63FF),
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: GoogleFonts.dmSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11.sp),
              tabs: [
                Tab(text: loc.generalSettings),
                Tab(text: loc.feeStructure),
                Tab(text: loc.transactionRules),
                Tab(text: loc.legalDocuments),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _GeneralSettingsTab(
                  config: _current,
                  country: _selectedCountry,
                  onChanged: () => setState(() {}),
                ),
                _FeeStructureTab(
                  config: _current,
                  country: _selectedCountry,
                  onChanged: () => setState(() {}),
                ),
                _TransactionRulesTab(
                  config: _current,
                  country: _selectedCountry,
                  onChanged: () => setState(() {}),
                ),
                _LegalDocumentsTab(
                  config: _current,
                  country: _selectedCountry,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Config Model ─────────────────────────────────────────────────────────────
class _CountryConfig {
  // General
  bool isActive;
  bool allowNewRegistrations;
  String defaultLanguage;
  String timezone;
  String dateFormat;

  // Fees
  double brokerageFeePercent;
  double taxPercent;
  double serviceFee;
  double bankEscrowFee;
  bool feesEditable;

  // Transaction rules
  bool requireNationalId;
  bool requireProofOfFunds;
  bool requirePropertyDeed;
  bool requireBankEscrow;
  bool requireFaceVerification;
  bool requireOtp;
  int maxTransactionDays;
  String transactionPrefix;

  // Legal docs
  List<String> requiredDocuments;
  String contractTemplate;
  bool autoGenerateReceipts;

  _CountryConfig({
    required this.isActive,
    required this.allowNewRegistrations,
    required this.defaultLanguage,
    required this.timezone,
    required this.dateFormat,
    required this.brokerageFeePercent,
    required this.taxPercent,
    required this.serviceFee,
    required this.bankEscrowFee,
    required this.feesEditable,
    required this.requireNationalId,
    required this.requireProofOfFunds,
    required this.requirePropertyDeed,
    required this.requireBankEscrow,
    required this.requireFaceVerification,
    required this.requireOtp,
    required this.maxTransactionDays,
    required this.transactionPrefix,
    required this.requiredDocuments,
    required this.contractTemplate,
    required this.autoGenerateReceipts,
  });

  factory _CountryConfig.defaultFor(String code) {
    final prefixes = {
      'IQ': 'MADAR-IQ',
      'SA': 'MADAR-SA',
      'AE': 'MADAR-AE',
      'JO': 'MADAR-JO',
      'KW': 'MADAR-KW',
      'QA': 'MADAR-QA',
      'BH': 'MADAR-BH',
      'OM': 'MADAR-OM',
    };
    final timezones = {
      'IQ': 'Asia/Baghdad (UTC+3)',
      'SA': 'Asia/Riyadh (UTC+3)',
      'AE': 'Asia/Dubai (UTC+4)',
      'JO': 'Asia/Amman (UTC+3)',
      'KW': 'Asia/Kuwait (UTC+3)',
      'QA': 'Asia/Qatar (UTC+3)',
      'BH': 'Asia/Bahrain (UTC+3)',
      'OM': 'Asia/Muscat (UTC+4)',
    };
    return _CountryConfig(
      isActive: code == 'IQ' || code == 'SA',
      allowNewRegistrations: true,
      defaultLanguage: 'Arabic',
      timezone: timezones[code] ?? 'UTC+3',
      dateFormat: 'DD/MM/YYYY',
      brokerageFeePercent: 1.0,
      taxPercent: code == 'SA' ? 15.0 : 0.0,
      serviceFee: 300000,
      bankEscrowFee: 0.5,
      feesEditable: true,
      requireNationalId: true,
      requireProofOfFunds: true,
      requirePropertyDeed: code != 'IQ',
      requireBankEscrow: true,
      requireFaceVerification: true,
      requireOtp: true,
      maxTransactionDays: 90,
      transactionPrefix: prefixes[code] ?? 'MADAR',
      requiredDocuments: ['National ID', 'Proof of Funds'],
      contractTemplate: 'Standard Arabic Contract',
      autoGenerateReceipts: true,
    );
  }
}

// ─── General Settings Tab ─────────────────────────────────────────────────────
class _GeneralSettingsTab extends StatelessWidget {
  final _CountryConfig config;
  final AppCountry country;
  final VoidCallback onChanged;

  const _GeneralSettingsTab({
    required this.config,
    required this.country,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _SectionHeader(title: 'Country Status', icon: Icons.flag_rounded),
        SizedBox(height: 1.h),
        _ConfigCard(
          children: [
            _SwitchRow(
              label: 'Country Active',
              subtitle: 'Enable operations in ${country.nameEn}',
              value: config.isActive,
              onChanged: (v) {
                config.isActive = v;
                onChanged();
              },
            ),
            _Divider(),
            _SwitchRow(
              label: 'Allow New Registrations',
              subtitle: 'Accept new office/agent registrations',
              value: config.allowNewRegistrations,
              onChanged: (v) {
                config.allowNewRegistrations = v;
                onChanged();
              },
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _SectionHeader(title: 'Locale Settings', icon: Icons.language_rounded),
        SizedBox(height: 1.h),
        _ConfigCard(
          children: [
            _DropdownRow(
              label: 'Default Language',
              value: config.defaultLanguage,
              options: ['Arabic', 'English', 'Kurdish'],
              onChanged: (v) {
                config.defaultLanguage = v!;
                onChanged();
              },
            ),
            _Divider(),
            _DropdownRow(
              label: 'Date Format',
              value: config.dateFormat,
              options: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
              onChanged: (v) {
                config.dateFormat = v!;
                onChanged();
              },
            ),
            _Divider(),
            _InfoRow(label: 'Timezone', value: config.timezone),
            _Divider(),
            _InfoRow(
              label: 'Currency',
              value: '${country.currency} (${country.currencySymbol})',
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _SectionHeader(title: 'Transaction ID', icon: Icons.tag_rounded),
        SizedBox(height: 1.h),
        _ConfigCard(
          children: [
            _TextFieldRow(
              label: 'Transaction Prefix',
              value: config.transactionPrefix,
              hint: 'e.g. MADAR-IQ',
              onChanged: (v) {
                config.transactionPrefix = v;
                onChanged();
              },
            ),
            _Divider(),
            _InfoRow(
              label: 'Sample ID',
              value: '${config.transactionPrefix}-2026-00001',
              valueColor: const Color(0xFF6C63FF),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Fee Structure Tab ────────────────────────────────────────────────────────
class _FeeStructureTab extends StatelessWidget {
  final _CountryConfig config;
  final AppCountry country;
  final VoidCallback onChanged;

  const _FeeStructureTab({
    required this.config,
    required this.country,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _SectionHeader(
          title: 'Brokerage & Service Fees',
          icon: Icons.percent_rounded,
        ),
        SizedBox(height: 1.h),
        _ConfigCard(
          children: [
            _SliderRow(
              label: 'Brokerage Fee',
              value: config.brokerageFeePercent,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              suffix: '%',
              onChanged: (v) {
                config.brokerageFeePercent = v;
                onChanged();
              },
            ),
            _Divider(),
            _SliderRow(
              label: 'Tax Rate',
              value: config.taxPercent,
              min: 0.0,
              max: 25.0,
              divisions: 25,
              suffix: '%',
              onChanged: (v) {
                config.taxPercent = v;
                onChanged();
              },
            ),
            _Divider(),
            _SliderRow(
              label: 'Bank Escrow Fee',
              value: config.bankEscrowFee,
              min: 0.1,
              max: 2.0,
              divisions: 19,
              suffix: '%',
              onChanged: (v) {
                config.bankEscrowFee = v;
                onChanged();
              },
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _SectionHeader(title: 'Fixed Fees', icon: Icons.attach_money_rounded),
        SizedBox(height: 1.h),
        _ConfigCard(
          children: [
            _TextFieldRow(
              label: 'Service Fee (per party)',
              value: config.serviceFee.toStringAsFixed(0),
              hint: '300000',
              keyboardType: TextInputType.number,
              suffix: country.currencySymbol,
              onChanged: (v) {
                config.serviceFee = double.tryParse(v) ?? config.serviceFee;
                onChanged();
              },
            ),
            _Divider(),
            _SwitchRow(
              label: 'Allow Finance Team to Edit Fees',
              subtitle: 'Finance officers can override fee amounts',
              value: config.feesEditable,
              onChanged: (v) {
                config.feesEditable = v;
                onChanged();
              },
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _FeePreviewCard(config: config, country: country),
      ],
    );
  }
}

class _FeePreviewCard extends StatelessWidget {
  final _CountryConfig config;
  final AppCountry country;

  const _FeePreviewCard({required this.config, required this.country});

  @override
  Widget build(BuildContext context) {
    const sampleValue = 100000000.0;
    final brokerage = sampleValue * config.brokerageFeePercent / 100;
    final tax = sampleValue * config.taxPercent / 100;
    final escrow = sampleValue * config.bankEscrowFee / 100;
    final service = config.serviceFee * 2;
    final total = brokerage + tax + escrow + service;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withAlpha(38),
            const Color(0xFF6C63FF).withAlpha(13),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6C63FF).withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Preview (Sample: 100M ${country.currencySymbol})',
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.5.h),
          _PreviewRow(
            'Brokerage (${config.brokerageFeePercent.toStringAsFixed(1)}%)',
            brokerage,
            country.currencySymbol,
          ),
          _PreviewRow(
            'Tax (${config.taxPercent.toStringAsFixed(1)}%)',
            tax,
            country.currencySymbol,
          ),
          _PreviewRow(
            'Bank Escrow (${config.bankEscrowFee.toStringAsFixed(1)}%)',
            escrow,
            country.currencySymbol,
          ),
          _PreviewRow('Service Fee (×2)', service, country.currencySymbol),
          Divider(color: Colors.white.withAlpha(26), height: 2.h),
          _PreviewRow(
            'Total Fees',
            total,
            country.currencySymbol,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final double value;
  final String symbol;
  final bool isTotal;

  const _PreviewRow(
    this.label,
    this.value,
    this.symbol, {
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: isTotal ? Colors.white : Colors.white60,
              fontSize: 11.sp,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            '${_fmt(value)} $symbol',
            style: GoogleFonts.dmSans(
              color: isTotal ? const Color(0xFF6C63FF) : Colors.white70,
              fontSize: 11.sp,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Transaction Rules Tab ────────────────────────────────────────────────────
class _TransactionRulesTab extends StatelessWidget {
  final _CountryConfig config;
  final AppCountry country;
  final VoidCallback onChanged;

  const _TransactionRulesTab({
    required this.config,
    required this.country,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _SectionHeader(
          title: 'Required Verifications',
          icon: Icons.verified_user_rounded,
        ),
        SizedBox(height: 1.h),
        _ConfigCard(
          children: [
            _SwitchRow(
              label: 'OTP Verification',
              subtitle: 'Require OTP before signing',
              value: config.requireOtp,
              onChanged: (v) {
                config.requireOtp = v;
                onChanged();
              },
            ),
            _Divider(),
            _SwitchRow(
              label: 'Face Verification',
              subtitle: 'Require selfie face match',
              value: config.requireFaceVerification,
              onChanged: (v) {
                config.requireFaceVerification = v;
                onChanged();
              },
            ),
            _Divider(),
            _SwitchRow(
              label: 'National ID Required',
              subtitle: 'Mandatory for both parties',
              value: config.requireNationalId,
              onChanged: (v) {
                config.requireNationalId = v;
                onChanged();
              },
            ),
            _Divider(),
            _SwitchRow(
              label: 'Proof of Funds Required',
              subtitle: 'Bank statement or equivalent',
              value: config.requireProofOfFunds,
              onChanged: (v) {
                config.requireProofOfFunds = v;
                onChanged();
              },
            ),
            _Divider(),
            _SwitchRow(
              label: 'Property Deed Required',
              subtitle: 'Title deed upload mandatory',
              value: config.requirePropertyDeed,
              onChanged: (v) {
                config.requirePropertyDeed = v;
                onChanged();
              },
            ),
            _Divider(),
            _SwitchRow(
              label: 'Bank Escrow Required',
              subtitle: 'Funds must be held in escrow',
              value: config.requireBankEscrow,
              onChanged: (v) {
                config.requireBankEscrow = v;
                onChanged();
              },
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _SectionHeader(title: 'Transaction Limits', icon: Icons.timer_rounded),
        SizedBox(height: 1.h),
        _ConfigCard(
          children: [
            _SliderRow(
              label: 'Max Transaction Duration',
              value: config.maxTransactionDays.toDouble(),
              min: 30,
              max: 365,
              divisions: 11,
              suffix: ' days',
              onChanged: (v) {
                config.maxTransactionDays = v.toInt();
                onChanged();
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Legal Documents Tab ──────────────────────────────────────────────────────
class _LegalDocumentsTab extends StatelessWidget {
  final _CountryConfig config;
  final AppCountry country;
  final VoidCallback onChanged;

  const _LegalDocumentsTab({
    required this.config,
    required this.country,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allDocs = [
      'National ID',
      'Proof of Funds',
      'Property Deed',
      'Bank Statement',
      'Tax Certificate',
      'Marriage Certificate',
      'Inheritance Certificate',
      'Power of Attorney',
      'Court Order',
      'Agricultural Land Permit',
    ];

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _SectionHeader(
          title: 'Required Documents',
          icon: Icons.description_rounded,
        ),
        SizedBox(height: 1.h),
        _ConfigCard(
          children: [
            for (int i = 0; i < allDocs.length; i++) ...[
              if (i > 0) _Divider(),
              _CheckboxRow(
                label: allDocs[i],
                value: config.requiredDocuments.contains(allDocs[i]),
                onChanged: (v) {
                  if (v == true) {
                    config.requiredDocuments.add(allDocs[i]);
                  } else {
                    config.requiredDocuments.remove(allDocs[i]);
                  }
                  onChanged();
                },
              ),
            ],
          ],
        ),
        SizedBox(height: 2.h),
        _SectionHeader(
          title: 'Contract & Receipts',
          icon: Icons.receipt_long_rounded,
        ),
        SizedBox(height: 1.h),
        _ConfigCard(
          children: [
            _DropdownRow(
              label: 'Contract Template',
              value: config.contractTemplate,
              options: [
                'Standard Arabic Contract',
                'Iraqi Real Estate Law Template',
                'Saudi RERA Template',
                'UAE DLD Template',
                'Custom Template',
              ],
              onChanged: (v) {
                config.contractTemplate = v!;
                onChanged();
              },
            ),
            _Divider(),
            _SwitchRow(
              label: 'Auto-Generate Receipts',
              subtitle: 'Automatically create PDF receipts',
              value: config.autoGenerateReceipts,
              onChanged: (v) {
                config.autoGenerateReceipts = v;
                onChanged();
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Shared UI Components ─────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 16),
        SizedBox(width: 2.w),
        Text(
          title,
          style: GoogleFonts.dmSans(
            color: Colors.white70,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final List<Widget> children;

  const _ConfigCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withAlpha(15),
      indent: 4.w,
      endIndent: 4.w,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle!,
                    style: GoogleFonts.dmSans(
                      color: Colors.white38,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF6C63FF),
            activeTrackColor: const Color(0xFF6C63FF).withAlpha(77),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white.withAlpha(26),
          ),
        ],
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF1A2035),
            style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 11.sp),
            underline: const SizedBox(),
            icon: const Icon(
              Icons.expand_more_rounded,
              color: Colors.white38,
              size: 18,
            ),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: valueColor ?? Colors.white60,
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextFieldRow extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final String? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const _TextFieldRow({
    required this.label,
    required this.value,
    required this.hint,
    this.suffix,
    this.keyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: value,
              keyboardType: keyboardType,
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11.sp),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.dmSans(
                  color: Colors.white24,
                  fontSize: 11.sp,
                ),
                suffixText: suffix,
                suffixStyle: GoogleFonts.dmSans(
                  color: Colors.white38,
                  fontSize: 11.sp,
                ),
                filled: true,
                fillColor: Colors.white.withAlpha(13),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withAlpha(26)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withAlpha(26)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withAlpha(51),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${value % 1 == 0 ? value.toInt() : value.toStringAsFixed(1)}$suffix',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF6C63FF),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6C63FF),
              inactiveTrackColor: Colors.white.withAlpha(26),
              thumbColor: const Color(0xFF6C63FF),
              overlayColor: const Color(0xFF6C63FF).withAlpha(51),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF6C63FF),
              checkColor: Colors.white,
              side: BorderSide(color: Colors.white.withAlpha(77)),
            ),
          ],
        ),
      ),
    );
  }
}
