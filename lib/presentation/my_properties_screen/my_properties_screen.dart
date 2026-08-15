import '../../core/app_export.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/supabase_service.dart';
import './widgets/add_property_sheet_widget.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;
  late TabController _tabController;

  final List<Map<String, dynamic>> _adCards = [
    {
      'title': 'نقل الأثاث',
      'subtitle': 'خدمة نقل احترافية وآمنة',
      'icon': '🚚',
      'color': 0xFF1565C0,
      'tag': 'شريك مدار',
    },
    {
      'title': 'تجميل العقارات',
      'subtitle': 'تصميم داخلي وتشطيبات فاخرة',
      'icon': '🎨',
      'color': 0xFF7B1FA2,
      'tag': 'شريك مدار',
    },
    {
      'title': 'ضمان العقارات',
      'subtitle': 'حماية شاملة لعقارك',
      'icon': '🛡️',
      'color': 0xFF00897B,
      'tag': 'شريك مدار',
    },
  ];

  int _currentAdIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _startAdRotation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startAdRotation() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _currentAdIndex = (_currentAdIndex + 1) % _adCards.length;
        });
        _startAdRotation();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final properties = await SupabaseService.instance.getUserProperties();
      final submissions = await SupabaseService.instance
          .getPropertySubmissions();
      if (mounted) {
        setState(() {
          _properties = properties;
          _submissions = submissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
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
          title: Text(
            loc.myProperties,
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
              Tab(text: loc.myProperties),
              Tab(text: loc.submittedRequests),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPropertiesTab(theme, loc),
          _buildSubmissionsTab(theme, loc),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPropertySheet,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          loc.addProperty,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesTab(ThemeData theme, AppLocalizations loc) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildAdCarousel(theme, loc)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '${loc.myProperties} (${_properties.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_properties.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyProperties(theme, loc))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildPropertyCard(theme, _properties[i], loc),
                childCount: _properties.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTab(ThemeData theme, AppLocalizations loc) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: _submissions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.isRTL ? 'لا توجد طلبات' : 'No requests yet',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.isRTL
                        ? 'أضف عقاراً لتبدأ'
                        : 'Add a property to get started',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _submissions.length,
              itemBuilder: (_, i) =>
                  _buildSubmissionCard(theme, _submissions[i], loc),
            ),
    );
  }

  Widget _buildAdCarousel(ThemeData theme, AppLocalizations loc) {
    final adTitles = loc.isRTL
        ? ['نقل الأثاث', 'تجميل العقارات', 'ضمان العقارات']
        : ['Furniture Moving', 'Property Renovation', 'Property Insurance'];
    final adSubtitles = loc.isRTL
        ? [
            'خدمة نقل احترافية وآمنة',
            'تصميم داخلي وتشطيبات فاخرة',
            'حماية شاملة لعقارك',
          ]
        : [
            'Professional & safe moving service',
            'Interior design & premium finishes',
            'Comprehensive property protection',
          ];
    final adTag = loc.isRTL ? 'شريك مدار' : 'Madar Partner';

    final ad = _adCards[_currentAdIndex];
    final color = Color(ad['color'] as int);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(_currentAdIndex),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withAlpha(200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(ad['icon'] as String, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      adTag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    adTitles[_currentAdIndex],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    adSubtitles[_currentAdIndex],
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 12,
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

  Widget _buildEmptyProperties(ThemeData theme, AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 64,
              color: Colors.grey.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              loc.isRTL ? 'لا توجد عقارات بعد' : 'No properties yet',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              loc.isRTL
                  ? 'اضغط على زر الإضافة لإضافة عقارك'
                  : 'Tap the add button to list your property',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(
    ThemeData theme,
    Map<String, dynamic> property,
    AppLocalizations loc,
  ) {
    final title =
        property['title'] as String? ?? (loc.isRTL ? 'عقار' : 'Property');
    final address = property['address'] as String? ?? '';
    final price = property['asking_price_usd'] as num? ?? 0;
    final status = property['status'] as String? ?? 'active';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.home_work, color: AppTheme.primary, size: 28),
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
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (address.isNotEmpty)
                  Text(
                    address,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  '\$${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'active'
                  ? AppTheme.success.withAlpha(20)
                  : Colors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status == 'active'
                  ? (loc.isRTL ? 'نشط' : 'Active')
                  : (loc.isRTL ? 'معلق' : 'Pending'),
              style: TextStyle(
                color: status == 'active' ? AppTheme.success : Colors.orange,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(
    ThemeData theme,
    Map<String, dynamic> submission,
    AppLocalizations loc,
  ) {
    final address =
        submission['address'] as String? ??
        (loc.isRTL ? 'عنوان غير محدد' : 'No address');
    final type = submission['property_type'] as String? ?? 'house';
    final status = submission['status'] as String? ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pending_actions,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  type,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              loc.underReview,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPropertySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPropertySheetWidget(
        onSubmitted: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000000) {
      return '${(price / 1000000000).toStringAsFixed(1)} مليار د.ع';
    } else if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} مليون د.ع';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} ألف د.ع';
    }
    return '${price.toStringAsFixed(0)} د.ع';
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
