import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/directional_layout.dart';

class PropertyAnalyticsScreen extends StatefulWidget {
  const PropertyAnalyticsScreen({super.key});

  @override
  State<PropertyAnalyticsScreen> createState() =>
      _PropertyAnalyticsScreenState();
}

class _PropertyAnalyticsScreenState extends State<PropertyAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '30d';
  final int _touchedIndex = -1;

  final List<String> _periods = ['7d', '30d', '90d', '1y'];

  // ─── Demo Data ──────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _topProperties = [
    {
      'title': 'Luxury Villa — Mansour, Baghdad',
      'type': 'Villa',
      'price': '850,000,000 IQD',
      'views': 4821,
      'inquiries': 142,
      'saves': 389,
      'conversion': 2.94,
      'trend': 'up',
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1b9553347-1774335786277.png',
    },
    {
      'title': 'Modern Apartment — Karrada',
      'type': 'Apartment',
      'price': '185,000,000 IQD',
      'views': 3654,
      'inquiries': 98,
      'saves': 271,
      'conversion': 2.68,
      'trend': 'up',
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1ae964f09-1784904412567.png',
    },
    {
      'title': 'Commercial Space — Zayouna',
      'type': 'Commercial',
      'price': '320,000,000 IQD',
      'views': 2187,
      'inquiries': 54,
      'saves': 112,
      'conversion': 2.47,
      'trend': 'down',
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1319d6365-1786828392522.png',
    },
    {
      'title': 'Family Home — Adhamiyah',
      'type': 'House',
      'price': '420,000,000 IQD',
      'views': 1943,
      'inquiries': 67,
      'saves': 198,
      'conversion': 3.45,
      'trend': 'up',
      'image':
          'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=200&h=120&fit=crop',
    },
    {
      'title': 'Studio Apartment — Jadriyah',
      'type': 'Apartment',
      'price': '95,000,000 IQD',
      'views': 1621,
      'inquiries': 43,
      'saves': 156,
      'conversion': 2.65,
      'trend': 'stable',
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1e1ef8294-1772141183208.png',
    },
  ];

  final List<Map<String, dynamic>> _typeBreakdown = [
    {'type': 'Apartment', 'count': 847, 'pct': 0.38, 'color': 0xFF4FC3F7},
    {'type': 'Villa', 'count': 423, 'pct': 0.19, 'color': 0xFF81C784},
    {'type': 'House', 'count': 612, 'pct': 0.27, 'color': 0xFFFFB74D},
    {'type': 'Commercial', 'count': 178, 'pct': 0.08, 'color': 0xFFCE93D8},
    {'type': 'Land', 'count': 178, 'pct': 0.08, 'color': 0xFFEF9A9A},
  ];

  final List<Map<String, dynamic>> _regionData = [
    {
      'region': 'Mansour',
      'listings': 312,
      'avgPrice': '620M IQD',
      'growth': '+18%',
    },
    {
      'region': 'Karrada',
      'listings': 287,
      'avgPrice': '195M IQD',
      'growth': '+12%',
    },
    {
      'region': 'Adhamiyah',
      'listings': 198,
      'avgPrice': '380M IQD',
      'growth': '+8%',
    },
    {
      'region': 'Zayouna',
      'listings': 176,
      'avgPrice': '290M IQD',
      'growth': '+22%',
    },
    {
      'region': 'Jadriyah',
      'listings': 154,
      'avgPrice': '145M IQD',
      'growth': '+5%',
    },
    {
      'region': 'Sadr City',
      'listings': 143,
      'avgPrice': '85M IQD',
      'growth': '+31%',
    },
  ];

  List<FlSpot> get _viewsSpots => [
    const FlSpot(0, 1200),
    const FlSpot(1, 1850),
    const FlSpot(2, 1400),
    const FlSpot(3, 2100),
    const FlSpot(4, 1900),
    const FlSpot(5, 2800),
    const FlSpot(6, 3200),
    const FlSpot(7, 2900),
    const FlSpot(8, 3600),
    const FlSpot(9, 3100),
    const FlSpot(10, 4200),
    const FlSpot(11, 4821),
  ];

  List<FlSpot> get _inquiriesSpots => [
    const FlSpot(0, 45),
    const FlSpot(1, 62),
    const FlSpot(2, 48),
    const FlSpot(3, 78),
    const FlSpot(4, 71),
    const FlSpot(5, 95),
    const FlSpot(6, 112),
    const FlSpot(7, 98),
    const FlSpot(8, 134),
    const FlSpot(9, 118),
    const FlSpot(10, 156),
    const FlSpot(11, 142),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: const Color(0xFF0A0E1A),
            leading: IconButton(
              icon: const DirectionalIcon(
                icon: Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A0E1A),
                      Color(0xFF1B5E20),
                      Color(0xFF0A0E1A),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Property Analytics',
                          style: GoogleFonts.dmSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Listing performance & market insights',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: const Color(0xFF0A0E1A),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF81C784),
                  indicatorWeight: 2,
                  labelColor: const Color(0xFF81C784),
                  unselectedLabelColor: Colors.white38,
                  labelStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Listings'),
                    Tab(text: 'Regions'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildListingsTab(),
            _buildRegionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period selector
        Row(
          children: _periods.map((p) {
            final sel = _selectedPeriod == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedPeriod = p),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF81C784)
                        : const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? const Color(0xFF81C784) : Colors.white12,
                    ),
                  ),
                  child: Text(
                    p,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel ? const Color(0xFF0A0E1A) : Colors.white54,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // KPI grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _buildKpiCard(
              'Total Views',
              '18,226',
              '+24%',
              Icons.visibility_outlined,
              const Color(0xFF4FC3F7),
            ),
            _buildKpiCard(
              'Inquiries',
              '604',
              '+18%',
              Icons.chat_bubble_outline,
              const Color(0xFF81C784),
            ),
            _buildKpiCard(
              'Active Listings',
              '2,238',
              '+11%',
              Icons.home_outlined,
              const Color(0xFFFFB74D),
            ),
            _buildKpiCard(
              'Avg. Conversion',
              '2.87%',
              '+0.4%',
              Icons.trending_up,
              const Color(0xFFCE93D8),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Views chart
        _buildChartCard(
          'Views & Inquiries Trend',
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white.withAlpha(13), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        '${(v / 1000).toStringAsFixed(0)}k',
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const months = [
                          'J',
                          'F',
                          'M',
                          'A',
                          'M',
                          'J',
                          'J',
                          'A',
                          'S',
                          'O',
                          'N',
                          'D',
                        ];
                        final i = v.toInt();
                        if (i < 0 || i >= months.length) {
                          return const SizedBox();
                        }
                        return Text(
                          months[i],
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            color: Colors.white38,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _viewsSpots,
                    isCurved: true,
                    color: const Color(0xFF4FC3F7),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4FC3F7).withAlpha(20),
                    ),
                  ),
                  LineChartBarData(
                    spots: _inquiriesSpots,
                    isCurved: true,
                    color: const Color(0xFF81C784),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF81C784).withAlpha(15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Type breakdown
        _buildChartCard(
          'Listings by Type',
          Column(
            children: _typeBreakdown.map((t) {
              final color = Color(t['color'] as int);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t['type'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    Text(
                      '${t['count']}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: t['pct'] as double,
                          backgroundColor: Colors.white.withAlpha(20),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${((t['pct'] as double) * 100).toInt()}%',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListingsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _topProperties.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = _topProperties[i];
        final trend = p['trend'] as String;
        final trendColor = trend == 'up'
            ? const Color(0xFF81C784)
            : trend == 'down'
            ? const Color(0xFFEF9A9A)
            : Colors.white38;
        final trendIcon = trend == 'up'
            ? Icons.trending_up
            : trend == 'down'
            ? Icons.trending_down
            : Icons.trending_flat;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  p['image'] as String,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: Colors.white.withAlpha(13),
                    child: const Icon(
                      Icons.home,
                      color: Colors.white24,
                      size: 40,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p['title'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(trendIcon, color: trendColor, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p['price'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF81C784),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMetricChip(
                          Icons.visibility_outlined,
                          '${p['views']}',
                          'Views',
                          const Color(0xFF4FC3F7),
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          Icons.chat_bubble_outline,
                          '${p['inquiries']}',
                          'Inquiries',
                          const Color(0xFF81C784),
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          Icons.bookmark_outline,
                          '${p['saves']}',
                          'Saves',
                          const Color(0xFFFFB74D),
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          Icons.percent,
                          '${p['conversion']}%',
                          'CVR',
                          const Color(0xFFCE93D8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChartCard(
          'Listings by Region',
          Column(
            children: _regionData.map((r) {
              final isPositive = (r['growth'] as String).startsWith('+');
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        r['region'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r['listings']} listings',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            r['avgPrice'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isPositive
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFFEF9A9A))
                                .withAlpha(38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r['growth'] as String,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPositive
                              ? const Color(0xFF81C784)
                              : const Color(0xFFEF9A9A),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Market insights
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF81C784).withAlpha(51)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.insights,
                    color: Color(0xFF81C784),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Market Insights',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInsightRow(
                Icons.emoji_events_outlined,
                'Zayouna shows highest growth at +22% this month',
              ),
              _buildInsightRow(
                Icons.trending_up_outlined,
                'Apartment demand up 18% vs last quarter',
              ),
              _buildInsightRow(
                Icons.payments_outlined,
                'Average listing price increased 8.4% YoY',
              ),
              _buildInsightRow(
                Icons.bolt_outlined,
                'Sadr City emerging market — fastest growing region',
              ),
              _buildInsightRow(
                Icons.search_outlined,
                'Villa searches peaked on weekends (+34%)',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    String label,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    final isPositive = change.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      (isPositive
                              ? const Color(0xFF81C784)
                              : const Color(0xFFEF9A9A))
                          .withAlpha(38),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  change,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPositive
                        ? const Color(0xFF81C784)
                        : const Color(0xFFEF9A9A),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white38),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 9, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.white60,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
