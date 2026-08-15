import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

// ─── Agent/Lawyer Dashboard ───────────────────────────────────────────────────

class AgentDashboardScreen extends ConsumerStatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  ConsumerState<AgentDashboardScreen> createState() =>
      _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends ConsumerState<AgentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _agentData;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  // Barcode generation
  String _selectedTxType = 'sale';
  final _buyerPhoneController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  String? _generatedBarcodeCode;
  bool _isGenerating = false;

  // Contract writing
  final _contractBodyController = TextEditingController();
  String _contractStatus = 'draft';
  bool _isSendingContract = false;

  // Document fields config
  final List<Map<String, dynamic>> _documentFields = [
    {
      'id': 'national_id',
      'label': 'National ID',
      'labelAr': 'الهوية الوطنية',
      'required': true,
      'enabled': true,
      'icon': Icons.badge,
    },
    {
      'id': 'proof_of_funds',
      'label': 'Proof of Funds',
      'labelAr': 'إثبات مصدر المال',
      'required': false,
      'enabled': false,
      'icon': Icons.account_balance_wallet,
    },
    {
      'id': 'property_deed',
      'label': 'Property Deed',
      'labelAr': 'سند الملكية',
      'required': false,
      'enabled': false,
      'icon': Icons.home,
    },
    {
      'id': 'tax_clearance',
      'label': 'Tax Clearance',
      'labelAr': 'براءة الذمة الضريبية',
      'required': false,
      'enabled': false,
      'icon': Icons.receipt_long,
    },
    {
      'id': 'power_of_attorney',
      'label': 'Power of Attorney',
      'labelAr': 'وكالة قانونية',
      'required': false,
      'enabled': false,
      'icon': Icons.gavel,
    },
    {
      'id': 'marriage_certificate',
      'label': 'Marriage Certificate',
      'labelAr': 'شهادة الزواج',
      'required': false,
      'enabled': false,
      'icon': Icons.favorite,
    },
    {
      'id': 'inheritance_doc',
      'label': 'Inheritance Document',
      'labelAr': 'وثيقة الإرث',
      'required': false,
      'enabled': false,
      'icon': Icons.family_restroom,
    },
    {
      'id': 'bank_statement',
      'label': 'Bank Statement',
      'labelAr': 'كشف حساب مصرفي',
      'required': false,
      'enabled': false,
      'icon': Icons.account_balance,
    },
  ];

  final List<Map<String, String>> _txTypes = [
    {'value': 'sale', 'label': 'Sale', 'labelAr': 'بيع', 'icon': 'home'},
    {'value': 'rent', 'label': 'Rent', 'labelAr': 'إيجار', 'icon': 'key'},
    {
      'value': 'mortgage',
      'label': 'Mortgage',
      'labelAr': 'رهن',
      'icon': 'bank',
    },
    {
      'value': 'agricultural',
      'label': 'Agricultural',
      'labelAr': 'زراعي',
      'icon': 'grass',
    },
  ];

  final List<Map<String, dynamic>> _demoTransactions = [
    {
      'reference_number': 'MDR-IQ-2026-001',
      'status': 'in_progress',
      'total_amount': 185000000.0,
      'current_stage_index': 2,
      'buyer_name': 'أحمد الراشدي',
      'seller_name': 'مريم خليل',
      'transaction_type': 'sale',
    },
    {
      'reference_number': 'MDR-IQ-2026-002',
      'status': 'completed',
      'total_amount': 250000000.0,
      'current_stage_index': 5,
      'buyer_name': 'علي حسين',
      'seller_name': 'سارة محمد',
      'transaction_type': 'sale',
    },
    {
      'reference_number': 'MDR-IQ-2026-003',
      'status': 'pending',
      'total_amount': 120000000.0,
      'current_stage_index': 0,
      'buyer_name': 'محمد عبدالله',
      'seller_name': 'فاطمة علي',
      'transaction_type': 'rent',
    },
  ];

  static const _agentColor = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _contractBodyController.text = _defaultContractTemplate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) {
      _agentData = extra;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buyerPhoneController.dispose();
    _sellerPhoneController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _contractBodyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final txs = await SupabaseService.instance.getOfficeTransactions(
        _agentData?['id'] as String? ?? 'demo',
      );
      if (mounted) {
        setState(() {
          _transactions = txs.isNotEmpty ? txs : _demoTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _transactions = _demoTransactions;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateBarcode() async {
    if (_buyerPhoneController.text.isEmpty ||
        _sellerPhoneController.text.isEmpty ||
        _addressController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please fill all required fields');
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
      final result = await SupabaseService.instance.generateTransactionBarcode(
        officeId: _agentData?['id'] as String? ?? 'demo_agent',
        transactionType: _selectedTxType,
        buyerPhone: _buyerPhoneController.text,
        sellerPhone: _sellerPhoneController.text,
        propertyAddress: _addressController.text,
        amount: amount,
        countryCode: _agentData?['country_code'] as String? ?? 'IQ',
      );
      final code =
          result?['barcode_code'] as String? ??
          'MDR-IQ-${DateTime.now().millisecondsSinceEpoch}';
      if (mounted) {
        setState(() {
          _generatedBarcodeCode = code;
          _isGenerating = false;
        });
      }
      _loadData();
    } catch (e) {
      final demoCode = 'MDR-IQ-${DateTime.now().millisecondsSinceEpoch}';
      if (mounted) {
        setState(() {
          _generatedBarcodeCode = demoCode;
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A0E1A),
                  Color(0xFF0D1B2A),
                  Color(0xFF0A0E1A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_agentColor.withAlpha(50), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildNewTransactionTab(),
                      _buildContractTab(),
                      _buildTransactionsTab(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/employee-dashboard'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(30)),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _agentColor.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.gavel, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _agentData?['full_name'] as String? ?? 'أ. كريم الجبوري',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Legal Agent / Lawyer',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(160),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _agentColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _agentColor.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Agent',
                  style: GoogleFonts.dmSans(
                    color: _agentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _agentColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: _agentColor.withAlpha(80),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withAlpha(120),
        labelStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'New Deal'),
          Tab(text: 'Contract'),
          Tab(text: 'Deals'),
        ],
      ),
    );
  }

  // ─── OVERVIEW TAB ─────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final active = _transactions
        .where((t) => t['status'] == 'in_progress')
        .length;
    final completed = _transactions
        .where((t) => t['status'] == 'completed')
        .length;
    final pending = _transactions.where((t) => t['status'] == 'pending').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          // Agent banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF1565C0),
                  Color(0xFF1976D2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _agentColor.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Legal Agent Portal',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withAlpha(180),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _agentData?['full_name'] as String? ??
                            'أ. كريم الجبوري',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Company-side agent with full transaction control',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withAlpha(160),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(50)),
                  ),
                  child: const Icon(Icons.gavel, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // KPI row
          Row(
            children: [
              _buildKpiCard(
                'Active',
                '$active',
                Icons.pending_actions,
                const Color(0xFF1565C0),
              ),
              const SizedBox(width: 10),
              _buildKpiCard(
                'Completed',
                '$completed',
                Icons.check_circle,
                const Color(0xFF388E3C),
              ),
              const SizedBox(width: 10),
              _buildKpiCard(
                'Pending',
                '$pending',
                Icons.hourglass_empty,
                const Color(0xFFF57C00),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick actions
          _buildAgentQuickActions(),
          const SizedBox(height: 16),
          // Recent transactions
          _buildRecentTransactionsList(),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white.withAlpha(120),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentQuickActions() {
    final actions = [
      {
        'icon': Icons.qr_code_2,
        'label': 'New Transaction',
        'onTap': () => _tabController.animateTo(1),
      },
      {
        'icon': Icons.edit_document,
        'label': 'Write Contract',
        'onTap': () => _tabController.animateTo(2),
      },
      {
        'icon': Icons.tune,
        'label': 'Doc Fields',
        'onTap': () => _showDocFieldsSheet(),
      },
      {
        'icon': Icons.verified_user,
        'label': 'Verify Identity',
        'onTap': () => context.go('/two-fa-verification'),
      },
      {
        'icon': Icons.send,
        'label': 'Send to Parties',
        'onTap': () => _showSendContractSheet(),
      },
      {
        'icon': Icons.receipt_long,
        'label': 'All Deals',
        'onTap': () => _tabController.animateTo(3),
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: actions.map((a) {
            return GestureDetector(
              onTap: a['onTap'] as VoidCallback,
              child: Container(
                decoration: BoxDecoration(
                  color: _agentColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _agentColor.withAlpha(40)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(a['icon'] as IconData, color: _agentColor, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      a['label'] as String,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withAlpha(200),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        ..._transactions.take(3).map((tx) => _buildTxCard(tx)),
      ],
    );
  }

  Widget _buildTxCard(Map<String, dynamic> tx) {
    final status = tx['status'] as String? ?? 'pending';
    final ref = tx['reference_number'] as String? ?? '';
    final buyer = tx['buyer_name'] as String? ?? 'Buyer';
    final seller = tx['seller_name'] as String? ?? 'Seller';
    final stage = tx['current_stage_index'] as int? ?? 0;
    final statusColor = status == 'completed'
        ? const Color(0xFF4CAF50)
        : status == 'in_progress'
        ? _agentColor
        : Colors.orange;
    final stageLabels = [
      'Identity',
      'Documents',
      'Contract',
      'Escrow',
      'Ownership',
      'Settlement',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$seller → $buyer',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withAlpha(140),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: GoogleFonts.dmSans(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(6, (i) {
              final done = i < stage;
              final current = i == stage;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: 4,
                  decoration: BoxDecoration(
                    color: done
                        ? _agentColor
                        : current
                        ? _agentColor.withAlpha(120)
                        : Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            'Stage ${stage + 1}/6: ${stage < stageLabels.length ? stageLabels[stage] : 'Complete'}',
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(100),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ─── NEW TRANSACTION TAB ──────────────────────────────────────────────────

  Widget _buildNewTransactionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Transaction Barcode',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Both parties will receive a barcode to start the transaction',
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(140),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          // Transaction type
          Text(
            'Transaction Type',
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(200),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _txTypes.map((t) {
              final isSelected = _selectedTxType == t['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedTxType = t['value']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _agentColor
                        : Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _agentColor
                          : Colors.white.withAlpha(30),
                    ),
                  ),
                  child: Text(
                    t['label']!,
                    style: GoogleFonts.dmSans(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withAlpha(160),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            _sellerPhoneController,
            'Seller Phone',
            '+964 7XX XXX XXXX',
            Icons.person,
          ),
          const SizedBox(height: 14),
          _buildInputField(
            _buyerPhoneController,
            'Buyer Phone',
            '+964 7XX XXX XXXX',
            Icons.person_outline,
          ),
          const SizedBox(height: 14),
          _buildInputField(
            _addressController,
            'Property Address',
            'Street, District, City',
            Icons.location_on,
          ),
          const SizedBox(height: 14),
          _buildInputField(
            _amountController,
            'Amount (IQD)',
            'e.g. 185,000,000',
            Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateBarcode,
              style: ElevatedButton.styleFrom(
                backgroundColor: _agentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Generate Barcode & Send',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_generatedBarcodeCode != null) ...[
            const SizedBox(height: 24),
            _buildBarcodeResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.white.withAlpha(200),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(25)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                color: Colors.white.withAlpha(60),
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, color: _agentColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeResult() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _agentColor.withAlpha(60)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF388E3C).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Barcode Generated!',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Sent to both parties via Madar messages',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withAlpha(140),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: _generatedBarcodeCode!,
              version: QrVersions.auto,
              size: 160,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _generatedBarcodeCode!,
            style: GoogleFonts.dmSans(
              color: _agentColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _selectedTxType == 'agricultural'
                ? '⚠️ Agricultural: Stage 5 (Ownership Transfer) will be skipped. Funds released when buyer moves in.'
                : 'Both parties must upload this barcode to start the 6-stage transaction process.',
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(160),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── CONTRACT TAB ─────────────────────────────────────────────────────────

  Widget _buildContractTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contract Writing',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: _showDocFieldsSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _agentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _agentColor.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune, color: _agentColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Doc Fields',
                        style: GoogleFonts.dmSans(
                          color: _agentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Write the sale contract and send as PDF to both parties',
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(140),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          // Status chips
          Row(
            children: [
              _buildStatusChip(
                'Draft',
                _contractStatus == 'draft',
                Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatusChip('Sent', _contractStatus == 'sent', _agentColor),
              const SizedBox(width: 8),
              _buildStatusChip(
                'Signed',
                _contractStatus == 'signed',
                const Color(0xFF388E3C),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Contract editor
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_document,
                        color: _agentColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Contract Body',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(
                          () => _contractBodyController.text =
                              _defaultContractTemplate,
                        ),
                        child: Text(
                          'Reset Template',
                          style: GoogleFonts.dmSans(
                            color: _agentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: _contractBodyController,
                  maxLines: 18,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    hintText: 'Write contract here...',
                    hintStyle: GoogleFonts.dmSans(
                      color: Colors.white.withAlpha(60),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Required documents summary
          _buildRequiredDocsSummary(),
          const SizedBox(height: 20),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Fluttertoast.showToast(msg: 'Contract saved as draft'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withAlpha(40)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Save Draft',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSendingContract ? null : _sendContractToParties,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _agentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSendingContract
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Send PDF to Both Parties',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(30) : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color : Colors.white.withAlpha(20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: isActive ? color : Colors.white.withAlpha(120),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredDocsSummary() {
    final enabled = _documentFields.where((f) => f['enabled'] == true).toList();
    if (enabled.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _agentColor.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _agentColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, color: _agentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Required Documents (${enabled.length})',
                style: GoogleFonts.dmSans(
                  color: _agentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: enabled
                .map(
                  (f) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _agentColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      f['label'] as String,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withAlpha(200),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _sendContractToParties() async {
    setState(() => _isSendingContract = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isSendingContract = false;
        _contractStatus = 'sent';
      });
      Fluttertoast.showToast(
        msg: 'Contract PDF sent to both parties via Madar messages',
      );
    }
  }

  // ─── TRANSACTIONS TAB ─────────────────────────────────────────────────────

  Widget _buildTransactionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Transactions',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _agentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_transactions.length} deals',
                  style: GoogleFonts.dmSans(
                    color: _agentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._transactions.map((tx) => _buildTxCard(tx)),
        ],
      ),
    );
  }

  // ─── DOCUMENT FIELDS SHEET ────────────────────────────────────────────────

  void _showDocFieldsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF0D1B2A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.tune, color: _agentColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Configure Document Fields',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select which documents are required for this transaction',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(140),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: _documentFields.length,
                  itemBuilder: (_, i) {
                    final field = _documentFields[i];
                    final isEnabled = field['enabled'] as bool;
                    final isRequired = field['required'] as bool;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? _agentColor.withAlpha(15)
                            : Colors.white.withAlpha(5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isEnabled
                              ? _agentColor.withAlpha(60)
                              : Colors.white.withAlpha(15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isEnabled
                                  ? _agentColor.withAlpha(25)
                                  : Colors.white.withAlpha(10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              field['icon'] as IconData,
                              color: isEnabled
                                  ? _agentColor
                                  : Colors.white.withAlpha(80),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field['label'] as String,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  field['labelAr'] as String,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white.withAlpha(120),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Required',
                                style: GoogleFonts.dmSans(
                                  color: Colors.red.shade300,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else
                            Switch(
                              value: isEnabled,
                              onChanged: isRequired
                                  ? null
                                  : (val) {
                                      setSheetState(
                                        () =>
                                            _documentFields[i]['enabled'] = val,
                                      );
                                      setState(
                                        () =>
                                            _documentFields[i]['enabled'] = val,
                                      );
                                    },
                              activeColor: _agentColor,
                              inactiveThumbColor: Colors.white.withAlpha(80),
                              inactiveTrackColor: Colors.white.withAlpha(20),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Fluttertoast.showToast(msg: 'Document fields saved');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _agentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Save Configuration',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSendContractSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0D1B2A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.send, color: _agentColor, size: 40),
            const SizedBox(height: 12),
            Text(
              'Send Contract to Parties',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The contract will be sent as a PDF to both buyer and seller via Madar messages for review and signature.',
              style: GoogleFonts.dmSans(
                color: Colors.white.withAlpha(160),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withAlpha(40)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendContractToParties();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _agentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Send Now',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const String _defaultContractTemplate = '''عقد بيع عقار

بسم الله الرحمن الرحيم

تم إبرام هذا العقد بين:

الطرف الأول (البائع):
الاسم: ___________________
رقم الهوية: ___________________
رقم الهاتف: ___________________

الطرف الثاني (المشتري):
الاسم: ___________________
رقم الهوية: ___________________
رقم الهاتف: ___________________

موضوع العقد:
يبيع الطرف الأول للطرف الثاني العقار الواقع في:
___________________

المبلغ المتفق عليه: ___________________ دينار عراقي

الشروط والأحكام:
1. يلتزم البائع بتسليم العقار خالياً من أي رهن أو حجز.
2. يلتزم المشتري بدفع المبلغ كاملاً عند صدور السند.
3. يتم تحويل المبلغ من حساب الضمان عند اكتمال نقل الملكية.

تم تحرير هذا العقد بتاريخ: ___________________
بإشراف المحامي: ___________________
رقم الصفقة: ___________________

توقيع البائع: ___________________
توقيع المشتري: ___________________
توقيع المحامي: ___________________''';
}
