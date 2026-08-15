import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class RatingsReviewsScreen extends StatefulWidget {
  final Map<String, dynamic>? property;
  const RatingsReviewsScreen({super.key, this.property});

  @override
  State<RatingsReviewsScreen> createState() => _RatingsReviewsScreenState();
}

class _RatingsReviewsScreenState extends State<RatingsReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedRatingFilter = 0; // 0 = all
  int _newRating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;
  String _sortBy = 'recent';

  final List<Map<String, dynamic>> _reviews = [
    {
      'id': '1',
      'author': 'Mohammed Al-Rashidi',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1bcc020ad-1765692423049.png',
      'rating': 5,
      'date': '2 days ago',
      'title': 'Excellent property, highly recommended',
      'body':
          'The villa exceeded all our expectations. The location is perfect, the finishes are top quality, and the Madar team was incredibly professional throughout the entire process.',
      'property': 'Luxury Villa — Mansour',
      'type': 'Buyer',
      'helpful': 24,
      'verified': true,
      'tags': ['Great Location', 'Professional Service', 'Worth the Price'],
    },
    {
      'id': '2',
      'author': 'Fatima Al-Hamdani',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1412fb638-1786828391447.png',
      'rating': 4,
      'date': '1 week ago',
      'title': 'Great apartment, minor issues resolved quickly',
      'body':
          'The apartment in Karrada is exactly as described. The team was responsive and resolved a small maintenance issue within 24 hours. Very satisfied overall.',
      'property': 'Modern Apartment — Karrada',
      'type': 'Renter',
      'helpful': 18,
      'verified': true,
      'tags': ['Responsive Team', 'Good Value'],
    },
    {
      'id': '3',
      'author': 'Omar Al-Tamimi',
      'avatar':
          'https://images.unsplash.com/photo-1655632587075-0ff3b8585092',
      'rating': 5,
      'date': '2 weeks ago',
      'title': 'Smooth transaction from start to finish',
      'body':
          'The entire buying process was transparent and well-organized. The digital contract system is brilliant — no paperwork hassle. The escrow system gave us full confidence.',
      'property': 'Family Home — Adhamiyah',
      'type': 'Buyer',
      'helpful': 31,
      'verified': true,
      'tags': ['Transparent Process', 'Digital Contract', 'Trustworthy'],
    },
    {
      'id': '4',
      'author': 'Layla Al-Zubaidi',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1df2573b2-1772067312738.png',
      'rating': 3,
      'date': '3 weeks ago',
      'title': 'Good service but took longer than expected',
      'body':
          'The property itself is great and the team is professional. However, the verification process took a bit longer than we anticipated. Would still recommend Madar.',
      'property': 'Studio Apartment — Jadriyah',
      'type': 'Renter',
      'helpful': 9,
      'verified': false,
      'tags': ['Good Property', 'Slow Verification'],
    },
    {
      'id': '5',
      'author': 'Khalid Al-Obeidi',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1c53c5c54-1772094874983.png',
      'rating': 5,
      'date': '1 month ago',
      'title': 'Best real estate platform in Iraq',
      'body':
          'I have used multiple platforms before but Madar is on another level. The property listings are accurate, the photos are real, and the team is always available.',
      'property': 'Commercial Space — Zayouna',
      'type': 'Buyer',
      'helpful': 47,
      'verified': true,
      'tags': ['Best Platform', 'Accurate Listings', 'Always Available'],
    },
    {
      'id': '6',
      'author': 'Nadia Al-Saadi',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_18eed1942-1786828392527.png',
      'rating': 4,
      'date': '1 month ago',
      'title': 'Professional team, beautiful property',
      'body':
          'The villa photos matched reality perfectly. The agent was knowledgeable and helped us negotiate a fair price. The digital signing process was very convenient.',
      'property': 'Luxury Villa — Mansour',
      'type': 'Buyer',
      'helpful': 22,
      'verified': true,
      'tags': ['Accurate Photos', 'Fair Negotiation'],
    },
    {
      'id': '7',
      'author': 'Hassan Al-Jubouri',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_15aaa1063-1769307619388.png',
      'rating': 2,
      'date': '6 weeks ago',
      'title': 'Property had issues not mentioned in listing',
      'body':
          'The apartment had some plumbing issues that were not disclosed in the listing. The team did help resolve it but it caused delays. Transparency needs improvement.',
      'property': 'Modern Apartment — Karrada',
      'type': 'Renter',
      'helpful': 15,
      'verified': true,
      'tags': ['Disclosure Issues'],
    },
  ];

  List<Map<String, dynamic>> get _filteredReviews {
    var filtered = _selectedRatingFilter == 0
        ? _reviews
        : _reviews.where((r) => r['rating'] == _selectedRatingFilter).toList();

    if (_sortBy == 'helpful') {
      filtered = [...filtered]
        ..sort((a, b) => (b['helpful'] as int).compareTo(a['helpful'] as int));
    } else if (_sortBy == 'rating_high') {
      filtered = [...filtered]
        ..sort((a, b) => (b['rating'] as int).compareTo(a['rating'] as int));
    } else if (_sortBy == 'rating_low') {
      filtered = [...filtered]
        ..sort((a, b) => (a['rating'] as int).compareTo(b['rating'] as int));
    }
    return filtered;
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(0.0, (sum, r) => sum + (r['rating'] as int)) /
        _reviews.length;
  }

  Map<int, int> get _ratingDistribution {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      dist[r['rating'] as int] = (dist[r['rating'] as int] ?? 0) + 1;
    }
    return dist;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ratings & Reviews',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showWriteReviewSheet,
            icon: const Icon(
              Icons.edit_outlined,
              size: 16,
              color: Color(0xFFFFB74D),
            ),
            label: Text(
              'Write Review',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFFB74D),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFB74D),
          indicatorWeight: 2,
          labelColor: const Color(0xFFFFB74D),
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'All Reviews'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReviewsTab(), _buildSummaryTab()],
      ),
    );
  }

  Widget _buildReviewsTab() {
    final filtered = _filteredReviews;
    return Column(
      children: [
        // Rating summary bar
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF111827),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    _avgRating.toStringAsFixed(1),
                    style: GoogleFonts.dmSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  _buildStarRow(_avgRating.round(), size: 16),
                  const SizedBox(height: 4),
                  Text(
                    '${_reviews.length} reviews',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = _ratingDistribution[star] ?? 0;
                    final pct = _reviews.isEmpty
                        ? 0.0
                        : count / _reviews.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFB74D),
                            size: 10,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: Colors.white.withAlpha(20),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFFB74D),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$count',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
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
          ),
        ),
        // Filters
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF0A0E1A),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [0, 5, 4, 3, 2, 1].map((r) {
                      final sel = _selectedRatingFilter == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRatingFilter = r),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFFFFB74D)
                                    : Colors.white12,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (r > 0) ...[
                                  Icon(
                                    Icons.star,
                                    size: 11,
                                    color: sel
                                        ? const Color(0xFF0A0E1A)
                                        : const Color(0xFFFFB74D),
                                  ),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  r == 0 ? 'All' : '$r',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? const Color(0xFF0A0E1A)
                                        : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _showSortSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sort, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Sort',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Reviews list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _buildReviewCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] as int;
    final tags = review['tags'] as List<String>;

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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFB74D).withAlpha(102),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    review['avatar'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white.withAlpha(26),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white38,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review['author'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (review['verified'] == true) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF4FC3F7),
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            review['type'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          review['date'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStarRow(rating, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['title'] as String,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            review['body'] as String,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.white60,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          // Property tag
          Row(
            children: [
              const Icon(Icons.home_outlined, color: Colors.white38, size: 13),
              const SizedBox(width: 4),
              Text(
                review['property'] as String,
                style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFB74D).withAlpha(51),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFB74D),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_outlined,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful (${review['helpful']})',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Report',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.white24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final dist = _ratingDistribution;
    final verifiedCount = _reviews.where((r) => r['verified'] == true).length;
    final buyerCount = _reviews.where((r) => r['type'] == 'Buyer').length;
    final renterCount = _reviews.where((r) => r['type'] == 'Renter').length;

    // Collect all tags
    final tagCounts = <String, int>{};
    for (final r in _reviews) {
      for (final tag in r['tags'] as List<String>) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall rating card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1200), Color(0xFF111827)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFB74D).withAlpha(77)),
          ),
          child: Column(
            children: [
              Text(
                _avgRating.toStringAsFixed(1),
                style: GoogleFonts.dmSans(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              _buildStarRow(_avgRating.round(), size: 24),
              const SizedBox(height: 8),
              Text(
                'Based on ${_reviews.length} reviews',
                style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryChip(
                    '$verifiedCount',
                    'Verified',
                    Icons.verified,
                    const Color(0xFF4FC3F7),
                  ),
                  _buildSummaryChip(
                    '$buyerCount',
                    'Buyers',
                    Icons.shopping_bag_outlined,
                    const Color(0xFF81C784),
                  ),
                  _buildSummaryChip(
                    '$renterCount',
                    'Renters',
                    Icons.key_outlined,
                    const Color(0xFFCE93D8),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Rating breakdown
        Container(
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
                'Rating Breakdown',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              ...[5, 4, 3, 2, 1].map((star) {
                final count = dist[star] ?? 0;
                final pct = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < star ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFB74D),
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.white.withAlpha(20),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFB74D),
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$count',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Top mentioned tags
        Container(
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
                'Most Mentioned',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedTags
                    .take(10)
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB74D).withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFB74D).withAlpha(51),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              e.key,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFFB74D),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB74D).withAlpha(51),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${e.value}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: const Color(0xFFFFB74D),
                                ),
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
        ),
      ],
    );
  }

  Widget _buildStarRow(int rating, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: const Color(0xFFFFB74D),
          size: size,
        ),
      ),
    );
  }

  Widget _buildSummaryChip(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white38),
        ),
      ],
    );
  }

  void _showWriteReviewSheet() {
    setState(() => _newRating = 0);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Write a Review',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your Rating',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    5,
                    (i) => GestureDetector(
                      onTap: () => setModalState(() => _newRating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          i < _newRating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFB74D),
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Share your experience with this property...',
                      hintStyle: GoogleFonts.dmSans(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _newRating == 0
                        ? null
                        : () {
                            setModalState(() => _isSubmitting = true);
                            Future.delayed(const Duration(seconds: 1), () {
                              Navigator.pop(ctx);
                              _reviewController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Review submitted successfully!',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF81C784),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB74D),
                      foregroundColor: const Color(0xFF0A0E1A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Submit Review',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort Reviews',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              ('recent', 'Most Recent'),
              ('helpful', 'Most Helpful'),
              ('rating_high', 'Highest Rating'),
              ('rating_low', 'Lowest Rating'),
            ].map(
              (opt) => ListTile(
                onTap: () {
                  setState(() => _sortBy = opt.$1);
                  Navigator.pop(ctx);
                },
                leading: Icon(
                  _sortBy == opt.$1
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _sortBy == opt.$1
                      ? const Color(0xFFFFB74D)
                      : Colors.white38,
                  size: 20,
                ),
                title: Text(
                  opt.$2,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: _sortBy == opt.$1 ? Colors.white : Colors.white60,
                    fontWeight: _sortBy == opt.$1
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
