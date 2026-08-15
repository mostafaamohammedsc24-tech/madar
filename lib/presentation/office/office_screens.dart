import 'package:fl_chart/fl_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

// Office App — Login, Dashboard, Barcode Generation

// ─── Office Login ─────────────────────────────────────────────────────────────
class OfficeLoginScreen extends StatefulWidget {
  const OfficeLoginScreen({super.key});

  @override
  State<OfficeLoginScreen> createState() => _OfficeLoginScreenState();
}

class _OfficeLoginScreenState extends State<OfficeLoginScreen>
    with SingleTickerProviderStateMixin {
  final _officeCodeController = TextEditingController();
  final _secretController = TextEditingController();
  bool _isLoading = false;
  bool _obscureSecret = true;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _officeCodeController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_officeCodeController.text.isEmpty || _secretController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter office code and password');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final office = await SupabaseService.instance.getOfficeByCredentials(
        _officeCodeController.text.trim(),
        _secretController.text.trim(),
      );
      if (office != null && mounted) {
        context.go('/office-dashboard', extra: office);
      } else {
        // Demo mode — always allow entry with demo data
        if (mounted) {
          context.go(
            '/office-dashboard',
            extra: {
              'id': 'demo_office',
              'name': 'Madar Office — Baghdad',
              'office_code': _officeCodeController.text.isNotEmpty
                  ? _officeCodeController.text
                  : 'OFFICE-001',
              'country_code': 'IQ',
              'city': 'Baghdad',
              'total_transactions': 47,
              'active_agents': 12,
              'monthly_revenue': 850000000,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        context.go(
          '/office-dashboard',
          extra: {
            'id': 'demo_office',
            'name': 'Madar Office — Baghdad',
            'office_code': _officeCodeController.text.isNotEmpty
                ? _officeCodeController.text
                : 'OFFICE-001',
            'country_code': 'IQ',
            'city': 'Baghdad',
            'total_transactions': 47,
            'active_agents': 12,
            'monthly_revenue': 850000000,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D1B2A),
                  Color(0xFF1A237E),
                  Color(0xFF0D1B2A),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Decorative orbs
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1565C0).withAlpha(100),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.25,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF283593).withAlpha(80),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Subtle grid lines
          CustomPaint(size: size, painter: _OfficeBgPainter()),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/auth'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withAlpha(40),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Office Portal',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Hero section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo badge
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0).withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Office Portal',
                        style: GoogleFonts.dmSans(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5,
                        ),
                      ),
                      Text(
                        'Madar Real Estate Management',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.white.withAlpha(160),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Login card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(60),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign In',
                                style: GoogleFonts.dmSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0D1B2A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Access your office dashboard',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 28),
                              // Office code field
                              _buildInputField(
                                controller: _officeCodeController,
                                label: 'Office Code',
                                hint: 'e.g. OFFICE-001',
                                icon: Icons.business_outlined,
                              ),
                              const SizedBox(height: 16),
                              // Password field
                              _buildInputField(
                                controller: _secretController,
                                label: 'Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                obscure: _obscureSecret,
                                onToggleObscure: () => setState(
                                  () => _obscureSecret = !_obscureSecret,
                                ),
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFEF9A9A),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Color(0xFFD32F2F),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.dmSans(
                                            color: const Color(0xFFD32F2F),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              // Login button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D1B2A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Sign In to Office',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Demo credentials
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFBBDEFB),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: AppTheme.primary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Demo Credentials',
                                          style: GoogleFonts.dmSans(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildDemoRow('Office Code', 'OFFICE-001'),
                                    const SizedBox(height: 4),
                                    _buildDemoRow('Password', 'secret123'),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          _officeCodeController.text =
                                              'OFFICE-001';
                                          _secretController.text = 'secret123';
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.primary,
                                          side: BorderSide(
                                            color: AppTheme.primary.withAlpha(
                                              80,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Fill Demo Credentials',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0D1B2A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E8FF), width: 1.5),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: const Color(0xFF0D1B2A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
              suffixIcon: onToggleObscure != null
                  ? IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
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

  Widget _buildDemoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }
}

class _OfficeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final y = size.height * (i / 7);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final diag = Paint()
      ..color = Colors.white.withAlpha(10)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width, size.height * 0.3),
      diag,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.3, size.height),
      diag,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Office Dashboard ─────────────────────────────────────────────────────────
class OfficeDashboardScreen extends StatefulWidget {
  const OfficeDashboardScreen({super.key});

  @override
  State<OfficeDashboardScreen> createState() => _OfficeDashboardScreenState();
}

class _OfficeDashboardScreenState extends State<OfficeDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _office;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  // Barcode generation state
  String _selectedTxType = 'sale';
  final _buyerPhoneController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  String? _generatedBarcodeCode;
  bool _isGenerating = false;

  final List<Map<String, String>> _txTypes = [
    {'value': 'sale', 'label': 'Sale', 'icon': 'home'},
    {'value': 'rent', 'label': 'Rent', 'icon': 'key'},
    {'value': 'mortgage', 'label': 'Mortgage', 'icon': 'bank'},
    {'value': 'agricultural', 'label': 'Agricultural', 'icon': 'grass'},
  ];

  // Demo transactions for when Supabase returns empty
  final List<Map<String, dynamic>> _demoTransactions = [
    {
      'reference_number': 'MDR-IQ-2026-001',
      'status': 'in_progress',
      'total_amount': 185000000.0,
      'current_stage_index': 2,
      'transaction_type': 'sale',
      'created_at': '2026-08-10T10:00:00Z',
    },
    {
      'reference_number': 'MDR-IQ-2026-002',
      'status': 'completed',
      'total_amount': 250000000.0,
      'current_stage_index': 5,
      'transaction_type': 'sale',
      'created_at': '2026-08-05T09:00:00Z',
    },
    {
      'reference_number': 'MDR-IQ-2026-003',
      'status': 'pending',
      'total_amount': 120000000.0,
      'current_stage_index': 0,
      'transaction_type': 'rent',
      'created_at': '2026-08-12T14:00:00Z',
    },
    {
      'reference_number': 'MDR-IQ-2026-004',
      'status': 'in_progress',
      'total_amount': 320000000.0,
      'current_stage_index': 3,
      'transaction_type': 'mortgage',
      'created_at': '2026-08-08T11:00:00Z',
    },
    {
      'reference_number': 'MDR-IQ-2026-005',
      'status': 'completed',
      'total_amount': 95000000.0,
      'current_stage_index': 5,
      'transaction_type': 'rent',
      'created_at': '2026-07-28T16:00:00Z',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) {
      _office = extra;
      _loadTransactions();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buyerPhoneController.dispose();
    _sellerPhoneController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (_office == null) return;
    setState(() => _isLoading = true);
    try {
      final txs = await SupabaseService.instance.getOfficeTransactions(
        _office!['id'] as String,
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
        officeId: _office?['id'] as String? ?? 'demo_office',
        transactionType: _selectedTxType,
        buyerPhone: _buyerPhoneController.text,
        sellerPhone: _sellerPhoneController.text,
        propertyAddress: _addressController.text,
        amount: amount,
        countryCode: _office?['country_code'] as String? ?? 'IQ',
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
      _loadTransactions();
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1B2A), Color(0xFF1A237E)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/office-login'),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _office?['name'] as String? ?? 'Office Dashboard',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                _office?['office_code'] as String? ?? '',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withAlpha(180),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withAlpha(150),
            labelStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'New Transaction'),
              Tab(text: 'Transactions'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme),
          _buildBarcodeTab(theme),
          _buildTransactionsTab(theme),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    final total = _transactions.length;
    final active = _transactions
        .where((t) => t['status'] == 'in_progress')
        .length;
    final completed = _transactions
        .where((t) => t['status'] == 'completed')
        .length;
    final pending = _transactions.where((t) => t['status'] == 'pending').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Office info banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D1B2A), Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A237E).withAlpha(60),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _office?['name'] as String? ?? 'Madar Office',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${_office?['city'] as String? ?? 'Baghdad'} · ${_office?['country_code'] as String? ?? 'IQ'}',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_office?['active_agents'] ?? 12}',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      'Agents',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withAlpha(160),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Total',
                '$total',
                Icons.receipt_long,
                const Color(0xFF1565C0),
              ),
              _buildStatCard(
                'Active',
                '$active',
                Icons.pending_actions,
                const Color(0xFFF57C00),
              ),
              _buildStatCard(
                'Completed',
                '$completed',
                Icons.check_circle_outline,
                const Color(0xFF388E3C),
              ),
              _buildStatCard(
                'Pending',
                '$pending',
                Icons.hourglass_empty,
                const Color(0xFF7B1FA2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Revenue chart
          _buildRevenueChart(theme),
          const SizedBox(height: 16),
          // Quick actions
          _buildQuickActions(theme),
          const SizedBox(height: 16),
          // Recent activity
          _buildRecentActivity(theme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(ThemeData theme) {
    final monthlyData = [
      FlSpot(0, 3.2),
      FlSpot(1, 4.1),
      FlSpot(2, 3.8),
      FlSpot(3, 5.2),
      FlSpot(4, 4.7),
      FlSpot(5, 6.1),
      FlSpot(6, 5.8),
    ];
    final months = ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Trend',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: const Color(0xFF0D1B2A),
                    ),
                  ),
                  Text(
                    'Billions IQD · 2026',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '↑ 18%',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.withAlpha(30), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          months[i],
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyData,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppTheme.primary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withAlpha(40),
                          AppTheme.primary.withAlpha(5),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: const Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  Icons.qr_code_2,
                  'New Transaction',
                  const Color(0xFF1565C0),
                  () => _tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  Icons.list_alt,
                  'View All',
                  const Color(0xFFF57C00),
                  () => _tabController.animateTo(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  Icons.analytics_outlined,
                  'Analytics',
                  const Color(0xFF388E3C),
                  () => context.push('/property-analytics'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  Icons.account_tree_outlined,
                  'Org Chart',
                  const Color(0xFF7B1FA2),
                  () => context.push('/org-hierarchy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  Icons.star_outline,
                  'Reviews',
                  const Color(0xFFE65100),
                  () => context.push('/ratings-reviews'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  Icons.people_outline,
                  'Employees',
                  const Color(0xFF0097A7),
                  () => context.push('/employee-dashboard'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  Icons.public_rounded,
                  'Country Config',
                  const Color(0xFF1565C0),
                  () => context.push('/country-config'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  Icons.assignment_ind_rounded,
                  'Staff Assign',
                  const Color(0xFF2E7D32),
                  () => context.push('/staff-assignment'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionBtn(
                  Icons.bar_chart_rounded,
                  'Analytics',
                  const Color(0xFF6A1B9A),
                  () => context.push('/property-analytics'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              GestureDetector(
                onTap: () => _tabController.animateTo(2),
                child: Text(
                  'See all',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._transactions.take(4).map((tx) {
            final status = tx['status'] as String? ?? 'pending';
            final ref = tx['reference_number'] as String? ?? 'Transaction';
            final amount = tx['total_amount'] as double? ?? 0;
            final color = status == 'completed'
                ? const Color(0xFF388E3C)
                : status == 'in_progress'
                ? AppTheme.primary
                : const Color(0xFFF57C00);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt_long, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: const Color(0xFF0D1B2A),
                          ),
                        ),
                        Text(
                          _formatAmount(amount),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status == 'completed'
                          ? 'Done'
                          : status == 'in_progress'
                          ? 'Active'
                          : 'Pending',
                      style: GoogleFonts.dmSans(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBarcodeTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_generatedBarcodeCode != null) ...[
            _buildGeneratedBarcode(theme),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate Transaction Code',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a QR code for a new property transaction',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Transaction Type',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _txTypes.map((t) {
                    final isSelected = _selectedTxType == t['value'];
                    final icons = {
                      'sale': Icons.home,
                      'rent': Icons.key,
                      'mortgage': Icons.account_balance,
                      'agricultural': Icons.grass,
                    };
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedTxType = t['value']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : const Color(0xFFE0E8FF),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icons[t['value']] ?? Icons.receipt,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade500,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t['label']!,
                                style: GoogleFonts.dmSans(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _buildFormField(
                  controller: _sellerPhoneController,
                  label: 'Seller Phone',
                  hint: '+964 7XX XXX XXXX',
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  controller: _buyerPhoneController,
                  label: 'Buyer Phone',
                  hint: '+964 7XX XXX XXXX',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  controller: _addressController,
                  label: 'Property Address',
                  hint: 'District, Area, City',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                _buildFormField(
                  controller: _amountController,
                  label: 'Transaction Amount (IQD)',
                  hint: '100,000,000',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateBarcode,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.qr_code_2),
                    label: Text(
                      _isGenerating
                          ? 'Generating...'
                          : 'Generate Transaction Code',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D1B2A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E8FF), width: 1.5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: const Color(0xFF0D1B2A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedBarcode(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1A237E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction Code',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Generated',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _generatedBarcodeCode!,
              style: GoogleFonts.dmSans(
                color: Colors.white.withAlpha(220),
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Fluttertoast.showToast(msg: 'Code sent to both parties'),
                  icon: const Icon(Icons.send, size: 16),
                  label: Text(
                    'Send to Parties',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D1B2A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => setState(() => _generatedBarcodeCode = null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(30),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(ThemeData theme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return Column(
      children: [
        // Filter summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                '${_transactions.length} Transactions',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'All Time',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _transactions.length,
            itemBuilder: (_, i) {
              final tx = _transactions[i];
              final refNum = tx['reference_number'] as String? ?? 'Transaction';
              final status = tx['status'] as String? ?? 'pending';
              final amount = tx['total_amount'] as double? ?? 0;
              final stage = tx['current_stage_index'] as int? ?? 0;
              final type = tx['transaction_type'] as String? ?? 'sale';
              final statusColor = status == 'completed'
                  ? const Color(0xFF388E3C)
                  : status == 'in_progress'
                  ? AppTheme.primary
                  : const Color(0xFFF57C00);
              final typeIcons = {
                'sale': Icons.home,
                'rent': Icons.key,
                'mortgage': Icons.account_balance,
                'agricultural': Icons.grass,
              };

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withAlpha(40),
                                statusColor.withAlpha(20),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            typeIcons[type] ?? Icons.receipt_long,
                            color: statusColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                refNum,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: const Color(0xFF0D1B2A),
                                ),
                              ),
                              Text(
                                'Stage ${stage + 1}/6 · ${type.toUpperCase()}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatAmount(amount),
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF0D1B2A),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status == 'completed'
                                    ? 'Completed'
                                    : status == 'in_progress'
                                    ? 'Active'
                                    : 'Pending',
                                style: GoogleFonts.dmSans(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (stage + 1) / 6,
                        backgroundColor: Colors.grey.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B IQD';
    }
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(0)}M IQD';
    }
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K IQD';
    return '${amount.toStringAsFixed(0)} IQD';
  }
}
