import 'dart:async';

import '../../../core/app_export.dart';

// Anatomy locked: 3-card auto-rotating carousel
class AdCarouselWidget extends StatefulWidget {
  const AdCarouselWidget({super.key});

  @override
  State<AdCarouselWidget> createState() => _AdCarouselWidgetState();
}

class _AdCarouselWidgetState extends State<AdCarouselWidget> {
  // TODO: Replace with [Riverpod/Bloc] for production — connect to get_properties_page_ads RPC
  final PageController _pageController = PageController(
    viewportFraction: 0.88,
    initialPage: 0,
  );
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  static const List<Map<String, dynamic>> _adMaps = [
    {
      'id': 'ad_001',
      'title': 'Professional Moving Services',
      'subtitle': 'Stress-free relocation across Iraq',
      'ctaLabel': 'Get Quote',
      'iconName': 'transfer_within_a_station',
      'gradientStart': 0xFF1565C0,
      'gradientEnd': 0xFF42A5F5,
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_19979b90d-1775119939977.png',
      'semanticLabel': 'Professional movers carrying furniture boxes',
    },
    {
      'id': 'ad_002',
      'title': 'Home Beautification',
      'subtitle': 'Interior design & renovation experts',
      'ctaLabel': 'Explore',
      'iconName': 'home_work',
      'gradientStart': 0xFF00897B,
      'gradientEnd': 0xFF4DB6AC,
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1da4188b4-1769300661655.png',
      'semanticLabel':
          'Beautifully renovated modern kitchen with white cabinets',
    },
    {
      'id': 'ad_003',
      'title': 'Property Insurance',
      'subtitle': 'Protect your investment with full coverage',
      'ctaLabel': 'Learn More',
      'iconName': 'verified_user',
      'gradientStart': 0xFF7B1FA2,
      'gradientEnd': 0xFFBA68C8,
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_171440452-1770039291221.png',
      'semanticLabel': 'Property insurance document with house model on desk',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _adMaps.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _adMaps.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              final ad = _adMaps[i];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  right: 12,
                  top: i == _currentPage ? 0 : 6,
                  bottom: i == _currentPage ? 0 : 6,
                ),
                child: _AdCard(ad: ad),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_adMaps.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentPage ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? AppTheme.primary
                    : AppTheme.primary.withAlpha(64),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AdCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  const _AdCard({required this.ad});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Color(ad['gradientStart'] as int),
            Color(ad['gradientEnd'] as int),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(ad['gradientStart'] as int).withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background image with opacity
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Opacity(
                opacity: 0.15,
                child: CustomImageWidget(
                  imageUrl: ad['imageUrl'] as String,
                  fit: BoxFit.cover,
                  semanticLabel: ad['semanticLabel'] as String,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: ad['iconName'] as String,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ad['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ad['subtitle'] as String,
                        style: TextStyle(
                          color: Colors.white.withAlpha(217),
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ad['ctaLabel'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(ad['gradientStart'] as int),
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
}
