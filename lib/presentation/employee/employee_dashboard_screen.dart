import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../core/services/ai_client.dart';
import '../../services/supabase_service.dart';

enum EmployeeRole {
  callCenter,
  publishingManager,
  photographer,
  propertyInfoSpecialist,
  transactionCoordinator,
  lawyer,
  bankEscrowOfficer,
  financeOfficer,
  propertyManager,
  customerSupport,
  riskAnalyst,
  marketingSpecialist,
  visitManager,
  networkExpansion,
  executive,
}

class EmployeeDashboardScreen extends ConsumerStatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  ConsumerState<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState
    extends ConsumerState<EmployeeDashboardScreen>
    with SingleTickerProviderStateMixin {
  EmployeeRole _currentRole = EmployeeRole.transactionCoordinator;
  bool _showAiChat = false;
  bool _showRoleSwitcher = false;
  final _aiChatController = TextEditingController();
  final List<Map<String, String>> _aiMessages = [];
  bool _isAiTyping = false;
  late TabController _tabController;
  Map<String, dynamic>? _employeeData;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  static const _aiConfig = ChatConfig(
    provider: 'GEMINI',
    model: 'gemini/gemini-2.5-flash',
    streaming: true,
  );

  final List<Map<String, dynamic>> _demoTasks = [
    {
      'action_type': 'Document Review',
      'notes': 'Review contract for MADAR-IQ-2026-001',
      'status': 'pending',
      'priority': 'high',
    },
    {
      'action_type': 'Client Follow-up',
      'notes': 'Call buyer for property inspection confirmation',
      'status': 'pending',
      'priority': 'medium',
    },
    {
      'action_type': 'Photo Upload',
      'notes': 'Upload property photos for listing #4521',
      'status': 'in_progress',
      'priority': 'high',
    },
    {
      'action_type': 'Legal Verification',
      'notes': 'Verify ownership documents for Karrada property',
      'status': 'pending',
      'priority': 'low',
    },
  ];

  final List<Map<String, dynamic>> _demoTransactions = [
    {
      'reference_number': 'MDR-IQ-2026-001',
      'status': 'in_progress',
      'total_amount': 185000000.0,
      'current_stage_index': 2,
    },
    {
      'reference_number': 'MDR-IQ-2026-002',
      'status': 'completed',
      'total_amount': 250000000.0,
      'current_stage_index': 5,
    },
    {
      'reference_number': 'MDR-IQ-2026-003',
      'status': 'pending',
      'total_amount': 120000000.0,
      'current_stage_index': 0,
    },
  ];

  final Map<EmployeeRole, Map<String, dynamic>> _roleConfig = {
    EmployeeRole.callCenter: {
      'title': 'Call Center Agent',
      'titleAr': 'موظف الاتصالات',
      'icon': Icons.call,
      'color': 0xFF1565C0,
      'dept': 'Support',
    },
    EmployeeRole.publishingManager: {
      'title': 'Publishing Manager',
      'titleAr': 'مدير النشر',
      'icon': Icons.campaign,
      'color': 0xFF388E3C,
      'dept': 'Marketing',
    },
    EmployeeRole.photographer: {
      'title': 'Photographer',
      'titleAr': 'مصور',
      'icon': Icons.camera_alt,
      'color': 0xFF7B1FA2,
      'dept': 'Media',
    },
    EmployeeRole.propertyInfoSpecialist: {
      'title': 'Property Info Specialist',
      'titleAr': 'أخصائي معلومات العقارات',
      'icon': Icons.home_work,
      'color': 0xFFF57C00,
      'dept': 'Operations',
    },
    EmployeeRole.transactionCoordinator: {
      'title': 'Transaction Coordinator',
      'titleAr': 'منسق الصفقات',
      'icon': Icons.handshake,
      'color': 0xFF00897B,
      'dept': 'Transactions',
    },
    EmployeeRole.lawyer: {
      'title': 'Lawyer / Legal',
      'titleAr': 'محامي / قانوني',
      'icon': Icons.gavel,
      'color': 0xFF1565C0,
      'dept': 'Legal',
    },
    EmployeeRole.bankEscrowOfficer: {
      'title': 'Bank / Escrow Officer',
      'titleAr': 'موظف المصرف',
      'icon': Icons.account_balance,
      'color': 0xFF388E3C,
      'dept': 'Finance',
    },
    EmployeeRole.financeOfficer: {
      'title': 'Finance Officer',
      'titleAr': 'موظف المالية',
      'icon': Icons.attach_money,
      'color': 0xFFF57C00,
      'dept': 'Finance',
    },
    EmployeeRole.propertyManager: {
      'title': 'Property Manager',
      'titleAr': 'مدير العقارات',
      'icon': Icons.apartment,
      'color': 0xFF7B1FA2,
      'dept': 'Operations',
    },
    EmployeeRole.customerSupport: {
      'title': 'Customer Support',
      'titleAr': 'دعم العملاء',
      'icon': Icons.headset_mic,
      'color': 0xFF00897B,
      'dept': 'Support',
    },
    EmployeeRole.riskAnalyst: {
      'title': 'Risk Analyst',
      'titleAr': 'محلل المخاطر',
      'icon': Icons.security,
      'color': 0xFFD32F2F,
      'dept': 'Risk',
    },
    EmployeeRole.marketingSpecialist: {
      'title': 'Marketing Specialist',
      'titleAr': 'أخصائي تسويق',
      'icon': Icons.trending_up,
      'color': 0xFFE91E63,
      'dept': 'Marketing',
    },
    EmployeeRole.visitManager: {
      'title': 'Visit Manager',
      'titleAr': 'مدير الزيارات',
      'icon': Icons.key,
      'color': 0xFF795548,
      'dept': 'Operations',
    },
    EmployeeRole.networkExpansion: {
      'title': 'Network Expansion',
      'titleAr': 'توسعة الشبكة',
      'icon': Icons.hub,
      'color': 0xFF0097A7,
      'dept': 'Growth',
    },
    EmployeeRole.executive: {
      'title': 'Executive',
      'titleAr': 'تنفيذي',
      'icon': Icons.workspace_premium,
      'color': 0xFF37474F,
      'dept': 'Management',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) {
      _employeeData = extra;
      final roleStr = extra['role'] as String? ?? 'transactionCoordinator';
      _currentRole = _parseRole(roleStr);
    }
  }

  EmployeeRole _parseRole(String role) {
    switch (role) {
      case 'call_center':
        return EmployeeRole.callCenter;
      case 'publishing_manager':
        return EmployeeRole.publishingManager;
      case 'photographer':
        return EmployeeRole.photographer;
      case 'property_info_specialist':
        return EmployeeRole.propertyInfoSpecialist;
      case 'transaction_coordinator':
        return EmployeeRole.transactionCoordinator;
      case 'lawyer':
        return EmployeeRole.lawyer;
      case 'bank_escrow_officer':
        return EmployeeRole.bankEscrowOfficer;
      case 'finance_officer':
        return EmployeeRole.financeOfficer;
      case 'property_manager':
        return EmployeeRole.propertyManager;
      case 'customer_support':
        return EmployeeRole.customerSupport;
      case 'risk_analyst':
        return EmployeeRole.riskAnalyst;
      case 'marketing_specialist':
        return EmployeeRole.marketingSpecialist;
      case 'visit_manager':
        return EmployeeRole.visitManager;
      case 'network_expansion':
        return EmployeeRole.networkExpansion;
      default:
        return EmployeeRole.executive;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final empId = _employeeData?['id'] as String? ?? 'demo';
      final tasks = await SupabaseService.instance.getEmployeeTasks(empId);
      final txs = await SupabaseService.instance.getEmployeeTransactions(
        empId,
        _currentRole.name,
      );
      if (mounted) {
        setState(() {
          _tasks = tasks.isNotEmpty ? tasks : _demoTasks;
          _transactions = txs.isNotEmpty ? txs : _demoTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tasks = _demoTasks;
          _transactions = _demoTransactions;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiChatController.dispose();
    super.dispose();
  }

  Color get _roleColor => Color(_roleConfig[_currentRole]!['color'] as int);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleData = _roleConfig[_currentRole]!;
    final color = _roleColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          // Background gradient
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
          // Decorative orb
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withAlpha(60), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(theme, roleData, color),
                _buildTabBar(color),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDashboardTab(theme, roleData, color),
                      _buildTasksTab(theme, color),
                      _buildTransactionsTab(theme, color),
                      _buildProfileTab(theme, roleData, color),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showRoleSwitcher) _buildRoleSwitcherOverlay(theme),
          if (_showAiChat) _buildAiChatOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    Map<String, dynamic> roleData,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/auth'),
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
              gradient: LinearGradient(
                colors: [color, color.withAlpha(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              roleData['icon'] as IconData,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _employeeData?['full_name'] as String? ?? 'Madar Employee',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  roleData['title'] as String,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(160),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showRoleSwitcher = !_showRoleSwitcher),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, color: color, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Role',
                    style: GoogleFonts.dmSans(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showAiChat = !_showAiChat),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(30)),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color color) {
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
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(80),
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
          Tab(text: 'Dashboard'),
          Tab(text: 'Tasks'),
          Tab(text: 'Deals'),
          Tab(text: 'Profile'),
        ],
      ),
    );
  }

  // ─── DASHBOARD TAB ────────────────────────────────────────────────────────

  Widget _buildDashboardTab(
    ThemeData theme,
    Map<String, dynamic> roleData,
    Color color,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          _buildWelcomeBanner(color, roleData),
          const SizedBox(height: 16),
          _buildKpiRow(color),
          const SizedBox(height: 16),
          _buildActivityChart(color),
          const SizedBox(height: 16),
          _buildRoleSpecificSection(theme, color),
          const SizedBox(height: 16),
          _buildQuickActionsGrid(color),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(Color color, Map<String, dynamic> roleData) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(200), color.withAlpha(120)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
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
                  greeting,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _employeeData?['full_name'] as String? ?? 'Madar Employee',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _employeeData?['employee_code'] as String? ?? 'EMP-001',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
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
                            'Active',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(50)),
            ),
            child: Icon(
              roleData['icon'] as IconData,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(Color color) {
    final kpis = _getKpisForRole(_currentRole);
    return Row(
      children: kpis.take(4).map((kpi) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Column(
              children: [
                Icon(kpi['icon'] as IconData, color: color, size: 20),
                const SizedBox(height: 6),
                Text(
                  kpi['value'] as String,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  kpi['label'] as String,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(120),
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityChart(Color color) {
    final spots = [
      FlSpot(0, 2),
      FlSpot(1, 3.5),
      FlSpot(2, 2.8),
      FlSpot(3, 4.2),
      FlSpot(4, 3.9),
      FlSpot(5, 5.1),
      FlSpot(6, 4.7),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
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
                    'Activity Overview',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Last 7 days',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withAlpha(120),
                      fontSize: 11,
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
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '↑ 23%',
                  style: GoogleFonts.dmSans(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [color.withAlpha(50), color.withAlpha(5)],
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

  Widget _buildQuickActionsGrid(Color color) {
    final actions = _getQuickActionsForRole(_currentRole);
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
              onTap: a['onTap'] as VoidCallback? ?? () {},
              child: Container(
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withAlpha(40)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(a['icon'] as IconData, color: color, size: 24),
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

  List<Map<String, dynamic>> _getQuickActionsForRole(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.lawyer:
        return [
          {
            'icon': Icons.edit_document,
            'label': 'Write Contract',
            'onTap': () => context.go('/agent-dashboard'),
          },
          {'icon': Icons.send, 'label': 'Send to Parties', 'onTap': () {}},
          {'icon': Icons.verified_user, 'label': 'Verify ID', 'onTap': () {}},
          {
            'icon': Icons.receipt_long,
            'label': 'View Deals',
            'onTap': () => _tabController.animateTo(2),
          },
          {
            'icon': Icons.task_alt,
            'label': 'My Tasks',
            'onTap': () => _tabController.animateTo(1),
          },
          {'icon': Icons.chat, 'label': 'Messages', 'onTap': () {}},
        ];
      case EmployeeRole.bankEscrowOfficer:
        return [
          {'icon': Icons.savings, 'label': 'Escrow Accounts', 'onTap': () {}},
          {
            'icon': Icons.check_circle,
            'label': 'Confirm Deposit',
            'onTap': () {},
          },
          {'icon': Icons.receipt, 'label': 'Generate Receipt', 'onTap': () {}},
          {
            'icon': Icons.transfer_within_a_station,
            'label': 'Transfer Funds',
            'onTap': () {},
          },
          {
            'icon': Icons.history,
            'label': 'History',
            'onTap': () => _tabController.animateTo(2),
          },
          {'icon': Icons.bar_chart, 'label': 'Reports', 'onTap': () {}},
        ];
      case EmployeeRole.financeOfficer:
        return [
          {'icon': Icons.calculate, 'label': 'Calculate Fees', 'onTap': () {}},
          {
            'icon': Icons.receipt_long,
            'label': 'Issue Receipt',
            'onTap': () {},
          },
          {'icon': Icons.percent, 'label': 'Commission', 'onTap': () {}},
          {
            'icon': Icons.account_balance_wallet,
            'label': 'Payments',
            'onTap': () {},
          },
          {'icon': Icons.bar_chart, 'label': 'Analytics', 'onTap': () {}},
          {
            'icon': Icons.task_alt,
            'label': 'Tasks',
            'onTap': () => _tabController.animateTo(1),
          },
        ];
      default:
        return [
          {
            'icon': Icons.add_task,
            'label': 'New Task',
            'onTap': () => _tabController.animateTo(1),
          },
          {
            'icon': Icons.receipt_long,
            'label': 'Transactions',
            'onTap': () => _tabController.animateTo(2),
          },
          {
            'icon': Icons.notifications,
            'label': 'Notifications',
            'onTap': () {},
          },
          {'icon': Icons.chat, 'label': 'Messages', 'onTap': () {}},
          {
            'icon': Icons.account_tree_outlined,
            'label': 'Org Chart',
            'onTap': () => context.push('/org-hierarchy'),
          },
          {
            'icon': Icons.analytics_outlined,
            'label': 'Analytics',
            'onTap': () => context.push('/property-analytics'),
          },
          {
            'icon': Icons.star_outline,
            'label': 'Reviews',
            'onTap': () => context.push('/ratings-reviews'),
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getKpisForRole(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.callCenter:
        return [
          {'icon': Icons.call, 'label': 'Calls Today', 'value': '24'},
          {'icon': Icons.check_circle, 'label': 'Resolved', 'value': '18'},
          {'icon': Icons.pending, 'label': 'Pending', 'value': '6'},
          {'icon': Icons.star, 'label': 'Rating', 'value': '4.8'},
        ];
      case EmployeeRole.transactionCoordinator:
        return [
          {
            'icon': Icons.receipt_long,
            'label': 'Active Deals',
            'value': '${_transactions.length}',
          },
          {
            'icon': Icons.pending_actions,
            'label': 'Tasks',
            'value': '${_tasks.length}',
          },
          {'icon': Icons.check_circle, 'label': 'Done', 'value': '12'},
          {'icon': Icons.trending_up, 'label': 'Month', 'value': '5'},
        ];
      case EmployeeRole.lawyer:
        return [
          {'icon': Icons.gavel, 'label': 'Contracts', 'value': '8'},
          {'icon': Icons.draw, 'label': 'Awaiting Sig', 'value': '3'},
          {'icon': Icons.check_circle, 'label': 'Signed', 'value': '45'},
          {'icon': Icons.schedule, 'label': 'Meetings', 'value': '2'},
        ];
      case EmployeeRole.bankEscrowOfficer:
        return [
          {'icon': Icons.savings, 'label': 'Escrow', 'value': '12'},
          {'icon': Icons.pending, 'label': 'Pending', 'value': '4'},
          {'icon': Icons.check_circle, 'label': 'Confirmed', 'value': '38'},
          {'icon': Icons.attach_money, 'label': 'Total B', 'value': '2.4'},
        ];
      case EmployeeRole.financeOfficer:
        return [
          {'icon': Icons.receipt, 'label': 'Receipts', 'value': '34'},
          {'icon': Icons.percent, 'label': 'Commission', 'value': '1%'},
          {
            'icon': Icons.account_balance_wallet,
            'label': 'Collected',
            'value': '18M',
          },
          {'icon': Icons.pending, 'label': 'Pending', 'value': '7'},
        ];
      case EmployeeRole.photographer:
        return [
          {'icon': Icons.camera_alt, 'label': 'Sessions', 'value': '3'},
          {'icon': Icons.photo_library, 'label': 'Photos', 'value': '156'},
          {'icon': Icons.pending, 'label': 'Requests', 'value': '7'},
          {'icon': Icons.check_circle, 'label': 'Done', 'value': '89'},
        ];
      default:
        return [
          {'icon': Icons.task, 'label': 'Tasks', 'value': '${_tasks.length}'},
          {
            'icon': Icons.receipt,
            'label': 'Deals',
            'value': '${_transactions.length}',
          },
          {'icon': Icons.check_circle, 'label': 'Done', 'value': '0'},
          {'icon': Icons.trending_up, 'label': 'Month', 'value': '0'},
        ];
    }
  }

  Widget _buildRoleSpecificSection(ThemeData theme, Color color) {
    switch (_currentRole) {
      case EmployeeRole.lawyer:
        return _buildLawyerSection(color);
      case EmployeeRole.bankEscrowOfficer:
        return _buildBankSection(color);
      case EmployeeRole.financeOfficer:
        return _buildFinanceSection(color);
      case EmployeeRole.callCenter:
        return _buildCallCenterSection(color);
      default:
        return _buildGenericSection(color);
    }
  }

  Widget _buildSectionCard({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLawyerSection(Color color) {
    final contracts = [
      {
        'ref': 'MDR-IQ-2026-001',
        'stage': 'Contract Writing',
        'status': 'in_progress',
        'parties': 'أحمد / مريم',
      },
      {
        'ref': 'MDR-IQ-2026-002',
        'stage': 'Awaiting Signature',
        'status': 'pending',
        'parties': 'علي / سارة',
      },
      {
        'ref': 'MDR-IQ-2026-003',
        'stage': 'Ownership Transfer',
        'status': 'in_progress',
        'parties': 'محمد / فاطمة',
      },
    ];
    return _buildSectionCard(
      title: 'Active Contracts',
      color: color,
      children: contracts.map((c) {
        final isActive = c['status'] == 'in_progress';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.gavel, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['ref']!,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${c['stage']} · ${c['parties']}',
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
                  color: isActive
                      ? color.withAlpha(30)
                      : Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Pending',
                  style: GoogleFonts.dmSans(
                    color: isActive ? color : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBankSection(Color color) {
    final accounts = [
      {
        'ref': 'MDR-IQ-2026-001',
        'amount': '185,000,000 IQD',
        'status': 'pending',
      },
      {
        'ref': 'MDR-IQ-2026-004',
        'amount': '320,000,000 IQD',
        'status': 'confirmed',
      },
    ];
    return _buildSectionCard(
      title: 'Escrow Accounts',
      color: color,
      children: accounts.map((a) {
        final isConfirmed = a['status'] == 'confirmed';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.account_balance, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['ref']!,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      a['amount']!,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withAlpha(160),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? const Color(0xFF388E3C).withAlpha(30)
                      : Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isConfirmed ? 'Confirmed' : 'Pending',
                  style: GoogleFonts.dmSans(
                    color: isConfirmed
                        ? const Color(0xFF4CAF50)
                        : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinanceSection(Color color) {
    return _buildSectionCard(
      title: 'Fee Summary',
      color: color,
      children: [
        _buildFeeRow('Commission (1% × 2)', '3,700,000 IQD', color),
        _buildFeeRow('Fixed Fee (300K × 2)', '600,000 IQD', color),
        _buildFeeRow('Taxes', '1,850,000 IQD', color),
        const Divider(color: Colors.white24, height: 20),
        _buildFeeRow(
          'Total Collected',
          '6,150,000 IQD',
          const Color(0xFF4CAF50),
          bold: true,
        ),
      ],
    );
  }

  Widget _buildFeeRow(
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(180),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: bold ? color : Colors.white,
              fontSize: 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallCenterSection(Color color) {
    return _buildSectionCard(
      title: 'Recent Calls',
      color: color,
      children: [
        _buildCallTile('أحمد الراشدي', '+964 770 123 4567', '10:32 AM', color),
        _buildCallTile('سارة محمد', '+964 781 987 6543', '09:15 AM', color),
        _buildCallTile('علي حسين', '+964 750 555 1234', 'Yesterday', color),
      ],
    );
  }

  Widget _buildCallTile(String name, String phone, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  phone,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(140),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(120),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericSection(Color color) {
    return _buildSectionCard(
      title: 'Recent Activity',
      color: color,
      children: _demoTasks.take(3).map((t) {
        final isPending = t['status'] == 'pending';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(30)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPending ? Colors.orange : const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t['notes'] as String,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── TASKS TAB ────────────────────────────────────────────────────────────

  Widget _buildTasksTab(ThemeData theme, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Tasks',
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
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_tasks.length} tasks',
                  style: GoogleFonts.dmSans(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._tasks.map((task) => _buildTaskCard(task, color)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, Color color) {
    final status = task['status'] as String? ?? 'pending';
    final priority = task['priority'] as String? ?? 'medium';
    final priorityColor = priority == 'high'
        ? const Color(0xFFD32F2F)
        : priority == 'medium'
        ? const Color(0xFFF57C00)
        : const Color(0xFF388E3C);
    final isDone = status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? const Color(0xFF388E3C).withAlpha(60)
              : Colors.white.withAlpha(15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF388E3C).withAlpha(25)
                  : color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDone ? Icons.check_circle : Icons.task_alt,
              color: isDone ? const Color(0xFF4CAF50) : color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['action_type'] as String? ?? 'Task',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task['notes'] as String? ?? '',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(140),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: priorityColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withAlpha(160),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TRANSACTIONS TAB ─────────────────────────────────────────────────────

  Widget _buildTransactionsTab(ThemeData theme, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Deals',
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
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_transactions.length} deals',
                  style: GoogleFonts.dmSans(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._transactions.map((tx) => _buildTransactionCard(tx, color)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, Color color) {
    final status = tx['status'] as String? ?? 'pending';
    final ref = tx['reference_number'] as String? ?? 'Transaction';
    final amount = tx['total_amount'] as double? ?? 0;
    final stage = tx['current_stage_index'] as int? ?? 0;
    final statusColor = status == 'completed'
        ? const Color(0xFF4CAF50)
        : status == 'in_progress'
        ? color
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
                      '${(amount / 1000000).toStringAsFixed(1)}M IQD',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withAlpha(160),
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
          const SizedBox(height: 12),
          // Stage progress
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
                        ? color
                        : current
                        ? color.withAlpha(120)
                        : Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            'Stage ${stage + 1}/6: ${stage < stageLabels.length ? stageLabels[stage] : 'Complete'}',
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(120),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROFILE TAB ─────────────────────────────────────────────────────────

  Widget _buildProfileTab(
    ThemeData theme,
    Map<String, dynamic> roleData,
    Color color,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha(180), color.withAlpha(80)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(80),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    roleData['icon'] as IconData,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _employeeData?['full_name'] as String? ?? 'Madar Employee',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                Text(
                  roleData['title'] as String,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(200),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _employeeData?['employee_code'] as String? ?? 'EMP-001',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(160),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Settings
          _buildProfileMenuItem(
            Icons.assignment_ind_outlined,
            'Complete Onboarding',
            color,
            () => context.push('/employee-onboarding', extra: _employeeData),
          ),
          _buildProfileMenuItem(
            Icons.account_tree_outlined,
            'Org Hierarchy',
            color,
            () => context.push('/org-hierarchy'),
          ),
          _buildProfileMenuItem(
            Icons.analytics_outlined,
            'Property Analytics',
            color,
            () => context.push('/property-analytics'),
          ),
          _buildProfileMenuItem(
            Icons.star_outline,
            'Ratings & Reviews',
            color,
            () => context.push('/ratings-reviews'),
          ),
          _buildProfileMenuItem(
            Icons.public_rounded,
            'Country Config',
            color,
            () => context.push('/country-config'),
          ),
          _buildProfileMenuItem(
            Icons.assignment_ind_rounded,
            'Staff Assignment',
            color,
            () => context.push('/staff-assignment'),
          ),
          _buildProfileMenuItem(
            Icons.notifications_outlined,
            'Notifications',
            color,
            () {},
          ),
          _buildProfileMenuItem(
            Icons.lock_outline,
            'Security & 2FA',
            color,
            () => context.go('/two-fa-verification'),
          ),
          _buildProfileMenuItem(Icons.language, 'Language', color, () {}),
          _buildProfileMenuItem(
            Icons.help_outline,
            'Help & Support',
            color,
            () {},
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.go('/auth'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD32F2F).withAlpha(60),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: Color(0xFFEF5350), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFEF5350),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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

  Widget _buildProfileMenuItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Row(
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withAlpha(80),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ─── ROLE SWITCHER OVERLAY ────────────────────────────────────────────────

  Widget _buildRoleSwitcherOverlay(ThemeData theme) {
    final departments = <String, List<EmployeeRole>>{};
    for (final role in EmployeeRole.values) {
      final dept = _roleConfig[role]!['dept'] as String;
      departments.putIfAbsent(dept, () => []).add(role);
    }
    return GestureDetector(
      onTap: () => setState(() => _showRoleSwitcher = false),
      child: Container(
        color: Colors.black.withAlpha(80),
        child: Align(
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 80,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF0D1B2A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'Switch Role',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showRoleSwitcher = false),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
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
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: departments.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Text(
                                  entry.key.toUpperCase(),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withAlpha(120),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: entry.value.map((role) {
                                  final rd = _roleConfig[role]!;
                                  final c = Color(rd['color'] as int);
                                  final isSelected = role == _currentRole;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _currentRole = role;
                                        _showRoleSwitcher = false;
                                      });
                                      _loadData();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected ? c : c.withAlpha(15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? c
                                              : c.withAlpha(60),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            rd['icon'] as IconData,
                                            color: isSelected
                                                ? Colors.white
                                                : c,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            rd['title'] as String,
                                            style: GoogleFonts.dmSans(
                                              color: isSelected
                                                  ? Colors.white
                                                  : c,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 11,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── AI CHAT OVERLAY ──────────────────────────────────────────────────────

  Widget _buildAiChatOverlay(ThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Color(0xFF0D1B2A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border(top: BorderSide(color: Color(0xFF1A237E), width: 1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI Assistant',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showAiChat = false),
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
            Expanded(
              child: _aiMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            color: Colors.white.withAlpha(60),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ask me anything about your work',
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withAlpha(120),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _aiMessages.length,
                      itemBuilder: (_, i) {
                        final msg = _aiMessages[i];
                        final isUser = msg['role'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppTheme.primary
                                  : Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              msg['content'] ?? '',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_isAiTyping)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Thinking...',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withAlpha(160),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: TextField(
                        controller: _aiChatController,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask AI assistant...',
                          hintStyle: GoogleFonts.dmSans(
                            color: Colors.white.withAlpha(80),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: _sendAiMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendAiMessage(_aiChatController.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendAiMessage(String text) async {
    if (text.trim().isEmpty) return;
    _aiChatController.clear();
    setState(() {
      _aiMessages.add({'role': 'user', 'content': text});
      _isAiTyping = true;
    });
    try {
      final aiClient = AiClient();
      final response = await aiClient.chatCompletion(
        config: _aiConfig,
        messages: [
          {
            'role': 'system',
            'content':
                'You are a helpful assistant for Madar Real Estate employees. Role: ${_roleConfig[_currentRole]!['title']}',
          },
          ..._aiMessages,
        ],
      );
      if (mounted) {
        setState(() {
          _aiMessages.add({
            'role': 'assistant',
            'content': response ?? 'I can help you with your work tasks.',
          });
          _isAiTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiMessages.add({
            'role': 'assistant',
            'content': 'I can help you with your work tasks. What do you need?',
          });
          _isAiTyping = false;
        });
      }
    }
  }
}
