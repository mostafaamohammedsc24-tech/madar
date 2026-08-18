import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/currency/currency_registry.dart';
import '../../../../core/demo/demo_mode.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../features/authentication/routing/auth_globals.dart';
import '../../../../services/supabase_service.dart';
import '../../data/party_deal_store.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/enums/transaction_enums.dart';
import '../../domain/models/deal_transaction.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.initial,
  });

  final String transactionId;
  final DealTransaction? initial;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _repo = TransactionRepository();
  final _otpCtrl = TextEditingController();
  DealTransaction? _tx;
  bool _loading = true;
  final List<Offset?> _signature = [];

  @override
  void initState() {
    super.initState();
    _tx = widget.initial;
    _resolveSide();
    _refresh();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  PartyDealProgress get _p {
    final tx = _tx;
    final progress = PartyDealStore.of(widget.transactionId);
    if (tx != null) {
      PartyDealStore.seedIfNeeded(
        widget.transactionId,
        agricultural: tx.type == DealTransactionType.agricultural,
      );
    }
    return progress;
  }

  bool get _asBuyer => _p.isBuyer;

  void _resolveSide() {
    final p = _p;
    if (p.mySide != null) return;
    final tx = _tx;
    if (tx == null) return;
    final userId = SupabaseService.instance.currentUser?.id;
    final role = tx.roleForUser(userId);
    if (role == TransactionRole.buyer) {
      p.mySide = PartySide.buyer;
      return;
    }
    if (role == TransactionRole.seller) {
      p.mySide = PartySide.seller;
      return;
    }
    final phone = userAuthNotifier.state.fullPhoneNumber.replaceAll(
      RegExp(r'\D'),
      '',
    );
    if (phone.isEmpty) return;
    final suffix = phone.length > 8 ? phone.substring(phone.length - 8) : phone;
    final buyer = tx.buyerPhone?.replaceAll(RegExp(r'\D'), '') ?? '';
    final seller = tx.sellerPhone?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (buyer.endsWith(suffix)) {
      p.mySide = PartySide.buyer;
    } else if (seller.endsWith(suffix)) {
      p.mySide = PartySide.seller;
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final tx = await _repo.getById(widget.transactionId);
    if (!mounted) return;
    setState(() {
      _tx = tx ?? _tx;
      _loading = false;
    });
    _resolveSide();
  }

  Future<void> _uploadDocument(String field) async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
    } catch (_) {
      return;
    }
    final asBuyer = _asBuyer;
    setState(() {
      _p.markDocUnderReview(field, asBuyer: asBuyer);
    });
    // Demo / local flow: lawyer reviews shortly after upload.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _p.markDocApproved(field, asBuyer: asBuyer);
      _completeOtherIfDemo();
    });
  }

  Future<void> _pickFile() async {
    try {
      await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (_) {}
  }

  void _completeOtherIfDemo() {
    if (!DemoMode.enabled) return;
    final p = _p;
    if (_asBuyer) {
      p.sellerIdentity = p.sellerIdentity || p.buyerIdentity;
      p.sellerDocs = p.sellerDocs || p.buyerDocs;
      for (final f in p.lawyerDocFields) {
        if (p.buyerDocStatus[f] == DocReviewStatus.approved) {
          p.sellerDocStatus[f] = DocReviewStatus.approved;
        }
      }
      p.sellerContractUploaded =
          p.sellerContractUploaded || p.buyerContractUploaded;
      p.sellerOtp = p.sellerOtp || p.buyerOtp;
      p.sellerFace = p.sellerFace || p.buyerFace;
      p.sellerSigned = p.sellerSigned || p.buyerSigned;
    } else {
      p.buyerIdentity = p.buyerIdentity || p.sellerIdentity;
      p.buyerDocs = p.buyerDocs || p.sellerDocs;
      for (final f in p.lawyerDocFields) {
        if (p.sellerDocStatus[f] == DocReviewStatus.approved) {
          p.buyerDocStatus[f] = DocReviewStatus.approved;
        }
      }
      p.buyerContractUploaded =
          p.buyerContractUploaded || p.sellerContractUploaded;
      p.buyerOtp = p.buyerOtp || p.sellerOtp;
      p.buyerFace = p.buyerFace || p.sellerFace;
      p.buyerSigned = p.buyerSigned || p.sellerSigned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tx = _tx;
    final p = _p;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(tx?.transactionNumber ?? loc.navDeals)),
      body: _loading && tx == null
          ? const Center(child: CircularProgressIndicator())
          : tx == null
              ? Center(child: Text(loc.transactionNotFound))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  children: [
                    Text(
                      tx.transactionNumber,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx.propertyAddressSnapshot ?? '',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (tx.salePrice != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        CurrencyRegistry.formatAmount(
                          tx.salePrice!,
                          tx.currencyCode,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _asBuyer
                                ? Icons.person_outline
                                : Icons.storefront_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${loc.yourRoleInDeal}: ${_asBuyer ? loc.roleBuyer : loc.roleSeller}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.furniturePartnerNotice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _stageCard(
                      theme,
                      loc,
                      index: 1,
                      title: loc.stepIdentity,
                      hint: loc.txIdentityHint,
                      done: p.myIdentityDone,
                      locked: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!p.myIdentityDone)
                            FilledButton.icon(
                              onPressed: () {
                                setState(() {
                                  if (_asBuyer) {
                                    p.buyerIdentity = true;
                                  } else {
                                    p.sellerIdentity = true;
                                  }
                                  _completeOtherIfDemo();
                                });
                              },
                              icon: const Icon(Icons.verified_user_outlined),
                              label: Text(loc.confirmIdentity),
                            )
                          else ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    loc.identityConfirmedSuccess,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!p.bothIdentity)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(loc.waitingForOtherPartyAction),
                              ),
                          ],
                        ],
                      ),
                    ),
                    _stageCard(
                      theme,
                      loc,
                      index: 2,
                      title: loc.stepDocuments,
                      hint: loc.txDocumentsHint,
                      done: (_asBuyer ? p.buyerDocs : p.sellerDocs),
                      locked: !p.bothIdentity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final field in p.lawyerDocFields)
                            _DocumentUploadTile(
                              label: _docLabel(loc, field),
                              status: p.docStatusFor(field, asBuyer: _asBuyer),
                              underReviewLabel: loc.documentUnderLawyerReview,
                              approvedLabel: loc.documentApprovedByLawyer,
                              tapToUploadLabel: loc.tapToUploadDocument,
                              onUpload: () => _uploadDocument(field),
                            ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                if (!p.lawyerDocFields.contains('deed')) {
                                  p.lawyerDocFields.add('deed');
                                }
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: Text(loc.addRequiredDocument),
                          ),
                        ],
                      ),
                    ),
                    _stageCard(
                      theme,
                      loc,
                      index: 3,
                      title: loc.stepContract,
                      hint: loc.txContractHint,
                      done: p.bothSigned,
                      locked: !p.bothDocs,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() => p.contractSent = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.downloadContractPdf)),
                              );
                            },
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(loc.downloadContractPdf),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.lawyersTeamChat)),
                              );
                            },
                            icon: const Icon(Icons.groups_outlined),
                            label: Text(loc.lawyersTeamChat),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              await _pickFile();
                              setState(() {
                                if (_asBuyer) {
                                  p.buyerContractUploaded = true;
                                } else {
                                  p.sellerContractUploaded = true;
                                }
                                _completeOtherIfDemo();
                              });
                            },
                            icon: const Icon(Icons.upload_file),
                            label: Text(loc.uploadSignedContract),
                          ),
                          if (p.bothContracts) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _otpCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: loc.enterOtpCode,
                                hintText: DemoMode.enabled ? '123456' : null,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: () {
                                final ok = !DemoMode.enabled ||
                                    _otpCtrl.text.trim() == '123456' ||
                                    _otpCtrl.text.trim().isNotEmpty;
                                if (!ok) return;
                                setState(() {
                                  if (_asBuyer) {
                                    p.buyerOtp = true;
                                  } else {
                                    p.sellerOtp = true;
                                  }
                                  _completeOtherIfDemo();
                                });
                              },
                              child: Text(loc.enterOtpCode),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: () {
                                setState(() {
                                  if (_asBuyer) {
                                    p.buyerFace = true;
                                  } else {
                                    p.sellerFace = true;
                                  }
                                  _completeOtherIfDemo();
                                });
                              },
                              child: Text(loc.verifyFaceCta),
                            ),
                            if ((_asBuyer ? p.buyerOtp && p.buyerFace : p.sellerOtp && p.sellerFace)) ...[
                              const SizedBox(height: 12),
                              Text(loc.drawSignature),
                              const SizedBox(height: 8),
                              Container(
                                height: 140,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: GestureDetector(
                                  onPanStart: (d) => setState(
                                    () => _signature.add(d.localPosition),
                                  ),
                                  onPanUpdate: (d) => setState(
                                    () => _signature.add(d.localPosition),
                                  ),
                                  onPanEnd: (_) =>
                                      setState(() => _signature.add(null)),
                                  child: CustomPaint(
                                    painter: _SignaturePainter(_signature),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: _signature.whereType<Offset>().length < 4
                                    ? null
                                    : () {
                                        setState(() {
                                          if (_asBuyer) {
                                            p.buyerSigned = true;
                                            p.buyerSignature = 'signed';
                                          } else {
                                            p.sellerSigned = true;
                                            p.sellerSignature = 'signed';
                                          }
                                          _completeOtherIfDemo();
                                        });
                                      },
                                child: Text(loc.sendSignature),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    _stageCard(
                      theme,
                      loc,
                      index: 4,
                      title: loc.stepEscrow,
                      hint: loc.txEscrowHint,
                      done: p.bankDepositConfirmed,
                      locked: !p.bothSigned,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            loc.escrowBankBaghdad,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${loc.depositAmountLabel}: ${CurrencyRegistry.formatAmount(_escrowAmount(tx), tx.currencyCode)}',
                          ),
                          const SizedBox(height: 8),
                          Text(loc.fundsReleaseNote),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                p.bankDepositConfirmed = true;
                                p.receipts.add({
                                  'title': loc.receiptIssued,
                                  'body':
                                      '${loc.escrowBankBaghdad}\n${CurrencyRegistry.formatAmount(_escrowAmount(tx), tx.currencyCode)}',
                                });
                              });
                            },
                            child: Text(loc.confirmDeposit),
                          ),
                          if (tx.type == DealTransactionType.agricultural) ...[
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: p.buyerMoveInApproved,
                              onChanged: (v) => setState(
                                () => p.buyerMoveInApproved = v ?? false,
                              ),
                              title: Text(loc.stepAgriculturalTransfer),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: p.lawyerReleaseApproved,
                              onChanged: (v) => setState(
                                () => p.lawyerReleaseApproved = v ?? false,
                              ),
                              title: Text(loc.companyLawyerLabel),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _stageCard(
                      theme,
                      loc,
                      index: 5,
                      title: loc.stepDeed,
                      hint: loc.txDeedHint,
                      done: p.skipDeed || p.deedUploaded,
                      locked: !p.bankDepositConfirmed,
                      child: p.skipDeed
                          ? Text(loc.skipAgriculturalDeed)
                          : FilledButton.icon(
                              onPressed: () async {
                                await _pickFile();
                                setState(() => p.deedUploaded = true);
                              },
                              icon: const Icon(Icons.upload_file),
                              label: Text(loc.uploadDeed),
                            ),
                    ),
                    _stageCard(
                      theme,
                      loc,
                      index: 6,
                      title: loc.stepSettlement,
                      hint: loc.txSettlementHint,
                      done: p.settlementClosed,
                      locked: !(p.skipDeed || p.deedUploaded) ||
                          !p.bankDepositConfirmed,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${loc.correspondenceFeeLabel}: ${CurrencyRegistry.formatAmount(_feePercent(tx), tx.currencyCode)}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${loc.stampFeeLabel}: ${CurrencyRegistry.formatAmount(600000, 'IQD')}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${loc.remainderToSeller}: ${CurrencyRegistry.formatAmount(_remainder(tx), tx.currencyCode)}',
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                p.settlementClosed = true;
                                p.receipts.add({
                                  'title': loc.receiptIssued,
                                  'body': loc.transactionCompleted,
                                });
                              });
                            },
                            child: Text(loc.closeDeal),
                          ),
                          if (p.settlementClosed) ...[
                            const SizedBox(height: 8),
                            Text(
                              loc.transactionCompleted,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (p.receipts.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        loc.viewReceipt,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ...p.receipts.map(
                        (r) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.receipt_long),
                          title: Text(r['title'] ?? ''),
                          subtitle: Text(r['body'] ?? ''),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  double _escrowAmount(DealTransaction tx) {
    final price = tx.salePrice ?? 0;
    return price + _feePercent(tx) + 600000;
  }

  double _feePercent(DealTransaction tx) => (tx.salePrice ?? 0) * 0.02;

  double _remainder(DealTransaction tx) {
    final price = tx.salePrice ?? 0;
    return (price - _feePercent(tx) - 600000).clamp(0, double.infinity);
  }

  String _docLabel(AppLocalizations loc, String key) {
    switch (key) {
      case 'national_id':
        return loc.nationalIdDoc;
      case 'proof_of_funds':
        return loc.proofOfFundsDoc;
      case 'deed':
        return loc.propertyDeedDoc;
      default:
        return key;
    }
  }

  Widget _stageCard(
    ThemeData theme,
    AppLocalizations loc, {
    required int index,
    required String title,
    required String hint,
    required bool done,
    required bool locked,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: done
                      ? const Color(0xFF2E7D32)
                      : theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: done
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  child: done
                      ? const Icon(Icons.check, size: 16)
                      : Text(
                          '$index',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: done ? const Color(0xFF2E7D32) : null,
                    ),
                  ),
                ),
                if (done)
                  const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
              ],
            ),
            const SizedBox(height: 8),
            Text(hint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            if (locked)
              Text(
                loc.waitingForOtherPartyAction,
                style: theme.textTheme.bodySmall,
              )
            else
              child,
          ],
        ),
      ),
    );
  }
}

class _DocumentUploadTile extends StatelessWidget {
  const _DocumentUploadTile({
    required this.label,
    required this.status,
    required this.underReviewLabel,
    required this.approvedLabel,
    required this.tapToUploadLabel,
    required this.onUpload,
  });

  final String label;
  final DocReviewStatus status;
  final String underReviewLabel;
  final String approvedLabel;
  final String tapToUploadLabel;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canUpload = status == DocReviewStatus.missing;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: ListTile(
        onTap: canUpload ? onUpload : null,
        leading: Icon(
          status == DocReviewStatus.approved
              ? Icons.check_circle
              : status == DocReviewStatus.underReview
                  ? Icons.hourglass_top_rounded
                  : Icons.badge_outlined,
          color: status == DocReviewStatus.approved
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          switch (status) {
            DocReviewStatus.missing => tapToUploadLabel,
            DocReviewStatus.underReview => underReviewLabel,
            DocReviewStatus.approved => approvedLabel,
          },
        ),
        trailing: status == DocReviewStatus.underReview
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : status == DocReviewStatus.approved
                ? Icon(Icons.verified, color: theme.colorScheme.primary)
                : const Icon(Icons.upload_file),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points);
  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) {
        canvas.drawLine(a, b, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
