import 'package:fl_chart/fl_chart.dart';

import '../../core/app_export.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/supabase_service.dart';

class SellerCommissionDashboard extends StatefulWidget {
  const SellerCommissionDashboard({super.key});

  @override
  State<SellerCommissionDashboard> createState() =>
      _SellerCommissionDashboardState();
}

class _SellerCommissionDashboardState extends State<SellerCommissionDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];

  // Computed stats
  double _totalEarnings = 0;
  double _pendingEarnings = 0;
  double _completedEarnings = 0;
  int _totalDeals = 0;
  int _completedDeals = 0;

  // Monthly chart data
  final List<double> _monthlyData = [0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final txns = await SupabaseService.instance.getUserTransactions();
      if (mounted) {
        setState(() {
          _transactions = txns;
          _computeStats();
          _isLoading = false;
        });
      }
    } catch (_) {
      // Use mock data for demo
      _loadMockData();
    }
  }

  void _loadMockData() {
    _transactions = [
      {
        'id': 'txn_001',
        'status': 'completed',
        'property_price': 185000,
        'commission_rate': 0.01,
        'created_at': '2025-03-15',
        'property_title': 'Modern Apartment — Karrada',
      },
      {
        'id': 'txn_002',
        'status': 'completed',
        'property_price': 420000,
        'commission_rate': 0.01,
        'created_at': '2025-04-22',
        'property_title': 'Villa — Mansour District',
      },
      {
        'id': 'txn_003',
        'status': 'pending',
        'property_price': 260000,
        'commission_rate': 0.01,
        'created_at': '2025-05-10',
        'property_title': 'Townhouse — Jadriya',
      },
      {
        'id': 'txn_004',
        'status': 'in_progress',
        'property_price': 95000,
        'commission_rate': 0.01,
        'created_at': '2025-06-01',
        'property_title': 'Land — Adhamiya',
      },
      {
        'id': 'txn_005',
        'status': 'completed',
        'property_price': 75000,
        'commission_rate': 0.01,
        'created_at': '2025-06-18',
        'property_title': 'Apartment — Kadhimiya',
      },
    ];
    _computeStats();
    if (mounted) setState(() => _isLoading = false);
  }

  void _computeStats() {
    _totalDeals = _transactions.length;
    _completedDeals = _transactions
        .where((t) => t['status'] == 'completed')
        .length;
    _totalEarnings = 0;
    _pendingEarnings = 0;
    _completedEarnings = 0;

    for (final t in _transactions) {
      final price = (t['property_price'] as num?)?.toDouble() ?? 0;
      final rate = (t['commission_rate'] as num?)?.toDouble() ?? 0.01;
      final commission = price * rate;
      _totalEarnings += commission;
      if (t['status'] == 'completed') {
        _completedEarnings += commission;
      } else {
        _pendingEarnings += commission;
      }
    }

    // Build monthly chart (last 6 months)
    final now = DateTime.now();
    _monthlyData.fillRange(0, 6, 0);
    for (final t in _transactions) {
      try {
        final date = DateTime.parse(t['created_at'] as String? ?? '');
        final monthDiff =
            (now.year - date.year) * 12 + (now.month - date.month);
        if (monthDiff >= 0 && monthDiff < 6) {
          final price = (t['property_price'] as num?)?.toDouble() ?? 0;
          final rate = (t['commission_rate'] as num?)?.toDouble() ?? 0.01;
          _monthlyData[5 - monthDiff] += price * rate;
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.isRTL ? 'لوحة عمولات البائع' : 'Seller Commission Dashboard',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withAlpha(150),
          tabs: [
            Tab(text: loc.isRTL ? 'نظرة عامة' : 'Overview'),
            Tab(text: loc.isRTL ? 'الصفقات' : 'Deals'),
            Tab(text: loc.isRTL ? 'الإحصاء' : 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(theme, loc),
                _buildDealsTab(theme, loc),
                _buildAnalyticsTab(theme, loc),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, AppLocalizations loc) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Total earnings hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white.withAlpha(200),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc.isRTL ? 'إجمالي العمولات' : 'Total Commissions',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${_totalEarnings.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMiniStat(
                        loc.isRTL ? 'مكتملة' : 'Completed',
                        '\$${_completedEarnings.toStringAsFixed(0)}',
                        AppTheme.success,
                      ),
                      const SizedBox(width: 16),
                      _buildMiniStat(
                        loc.isRTL ? 'معلقة' : 'Pending',
                        '\$${_pendingEarnings.toStringAsFixed(0)}',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    theme,
                    icon: Icons.handshake,
                    label: loc.isRTL ? 'إجمالي الصفقات' : 'Total Deals',
                    value: '$_totalDeals',
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    theme,
                    icon: Icons.check_circle,
                    label: loc.isRTL ? 'صفقات مكتملة' : 'Completed',
                    value: '$_completedDeals',
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    theme,
                    icon: Icons.pending,
                    label: loc.isRTL ? 'قيد التنفيذ' : 'In Progress',
                    value:
                        '${_transactions.where((t) => t['status'] == 'in_progress').length}',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    theme,
                    icon: Icons.percent,
                    label: loc.isRTL ? 'نسبة الإنجاز' : 'Success Rate',
                    value: _totalDeals > 0
                        ? '${((_completedDeals / _totalDeals) * 100).toStringAsFixed(0)}%'
                        : '0%',
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Commission breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
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
                    loc.isRTL ? 'تفاصيل العمولة' : 'Commission Breakdown',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBreakdownRow(
                    theme,
                    loc.isRTL
                        ? 'عمولة المكاتبة (1%)'
                        : 'Brokerage Commission (1%)',
                    '\$${_completedEarnings.toStringAsFixed(0)}',
                    AppTheme.primary,
                    _totalEarnings > 0
                        ? _completedEarnings / _totalEarnings
                        : 0,
                  ),
                  const SizedBox(height: 12),
                  _buildBreakdownRow(
                    theme,
                    loc.isRTL
                        ? 'رسوم الخدمات الإلكترونية'
                        : 'Digital Services Fee',
                    '\$${(_completedDeals * 300).toStringAsFixed(0)}',
                    const Color(0xFF6C63FF),
                    0.3,
                  ),
                  const SizedBox(height: 12),
                  _buildBreakdownRow(
                    theme,
                    loc.isRTL
                        ? 'رسوم التصوير والترويج'
                        : 'Photography & Marketing',
                    '\$${(_completedDeals * 150).toStringAsFixed(0)}',
                    Colors.orange,
                    0.15,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: color == AppTheme.success
                ? Colors.greenAccent
                : Colors.orangeAccent,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    ThemeData theme,
    String label,
    String value,
    Color color,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withAlpha(20),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDealsTab(ThemeData theme, AppLocalizations loc) {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handshake_outlined,
              size: 64,
              color: Colors.grey.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              loc.isRTL ? 'لا توجد صفقات بعد' : 'No deals yet',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (_, i) {
        final t = _transactions[i];
        final price = (t['property_price'] as num?)?.toDouble() ?? 0;
        final rate = (t['commission_rate'] as num?)?.toDouble() ?? 0.01;
        final commission = price * rate;
        final status = t['status'] as String? ?? 'pending';
        final title =
            t['property_title'] as String? ?? (loc.isRTL ? 'عقار' : 'Property');
        final date = t['created_at'] as String? ?? '';

        Color statusColor;
        String statusLabel;
        switch (status) {
          case 'completed':
            statusColor = AppTheme.success;
            statusLabel = loc.isRTL ? 'مكتملة' : 'Completed';
            break;
          case 'in_progress':
            statusColor = Colors.orange;
            statusLabel = loc.isRTL ? 'جارية' : 'In Progress';
            break;
          default:
            statusColor = Colors.grey;
            statusLabel = loc.isRTL ? 'معلقة' : 'Pending';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_work, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '\$${price.toStringAsFixed(0)} • ${loc.isRTL ? 'العمولة:' : 'Commission:'} \$${commission.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (date.isNotEmpty)
                      Text(
                        date.substring(0, 10),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab(ThemeData theme, AppLocalizations loc) {
    final months = loc.isRTL
        ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final now = DateTime.now();
    final last6Months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i);
      return months[m.month - 1];
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
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
                  loc.isRTL ? 'العمولات الشهرية' : 'Monthly Commissions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY:
                          _monthlyData.reduce((a, b) => a > b ? a : b) * 1.3 +
                          100,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= last6Months.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                last6Months[idx],
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) =>
                            FlLine(color: theme.dividerColor, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(6, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: _monthlyData[i],
                              color: AppTheme.primary,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Performance metrics
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
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
                  loc.isRTL ? 'مؤشرات الأداء' : 'Performance Metrics',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMetricRow(
                  theme,
                  loc.isRTL ? 'متوسط قيمة الصفقة' : 'Avg Deal Value',
                  _totalDeals > 0
                      ? '\$${(_transactions.fold<double>(0, (s, t) => s + ((t['property_price'] as num?)?.toDouble() ?? 0)) / _totalDeals).toStringAsFixed(0)}'
                      : '\$0',
                  Icons.trending_up,
                  AppTheme.primary,
                ),
                const Divider(height: 24),
                _buildMetricRow(
                  theme,
                  loc.isRTL ? 'متوسط العمولة' : 'Avg Commission',
                  _totalDeals > 0
                      ? '\$${(_totalEarnings / _totalDeals).toStringAsFixed(0)}'
                      : '\$0',
                  Icons.percent,
                  const Color(0xFF6C63FF),
                ),
                const Divider(height: 24),
                _buildMetricRow(
                  theme,
                  loc.isRTL ? 'أعلى صفقة' : 'Best Deal',
                  _transactions.isEmpty
                      ? '\$0'
                      : '\$${_transactions.map((t) => (t['property_price'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}',
                  Icons.star,
                  Colors.amber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
