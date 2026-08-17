import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/enums/office_enums.dart';
import '../../domain/models/office_models.dart';
import '../providers/office_auth_notifier.dart';

class OfficeLeadsScreen extends StatefulWidget {
  const OfficeLeadsScreen({super.key});

  @override
  State<OfficeLeadsScreen> createState() => _OfficeLeadsScreenState();
}

class _OfficeLeadsScreenState extends State<OfficeLeadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;
  List<OfficeReferral> _referrals = [];
  List<OfficePropertyReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<OfficeAuthNotifier>().repository;
    setState(() => _loading = true);
    final refs = await repo.listReferrals();
    final reports = await repo.listReports();
    if (!mounted) return;
    setState(() {
      _referrals = refs;
      _reports = reports;
      _loading = false;
    });
  }

  String _refStatus(AppLocalizations loc, OfficeReferralStatus s) {
    switch (s) {
      case OfficeReferralStatus.neu:
        return loc.officeLeadNew;
      case OfficeReferralStatus.contacting:
        return loc.officeLeadContacting;
      case OfficeReferralStatus.qualified:
        return loc.officeLeadQualified;
      case OfficeReferralStatus.negotiating:
        return loc.officeLeadNegotiating;
      case OfficeReferralStatus.transactionCreated:
        return loc.officeLeadTxCreated;
      case OfficeReferralStatus.completed:
        return loc.officeLeadCompleted;
      case OfficeReferralStatus.rejected:
        return loc.officeLeadRejected;
      case OfficeReferralStatus.expired:
        return loc.officeLeadExpired;
    }
  }

  String _reportStatus(AppLocalizations loc, OfficeReportStatus s) {
    switch (s) {
      case OfficeReportStatus.underReview:
        return loc.officeReportUnderReview;
      case OfficeReportStatus.contactingOwner:
        return loc.officeReportContactingOwner;
      case OfficeReportStatus.ownerApproved:
        return loc.officeReportOwnerApproved;
      case OfficeReportStatus.ownerDeclined:
        return loc.officeReportOwnerDeclined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(loc.officeNavLeads),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: loc.officeBuyerLeads),
            Tab(text: loc.officePropertyReports),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                RefreshIndicator(
                  onRefresh: _load,
                  child: _referrals.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(child: Text(loc.officeNoLeads)),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _referrals.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final r = _referrals[i];
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                              ),
                              title: Text(loc.officeBuyerLead),
                              subtitle: Text(
                                '${_refStatus(loc, r.status)}\n'
                                '${r.createdAt?.toLocal().toString().split('.').first ?? ''}',
                              ),
                              isThreeLine: true,
                              onTap: r.conversationId == null
                                  ? null
                                  : () => context.push(
                                        '/office/chat/${r.conversationId}',
                                      ),
                            );
                          },
                        ),
                ),
                RefreshIndicator(
                  onRefresh: _load,
                  child: _reports.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(child: Text(loc.officeNoReports)),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reports.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final r = _reports[i];
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                              ),
                              title: Text(
                                r.addressText ?? loc.officeReportProperty,
                              ),
                              subtitle: Text(
                                '${_reportStatus(loc, r.status)} · '
                                '${r.propertyType ?? ''} · ${r.listingType ?? ''}',
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
