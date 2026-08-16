import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/app_export.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/chat_notifier.dart';
import '../../services/supabase_service.dart';

// Zillow-style Property Detail Screen — 5 tabs with live Supabase data

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  bool _isFavorited = false;
  double _downPaymentPercent = 20;
  double _interestRate = 7.5;
  int _loanYears = 20;
  late TabController _tabController;
  late PageController _imagePageController;
  bool _isLoadingDetails = false;
  Map<String, dynamic>? _fullPropertyData;

  static const _aiConfig = ChatConfig(
    provider: 'GEMINI',
    model: 'gemini/gemini-2.5-flash',
    streaming: true,
  );

  List<String> _images = [
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
    'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _imagePageController = PageController();
    _loadPropertyImages();
    _loadFullPropertyData();
  }

  void _loadPropertyImages() {
    final media = widget.property['property_media_v3'] as List?;
    if (media != null && media.isNotEmpty) {
      final urls = media
          .map((m) => m['media_url'] as String? ?? '')
          .where((u) => u.isNotEmpty)
          .toList();
      if (urls.isNotEmpty) {
        setState(() => _images = urls);
      }
    } else if (widget.property['imageUrl'] != null) {
      setState(() => _images = [widget.property['imageUrl'] as String]);
    }
  }

  Future<void> _loadFullPropertyData() async {
    final id = widget.property['id'] as String?;
    if (id == null) return;
    setState(() => _isLoadingDetails = true);
    try {
      final data = await SupabaseService.instance.getPropertyById(id);
      if (data != null && mounted) {
        setState(() {
          _fullPropertyData = data;
          final media = data['property_media_v3'] as List?;
          if (media != null && media.isNotEmpty) {
            final urls = media
                .map((m) => m['media_url'] as String? ?? '')
                .where((u) => u.isNotEmpty)
                .toList();
            if (urls.isNotEmpty) _images = urls;
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingDetails = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _effectiveProperty =>
      _fullPropertyData ?? widget.property;

  double get _propertyPrice {
    final v =
        _effectiveProperty['asking_price'] ??
        _effectiveProperty['estimatedValue'] ??
        _effectiveProperty['price'];
    return (v as num?)?.toDouble() ?? 185000;
  }

  double get _propertyArea {
    final v =
        _effectiveProperty['total_area_sqm'] ?? _effectiveProperty['area'];
    return (v as num?)?.toDouble() ?? 180;
  }

  int get _bedrooms {
    final v =
        _effectiveProperty['bedrooms_count'] ?? _effectiveProperty['bedrooms'];
    return (v as num?)?.toInt() ?? 3;
  }

  int get _bathrooms {
    final v =
        _effectiveProperty['bathrooms_count'] ??
        _effectiveProperty['bathrooms'];
    return (v as num?)?.toInt() ?? 2;
  }

  String get _title =>
      _effectiveProperty['title'] as String? ??
      _effectiveProperty['property_type'] as String? ??
      'Modern Property';

  String get _address {
    final addr =
        _effectiveProperty['address_text'] ?? _effectiveProperty['address'];
    if (addr != null) return addr as String;
    final city = _effectiveProperty['city'] as String? ?? '';
    final district = _effectiveProperty['district'] as String? ?? '';
    return [district, city].where((s) => s.isNotEmpty).join(', ');
  }

  String get _listingType =>
      _effectiveProperty['listing_type'] as String? ??
      _effectiveProperty['listingType'] as String? ??
      'sale';

  String get _propertyType =>
      _effectiveProperty['property_type'] as String? ??
      _effectiveProperty['type'] as String? ??
      'apartment';

  String get _description =>
      _effectiveProperty['description'] as String? ??
      'This premium property features modern finishes, smart home system, and is located in one of Baghdad\'s most sought-after districts. Walking distance to major hospitals, schools, and shopping centers.';

  int get _yearBuilt {
    final v = _effectiveProperty['year_built'];
    return (v as num?)?.toInt() ?? 2019;
  }

  int get _floorNumber {
    final v = _effectiveProperty['floor_number'];
    return (v as num?)?.toInt() ?? 0;
  }

  int get _totalFloors {
    final v = _effectiveProperty['total_floors'];
    return (v as num?)?.toInt() ?? 0;
  }

  double get _monthlyPayment {
    final loan = _propertyPrice * (1 - _downPaymentPercent / 100);
    final monthlyRate = _interestRate / 100 / 12;
    final n = _loanYears * 12;
    if (monthlyRate == 0) return loan / n;
    return loan *
        monthlyRate *
        _pow(1 + monthlyRate, n) /
        (_pow(1 + monthlyRate, n) - 1);
  }

  double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    ref.listen<ChatState>(chatNotifierProvider(_aiConfig), (prev, next) {
      if (next.error != null) {
        Fluttertoast.showToast(
          msg: next.error.toString(),
          backgroundColor: Colors.red,
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => setState(() => _isFavorited = !_isFavorited),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? Colors.red : Colors.white,
                    size: 20,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _imagePageController,
                    itemCount: _images.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (ctx, i) => CachedNetworkImage(
                      imageUrl: _images[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.primaryDark.withAlpha(60),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.primaryDark.withAlpha(60),
                        child: const Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${_images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.view_in_ar, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '3D Tour',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _images.length.clamp(0, 8),
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentImageIndex ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _currentImageIndex
                                ? Colors.white
                                : Colors.white.withAlpha(120),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriceSection(theme, loc),
                _buildMadarEstimate(theme, loc),
                _buildTabBar(theme, loc),
                _buildTabContent(theme, loc),
                _buildActionButtons(theme, loc),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(ThemeData theme, AppLocalizations loc) {
    final listingLabel = _getListingLabel(_listingType);
    final listingColor = _getListingColor(_listingType);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: listingColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            listingLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_effectiveProperty['is_verified'] == true ||
                            _effectiveProperty['isVerified'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.success),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: AppTheme.success,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  loc.verified,
                                  style: const TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '\$${_formatNumber(_propertyPrice.toInt())}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _address,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(theme, '$_bedrooms', 'Beds', Icons.bed_outlined),
                _buildDivider(),
                _buildStatItem(
                  theme,
                  '$_bathrooms',
                  'Baths',
                  Icons.bathtub_outlined,
                ),
                _buildDivider(),
                _buildStatItem(
                  theme,
                  '${_propertyArea.toInt()}',
                  'm²',
                  Icons.square_foot,
                ),
                _buildDivider(),
                _buildStatItem(
                  theme,
                  '\$${(_propertyPrice / _propertyArea).toInt()}',
                  '/m²',
                  Icons.attach_money,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getListingLabel(String type) {
    switch (type) {
      case 'sale':
        return 'For Sale';
      case 'rent':
        return 'For Rent';
      case 'mortgage':
        return 'Mortgage';
      case 'investment':
        return 'Investment';
      default:
        return type.toUpperCase();
    }
  }

  Color _getListingColor(String type) {
    switch (type) {
      case 'sale':
        return AppTheme.saleColor;
      case 'rent':
        return AppTheme.rentColor;
      case 'mortgage':
        return AppTheme.mortgageColor;
      case 'investment':
        return AppTheme.investmentColor;
      default:
        return AppTheme.primary;
    }
  }

  Widget _buildStatItem(
    ThemeData theme,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() =>
      Container(width: 1, height: 40, color: AppTheme.borderLight);

  Widget _buildMadarEstimate(ThemeData theme, AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withAlpha(15),
            AppTheme.primaryLight.withAlpha(15),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_graph,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                loc.madarEstimate,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '\$${_formatNumber((_propertyPrice * 1.03).toInt())}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(painter: _PriceChartPainter()),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rent Estimate: \$${(_propertyPrice * 0.004).toInt()}/mo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary,
                ),
              ),
              const Text(
                '+3.2% this year',
                style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'History'),
          Tab(text: 'Neighborhood'),
          Tab(text: 'Mortgage'),
          Tab(text: 'AI Insights'),
        ],
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme, AppLocalizations loc) {
    return SizedBox(
      height: 560,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(theme, loc),
          _buildHistoryTab(theme, loc),
          _buildNeighborhoodTab(theme, loc),
          _buildMortgageTab(theme, loc),
          _buildAiInsightsTab(theme, loc),
        ],
      ),
    );
  }

  // ── TAB 1: DETAILS ──────────────────────────────────────────────────────────
  Widget _buildDetailsTab(ThemeData theme, AppLocalizations loc) {
    final features = _effectiveProperty['property_features_v3'] as List?;
    final featureNames = features != null
        ? features
              .map((f) => f['feature_name'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .toList()
        : <String>[
            'Central AC',
            'Smart Home',
            'Parking x2',
            'Elevator',
            'Security 24/7',
            'Gym',
            'Rooftop',
            'Storage',
            'Italian Kitchen',
            'Marble Floors',
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, loc.whatsSpecial),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryLight.withAlpha(60)),
            ),
            child: Text(_description, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(theme, loc.leaseToOwn),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.investmentColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.investmentColor.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.home_work,
                      color: AppTheme.investmentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Madar Lease-to-Own Program',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.investmentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildLtoRow(
                  theme,
                  'Monthly Payment',
                  '\$${_formatNumber((_propertyPrice * 0.005).toInt())}/month',
                ),
                _buildLtoRow(theme, 'Duration', '20 years'),
                _buildLtoRow(
                  theme,
                  'Down Payment',
                  '\$${_formatNumber((_propertyPrice * 0.1).toInt())} (10%)',
                ),
                _buildLtoRow(theme, 'Ownership Transfer', 'After full payment'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(theme, 'Home Details'),
          const SizedBox(height: 10),
          _buildDetailGrid(theme),
          const SizedBox(height: 20),
          _buildSectionHeader(theme, 'Features & Amenities'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: featureNames
                .map(
                  (f) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 12,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          f,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLtoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailGrid(ThemeData theme) {
    final details = [
      {
        'icon': 'calendar_today',
        'label': 'Year Built',
        'value': _yearBuilt > 0 ? '$_yearBuilt' : 'N/A',
      },
      {
        'icon': 'layers',
        'label': 'Floor',
        'value': _floorNumber > 0
            ? '$_floorNumber${_totalFloors > 0 ? ' of $_totalFloors' : ''}'
            : 'N/A',
      },
      {
        'icon': 'square_foot',
        'label': 'Total Area',
        'value': '${_propertyArea.toInt()} m²',
      },
      {
        'icon': 'meeting_room',
        'label': 'Rooms',
        'value': '$_bedrooms Bed, $_bathrooms Bath',
      },
      {'icon': 'directions_car', 'label': 'Parking', 'value': '2 Spaces'},
      {'icon': 'roofing', 'label': 'Roof Type', 'value': 'Flat Concrete'},
      {'icon': 'thermostat', 'label': 'Heating', 'value': 'Central'},
      {'icon': 'ac_unit', 'label': 'Cooling', 'value': 'Central AC'},
      {'icon': 'kitchen', 'label': 'Kitchen', 'value': 'Fitted'},
      {
        'icon': 'landscape',
        'label': 'Type',
        'value': _propertyType.toUpperCase(),
      },
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: details.length,
      itemBuilder: (ctx, i) {
        final d = details[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      d['label']!,
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                    Text(
                      d['value']!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  // ── TAB 2: PRICE/TAX HISTORY ─────────────────────────────────────────────
  Widget _buildHistoryTab(ThemeData theme, AppLocalizations loc) {
    final priceHistory = [
      {
        'date': 'Aug 2026',
        'event': 'Listed for Sale',
        'price': '\$${_formatNumber(_propertyPrice.toInt())}',
        'change': '+8.2%',
        'positive': true,
      },
      {
        'date': 'Jan 2024',
        'event': 'Price Reduced',
        'price': '\$${_formatNumber((_propertyPrice * 0.92).toInt())}',
        'change': '-5.0%',
        'positive': false,
      },
      {
        'date': 'Mar 2022',
        'event': 'Sold',
        'price': '\$${_formatNumber((_propertyPrice * 0.97).toInt())}',
        'change': '+20.0%',
        'positive': true,
      },
      {
        'date': 'Jun 2019',
        'event': 'First Listed',
        'price': '\$${_formatNumber((_propertyPrice * 0.81).toInt())}',
        'change': 'New',
        'positive': true,
      },
    ];
    final taxHistory = [
      {
        'year': '2025',
        'tax': '\$${_formatNumber((_propertyPrice * 0.01).toInt())}',
        'assessed': '\$${_formatNumber((_propertyPrice * 0.95).toInt())}',
      },
      {
        'year': '2024',
        'tax': '\$${_formatNumber((_propertyPrice * 0.0092).toInt())}',
        'assessed': '\$${_formatNumber((_propertyPrice * 0.87).toInt())}',
      },
      {
        'year': '2023',
        'tax': '\$${_formatNumber((_propertyPrice * 0.0087).toInt())}',
        'assessed': '\$${_formatNumber((_propertyPrice * 0.83).toInt())}',
      },
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Price History'),
          const SizedBox(height: 12),
          ...priceHistory.map(
            (h) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: (h['positive'] as bool)
                          ? AppTheme.success
                          : AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h['event']! as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          h['date']! as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        h['price']! as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        h['change']! as String,
                        style: TextStyle(
                          color: (h['positive'] as bool)
                              ? AppTheme.success
                              : AppTheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(theme, 'Tax History'),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(8),
            ),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                ),
                children: ['Year', 'Tax Paid', 'Assessed Value']
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          h,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              ...taxHistory.map(
                (t) => TableRow(
                  children: [t['year']!, t['tax']!, t['assessed']!]
                      .map(
                        (v) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(v, style: const TextStyle(fontSize: 12)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TAB 3: NEIGHBORHOOD ──────────────────────────────────────────────────
  Widget _buildNeighborhoodTab(ThemeData theme, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Walkability Scores'),
          const SizedBox(height: 12),
          _buildScoreBar(theme, 'Walk Score', 82, AppTheme.success),
          _buildScoreBar(theme, 'Transit Score', 74, AppTheme.primary),
          _buildScoreBar(theme, 'Bike Score', 55, AppTheme.warning),
          const SizedBox(height: 20),
          _buildSectionHeader(theme, 'Nearby Schools'),
          const SizedBox(height: 12),
          _buildSchoolItem(theme, 'Al-Karrada Primary School', '0.3 km', 8),
          _buildSchoolItem(theme, 'Baghdad International School', '1.2 km', 9),
          _buildSchoolItem(theme, 'Al-Mustansiriya University', '2.1 km', 7),
          const SizedBox(height: 20),
          _buildSectionHeader(theme, 'Climate Risk (30 Years)'),
          const SizedBox(height: 12),
          _buildRiskItem(theme, 'Flood Risk', 'Low', AppTheme.success, 0.15),
          _buildRiskItem(theme, 'Heat Risk', 'High', AppTheme.error, 0.85),
          _buildRiskItem(theme, 'Wind Risk', 'Low', AppTheme.success, 0.2),
          _buildRiskItem(
            theme,
            'Drought Risk',
            'Moderate',
            AppTheme.warning,
            0.55,
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(theme, 'Nearby Places'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildNearbyChip(theme, '🏥 Hospital', '0.5 km'),
              _buildNearbyChip(theme, '🛒 Mall', '0.8 km'),
              _buildNearbyChip(theme, '🕌 Mosque', '0.2 km'),
              _buildNearbyChip(theme, '🏦 Bank', '0.4 km'),
              _buildNearbyChip(theme, '🍽️ Restaurant', '0.1 km'),
              _buildNearbyChip(theme, '⛽ Gas Station', '0.6 km'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(ThemeData theme, String label, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                '$score/100',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolItem(
    ThemeData theme,
    String name,
    String distance,
    int rating,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$rating',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            distance,
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskItem(
    ThemeData theme,
    String label,
    String level,
    Color color,
    double value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              level,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyChip(ThemeData theme, String label, String distance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            distance,
            style: const TextStyle(fontSize: 10, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  // ── TAB 4: MORTGAGE CALCULATOR ───────────────────────────────────────────
  Widget _buildMortgageTab(ThemeData theme, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Mortgage Calculator'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Estimated Monthly Payment',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${_formatNumber(_monthlyPayment.toInt())}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'per month',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Down Payment: ${_downPaymentPercent.toInt()}% (\$${_formatNumber((_propertyPrice * _downPaymentPercent / 100).toInt())})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _downPaymentPercent,
            min: 5,
            max: 50,
            divisions: 45,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _downPaymentPercent = v),
          ),
          Text(
            'Interest Rate: ${_interestRate.toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _interestRate,
            min: 3,
            max: 15,
            divisions: 120,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _interestRate = v),
          ),
          Text(
            'Loan Duration: $_loanYears years',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _loanYears.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _loanYears = v.toInt()),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildCalcRow(
                  theme,
                  'Principal & Interest',
                  '\$${_formatNumber((_monthlyPayment * 0.85).toInt())}',
                ),
                _buildCalcRow(
                  theme,
                  'Property Tax',
                  '\$${_formatNumber((_propertyPrice * 0.01 / 12).toInt())}',
                ),
                _buildCalcRow(
                  theme,
                  'Home Insurance',
                  '\$${_formatNumber((_propertyPrice * 0.005 / 12).toInt())}',
                ),
                const Divider(),
                _buildCalcRow(
                  theme,
                  'Total Monthly',
                  '\$${_formatNumber(_monthlyPayment.toInt())}',
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(
    ThemeData theme,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppTheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 5: AI INSIGHTS ───────────────────────────────────────────────────
  Widget _buildAiInsightsTab(ThemeData theme, AppLocalizations loc) {
    final chatState = ref.watch(chatNotifierProvider(_aiConfig));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, '🤖 AI Property Insights'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withAlpha(15),
                  AppTheme.primaryLight.withAlpha(10),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Gemini AI Analysis',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (chatState.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (chatState.response.isNotEmpty)
                  Text(chatState.response, style: theme.textTheme.bodyMedium)
                else if (!chatState.isLoading)
                  Text(
                    'Tap "Get AI Insights" to receive a comprehensive analysis of this property including investment potential, market comparison, and personalized recommendations.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: chatState.isLoading
                  ? null
                  : () {
                      ref
                          .read(chatNotifierProvider(_aiConfig).notifier)
                          .sendMessage(
                            [
                              {
                                'role': 'system',
                                'content':
                                    'You are a real estate expert for the Iraqi market. Provide concise, insightful property analysis.',
                              },
                              {
                                'role': 'user',
                                'content':
                                    'Analyze this property: $_title at $_address. Price: \$${_formatNumber(_propertyPrice.toInt())}. Area: ${_propertyArea.toInt()} m². $_bedrooms bedrooms. Type: $_propertyType. Listing: $_listingType. Provide investment potential, market comparison, pros/cons, and recommendation in 3-4 paragraphs.',
                              },
                            ],
                            parameters: {'temperature': 0.7, 'max_tokens': 600},
                          );
                    },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                chatState.isLoading ? 'Analyzing...' : 'Get AI Insights',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Quick Questions', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      'Is this a good investment?',
                      'Compare to similar properties',
                      'What increases its value?',
                      'Best time to buy?',
                    ]
                    .map(
                      (q) => GestureDetector(
                        onTap: () {
                          ref
                              .read(chatNotifierProvider(_aiConfig).notifier)
                              .sendMessage(
                                [
                                  {
                                    'role': 'system',
                                    'content':
                                        'You are a real estate expert for the Iraqi market. Be concise.',
                                  },
                                  {
                                    'role': 'user',
                                    'content':
                                        '$q Context: $_title, \$${_formatNumber(_propertyPrice.toInt())}, ${_propertyArea.toInt()} m², $_address',
                                  },
                                ],
                                parameters: {'max_tokens': 300},
                              );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          child: Text(q, style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(loc.scheduleTour),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(loc.contactSales),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final s = n.toString();
      final result = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
        result.write(s[i]);
      }
      return result.toString();
    }
    return n.toString();
  }
}

class _PriceChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withAlpha(180)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = AppTheme.primary.withAlpha(30)
      ..style = PaintingStyle.fill;
    final points = [0.4, 0.35, 0.5, 0.45, 0.6, 0.55, 0.7, 0.65, 0.8];
    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
