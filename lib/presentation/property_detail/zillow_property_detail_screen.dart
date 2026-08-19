import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Zillow Clone - Pixel-Perfect Property Detail Screen
class ZillowPropertyDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? propertyData;
  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final VoidCallback? onOpen3dHome;

  const ZillowPropertyDetailScreen({
    super.key,
    this.propertyData,
    this.onBack,
    this.onShare,
    this.onOpen3dHome,
  });

  @override
  State<ZillowPropertyDetailScreen> createState() =>
      _ZillowPropertyDetailScreenState();
}

class _ZillowPropertyDetailScreenState
    extends State<ZillowPropertyDetailScreen> {
  // Global Color Constants
  static const Color primaryBlue = Color(0xFF0052CC);
  static const Color emeraldGreen = Color(0xFF1B6B5A);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color bgGrey = Color(0xFFF2F2F2);
  static const Color tooltipBg = Color(0xFF1A1A1A);

  // Screen State
  bool _isFavorite = false;
  bool _factsExpanded = false;
  bool _whatsSpecialExpanded = false;
  int _selectedOfferStrength = 0; // 0: Strong, 1: Competitive, 2: Moderate
  int _selectedDateIndex = 0; // 0: Tue 18, 1: Wed 19, 2: Thu 20
  int _selectedTimeIndex = 0; // 0: 5:00 PM, 1: 5:30 PM, 2: 6:00 PM
  bool _wantFinancing = true;

  // Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _messageController;

  final String _address = "7761 Sagemeadow Ct, Columbus, OH 43235";
  final String _propertyImageUrl =
      "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&q=80";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: "Lofy Dono");
    _phoneController = TextEditingController(text: "(555) 019-2834");
    _emailController = TextEditingController(text: "lofydono2002@gmail.com");
    _messageController = TextEditingController(
      text: "I am interested in $_address.",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showTooltip(BuildContext context, String title, String explanation) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => entry.remove(),
        child: Container(
          color: Colors.black.withAlpha(76),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tooltipBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => entry.remove(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    explanation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: Stack(
        children: [
          // Background Grey Base
          Positioned.fill(
            child: Container(color: bgGrey),
          ),

          // CustomScrollView with SliverAppBar + Content Cards
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: 110, // Account for sticky bottom bar height
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildCard1PaymentBanner(),
                    const SizedBox(height: 12),
                    _buildCard2MainInfo(),
                    const SizedBox(height: 12),
                    _buildCard3FactsAndFeatures(),
                    const SizedBox(height: 12),
                    _buildCard4WhatsSpecial(context),
                    const SizedBox(height: 12),
                    _buildCard5UpcomingOpenHouses(),
                    const SizedBox(height: 12),
                    _buildCard6BuyAbilityPayment(),
                    const SizedBox(height: 12),
                    _buildCard7GetMortgage(),
                    const SizedBox(height: 12),
                    _buildCard8OfferInsights(),
                    const SizedBox(height: 12),
                    _buildCard9MarketValue(),
                    const SizedBox(height: 12),
                    _buildCard10PriceAndTaxHistory(),
                    const SizedBox(height: 16),
                    _buildCardClimateRisks(),
                    const SizedBox(height: 16),
                    _buildCardTravelTimes(),
                    const SizedBox(height: 16),
                    _buildCardNeighborhood(),
                    const SizedBox(height: 16),
                    _buildCardNearbySchools(),
                    const SizedBox(height: 16),
                    _buildCardHomesForYou(),
                    const SizedBox(height: 12),
                    _buildCard11TourBooking(),
                    const SizedBox(height: 12),
                    _buildCard12ContactAgentForm(),
                  ]),
                ),
              ),
            ],
          ),

          // Sticky Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyBottomBar(context),
          ),
        ],
      ),
    );
  }

  // ── SLIVER APP BAR OVERLAY ELEMENTS ─────────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: true,
      pinned: true,
      stretch: true,
      backgroundColor: bgGrey,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _propertyImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF2C3E50),
                child: const Center(
                  child: Icon(Icons.home, size: 64, color: Colors.white),
                ),
              ),
            ),
            // Gradient Overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(102),
                    Colors.transparent,
                    Colors.black.withAlpha(128),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // Top Left: White Circle Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: InkWell(
                onTap: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ),

            // Top Right Pill Container with 4 Icons
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(216),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : textPrimary,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          onPressed: () {
                            setState(() => _isFavorite = !_isFavorite);
                            Fluttertoast.showToast(
                              msg: _isFavorite
                                  ? "Saved to favorites"
                                  : "Removed from favorites",
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: textPrimary,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          onPressed: () {
                            if (widget.onShare != null) {
                              widget.onShare!();
                            } else {
                              Fluttertoast.showToast(msg: "Sharing link copied!");
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.block,
                            color: textPrimary,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          onPressed: () {
                            Fluttertoast.showToast(msg: "Listing hidden");
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: textPrimary,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Left Capsules
            Positioned(
              bottom: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Capsule 1: House for sale (white capsule with red dot)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "House for sale",
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Capsule 2: 3D Home (black capsule with 3D cube)
                  InkWell(
                    onTap: () {
                      if (widget.onOpen3dHome != null) {
                        widget.onOpen3dHome!();
                      } else {
                        _open3DTourViewerModal(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(216),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.view_in_ar, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            "3D Home",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Right: Zillow Logo Placeholder
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Z",
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        fontFamily: "monospace",
                      ),
                    ),
                    SizedBox(width: 2),
                    Text(
                      "illow",
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CARD 1: PAYMENT BANNER ───────────────────────────────────────────────
  Widget _buildCard1PaymentBanner() {
    return Card(
      color: emeraldGreen,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Est. \$2,477/mo",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                Fluttertoast.showToast(msg: "Starting pre-qualification...");
              },
              child: const Row(
                children: [
                  Text(
                    "Get pre-qualified",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CARD 2: MAIN INFO ───────────────────────────────────────────────────
  Widget _buildCard2MainInfo() {
    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "\$342,000",
              style: TextStyle(
                color: textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.bed, size: 18, color: textSecondary),
                SizedBox(width: 4),
                Text(
                  "3 beds",
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Text("|", style: TextStyle(color: textSecondary)),
                SizedBox(width: 8),
                Icon(Icons.bathtub_outlined, size: 18, color: textSecondary),
                SizedBox(width: 4),
                Text(
                  "2 baths",
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Text("|", style: TextStyle(color: textSecondary)),
                SizedBox(width: 8),
                Icon(Icons.square_foot, size: 18, color: textSecondary),
                SizedBox(width: 4),
                Text(
                  "1,558 sqft",
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _address,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Contact Button (Outlined blue)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      Fluttertoast.showToast(msg: "Contacting agent...");
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryBlue, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Contact",
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Request a Tour Button (Solid blue with subtitle)
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Fluttertoast.showToast(msg: "Tour requested!");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Request a tour",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          "as early as today at 5:00 PM",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
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
      ),
    );
  }

  // ── CARD 3: FACTS & FEATURES ─────────────────────────────────────────────
  Widget _buildCard3FactsAndFeatures() {
    final factsGrid = [
      {"icon": Icons.home_outlined, "title": "Zestimate®", "sub": "\$338,600"},
      {"icon": Icons.house_siding, "title": "Single family", "sub": "Residence"},
      {"icon": Icons.analytics_outlined, "title": "\$220/sqft", "sub": "Price/sqft"},
      {"icon": Icons.calendar_today_outlined, "title": "Built in 1983", "sub": "Year built"},
      {"icon": Icons.account_balance_wallet_outlined, "title": "HOA", "sub": "\$50/mo"},
      {"icon": Icons.landscape_outlined, "title": "0.3-acre lot", "sub": "Lot size"},
    ];

    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Facts & features",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // 2-column Grid of ListTile style items
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: factsGrid.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final item = factsGrid[index];
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item["icon"] as IconData,
                        color: primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item["title"] as String,
                              style: const TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item["sub"] as String,
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 11,
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
            ),

            if (_factsExpanded) ...[
              const Divider(height: 24),
              _buildExpandedFactsSection("Interior", [
                "Bedrooms: 3",
                "Bathrooms: 2 (Full: 2)",
                "Fireplace: Yes (Wood burning in Living Room)",
                "Flooring: Hardwood, Carpet, Ceramic Tile",
                "Basement: Full, Unfinished, Sump Pump",
              ]),
              _buildExpandedFactsSection("Cooling & Heating", [
                "Cooling: Central Air",
                "Heating: Forced Air, Natural Gas",
              ]),
              _buildExpandedFactsSection("Features", [
                "Appliances: Dishwasher, Microwave, Range/Oven, Refrigerator",
                "Interior Features: Walk-in Closet, Ceiling Fan, Open Floor Plan",
              ]),
              _buildExpandedFactsSection("Property & Parking", [
                "Property Type: Single Family Residence",
                "Parking: Attached 2-car Garage (440 sqft)",
                "Driveway: Concrete",
              ]),
              _buildExpandedFactsSection("Lot Details", [
                "Lot Size: 0.30 Acres (13,068 sqft)",
                "Parcel Number: 010-123456",
                "Zoning: Residential R-2",
              ]),
              _buildExpandedFactsSection("Utilities & Community", [
                "Utilities: Public Water, Public Sewer, Natural Gas Available",
                "Community: Sagemeadow Estates",
                "HOA Fee: \$50/month (Covers common area maintenance)",
              ]),
              _buildExpandedFactsSection("Financial & Tax", [
                "Tax Assessment: \$285,000",
                "Annual Tax Amount: \$4,210 (2025)",
              ]),
            ],

            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                setState(() => _factsExpanded = !_factsExpanded);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      _factsExpanded ? "Show less" : "Show more",
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _factsExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: primaryBlue,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedFactsSection(String title, List<String> bulletPoints) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bulletPoints
                .map(
                  (pt) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "• ",
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            pt,
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                              height: 1.3,
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
    );
  }

  // ── CARD 4: WHAT'S SPECIAL ───────────────────────────────────────────────
  Widget _buildCard4WhatsSpecial(BuildContext context) {
    const description =
        "Welcome home to 7761 Sagemeadow Ct! Beautifully maintained single family home in a peaceful cul-de-sac location in Columbus. Features a spacious open concept layout with high ceilings, updated kitchen with granite countertops, cozy fireplace, large private backyard with mature trees, and an attached two-car garage. Conveniently located near top-rated schools, parks, shopping, and dining.";

    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's special",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _whatsSpecialExpanded
                  ? description
                  : (description.length > 150
                      ? "${description.substring(0, 150)}..."
                      : description),
              style: const TextStyle(
                color: textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(
                  () => _whatsSpecialExpanded = !_whatsSpecialExpanded,
                );
              },
              child: Row(
                children: [
                  Text(
                    _whatsSpecialExpanded ? "Show less" : "Show more",
                    style: const TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _whatsSpecialExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: primaryBlue,
                    size: 18,
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // UX Detail: Row with 3 statistics with underline & tooltip behavior
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildUnderlinedStat(
                  context,
                  "8 days on Zillow",
                  "Days on Zillow",
                  "Number of consecutive days this property listing has been actively available for sale on Zillow.",
                ),
                _buildUnderlinedStat(
                  context,
                  "929 views",
                  "Views",
                  "Total number of times shoppers have viewed the detail page for this property.",
                ),
                _buildUnderlinedStat(
                  context,
                  "50 saves",
                  "Saves",
                  "Number of Zillow users who have saved this home to their favorites list.",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnderlinedStat(
    BuildContext context,
    String label,
    String title,
    String tooltipText,
  ) {
    return GestureDetector(
      onTap: () => _showTooltip(context, title, tooltipText),
      onLongPress: () => _showTooltip(context, title, tooltipText),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: textSecondary,
              width: 1.2,
              style: BorderStyle.solid,
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ── CARD 5: UPCOMING OPEN HOUSES ─────────────────────────────────────────
  Widget _buildCard5UpcomingOpenHouses() {
    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Upcoming open houses",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildOpenHouseCard("Tue, Aug 18", "9:00 AM - 7:00 PM"),
                  const SizedBox(width: 12),
                  _buildOpenHouseCard("Wed, Aug 19", "9:00 AM - 7:00 PM"),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Fluttertoast.showToast(msg: "Added open house to calendar!");
              },
              child: const Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: primaryBlue,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Add to calendar",
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  Widget _buildOpenHouseCard(String date, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, color: emeraldGreen, size: 16),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(color: textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── CARD 6: BUYABILITY PAYMENT ───────────────────────────────────────────
  Widget _buildCard6BuyAbilityPayment() {
    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "BuyAbility℠ payment",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  "Est. payment",
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _showTooltip(
                      context,
                      "Est. Payment Breakdown",
                      "Includes estimated principal & interest, property taxes based on local rates, plus home insurance and other potential costs.",
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "\$2,477/mo",
              style: TextStyle(
                color: textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),

            // Custom Segmented Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    Expanded(
                      flex: 60,
                      child: Container(color: primaryBlue),
                    ),
                    Expanded(
                      flex: 30,
                      child: Container(color: const Color(0xFF7B1FA2)),
                    ),
                    Expanded(
                      flex: 10,
                      child: Container(color: const Color(0xFFD32F2F)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Legend
            _buildLegendItem(
              primaryBlue,
              "Principal & interest",
              "\$1,753",
            ),
            const SizedBox(height: 6),
            _buildLegendItem(
              const Color(0xFF7B1FA2),
              "Taxes",
              "\$610",
            ),
            const SizedBox(height: 6),
            _buildLegendItem(
              const Color(0xFFD32F2F),
              "Other costs",
              "\$114",
            ),

            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Powered by Zillow Home Loans",
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                InkWell(
                  onTap: () {
                    Fluttertoast.showToast(msg: "Customize payment options");
                  },
                  child: const Text(
                    "Customize this payment",
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  Widget _buildLegendItem(Color dotColor, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: textPrimary, fontSize: 13),
            ),
          ],
        ),
        Text(
          amount,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ── CARD 7: GET A MORTGAGE WITH US ───────────────────────────────────────
  Widget _buildCard7GetMortgage() {
    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Get a mortgage with us",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: bgGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "NMLS #10287",
                    style: TextStyle(color: textSecondary, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: primaryBlue,
                    unselectedLabelColor: textSecondary,
                    indicatorColor: primaryBlue,
                    tabs: [
                      Tab(text: "30-year fixed"),
                      Tab(text: "30-year FHA"),
                      Tab(text: "30-year VA"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: TabBarView(
                      children: [
                        _buildMortgageRatesBox("6.750%", "6.902%"),
                        _buildMortgageRatesBox("6.250%", "6.815%"),
                        _buildMortgageRatesBox("6.125%", "6.340%"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Fluttertoast.showToast(msg: "Get pre-qualified process");
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryBlue, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Get pre-qualified",
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMortgageRatesBox(String rate, String apr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Our rate",
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                rate,
                style: const TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Our APR",
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                apr,
                style: const TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── CARD 8: OFFER INSIGHTS ───────────────────────────────────────────────
  Widget _buildCard8OfferInsights() {
    final strengths = ["Strong", "Competitive", "Moderate"];
    final targetPrices = ["\$351K+", "\$345K+", "\$342K"];

    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Offer Insights",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Choose an offer strength",
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Radio-style Buttons (Rounded Capsules)
            Row(
              children: List.generate(strengths.length, (index) {
                final isSelected = _selectedOfferStrength == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedOfferStrength = index);
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue.withAlpha(25) : bgGrey,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primaryBlue : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          strengths[index],
                          style: TextStyle(
                            color: isSelected ? primaryBlue : textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "List price: \$342K",
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      targetPrices[_selectedOfferStrength],
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: emeraldGreen, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "Over 90% chance of a winning offer",
                        style: TextStyle(
                          color: emeraldGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Text(
              "Sellers market",
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),

            const SizedBox(height: 16),
            // Bottom Locked Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgGrey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: textSecondary, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Unlock more with BuyAbility",
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Fluttertoast.showToast(msg: "Setting up BuyAbility...");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      "Set up BuyAbility",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  // ── CARD 9: MARKET VALUE ─────────────────────────────────────────────────
  Widget _buildCard9MarketValue() {
    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Market value",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "Zestimate® \$338,600",
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Text(
                  "+4% in the last 2 years",
                  style: TextStyle(
                    color: emeraldGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Text(
                  "\$339K",
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // fl_chart Gradient Line Chart
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            "\$${value.toInt()}K",
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text(
                                "02/26/24",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                ),
                              );
                            case 1:
                              return const Text(
                                "08/24/25",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                ),
                              );
                            case 2:
                              return const Text(
                                "02/19/26",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                ),
                              );
                          }
                          return const Text("");
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 2,
                  minY: 320,
                  maxY: 360,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 325),
                        FlSpot(1, 332),
                        FlSpot(2, 338.6),
                      ],
                      isCurved: true,
                      color: emeraldGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          if (index == 2) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: emeraldGreen,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          }
                          return FlDotCirclePainter(
                            radius: 3,
                            color: emeraldGreen,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            emeraldGreen.withAlpha(76),
                            emeraldGreen.withAlpha(0),
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

            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Fluttertoast.showToast(msg: "Loading market details...");
              },
              child: const Row(
                children: [
                  Text(
                    "Show more",
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: primaryBlue,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CARD 10: PRICE & TAX HISTORY ─────────────────────────────────────────
  Widget _buildCard10PriceAndTaxHistory() {
    final priceHistory = [
      {"date": "8/10/2026", "event": "Listed for sale", "price": "\$342,000"},
      {"date": "5/14/2022", "event": "Sold", "price": "\$295,000"},
      {"date": "4/02/2022", "event": "Listing removed", "price": "\$299,000"},
      {"date": "2/10/2022", "event": "Listed for sale", "price": "\$299,000"},
    ];

    final taxHistory = [
      {"date": "2025", "event": "Tax Assessment", "price": "\$4,210"},
      {"date": "2024", "event": "Tax Assessment", "price": "\$3,980"},
      {"date": "2023", "event": "Tax Assessment", "price": "\$3,820"},
    ];

    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Price & tax history",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: primaryBlue,
                    unselectedLabelColor: textSecondary,
                    indicatorColor: primaryBlue,
                    tabs: [
                      Tab(text: "Price history"),
                      Tab(text: "Tax history"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: TabBarView(
                      children: [
                        _buildHistoryTable(priceHistory),
                        _buildHistoryTable(taxHistory),
                      ],
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

  Widget _buildHistoryTable(List<Map<String, String>> data) {
    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(2.0),
          2: FlexColumnWidth(1.2),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: bgGrey, width: 2)),
            ),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Date",
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Event type",
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Price",
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          ...data.map(
            (row) => TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: bgGrey, width: 1)),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    row["date"]!,
                    style: const TextStyle(color: textPrimary, fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    row["event"]!,
                    style: const TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    row["price"]!,
                    style: const TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CARD 11: TOUR WITH A BUYER'S AGENT ─────────────────────────────────
  // ── ADDENDUM 1: CLIMATE RISKS CARD ────────────────────────────────────────
  Widget _buildCardClimateRisks() {
    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Climate risks.",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(color: textPrimary, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(
                    text:
                        "Explore flood, wildfire, and other predictive climate risk information for this property on ",
                  ),
                  TextSpan(
                    text: "First Street®",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: "."),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Flood zone.",
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "In FEMA Zone X (unshaded), a minimal-risk flood area.",
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADDENDUM 2: TRAVEL TIMES CARD ─────────────────────────────────────────
  Widget _buildCardTravelTimes() {
    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Travel times.",
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "INRIX",
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.directions_car_outlined, color: textSecondary),
                  hintText: "Add a destination",
                  hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADDENDUM 3: NEIGHBORHOOD CARD ─────────────────────────────────────────
  Widget _buildCardNeighborhood() {
    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Neighborhood: Summerwood.",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFFE8ECEF),
                      child: CustomPaint(
                        painter: _MiniMapPainter(),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.home,
                          color: primaryBlue,
                          size: 32,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Text(
                            "Summerwood",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "Show more",
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADDENDUM 4: NEARBY SCHOOLS CARD ───────────────────────────────────────
  Widget _buildCardNearbySchools() {
    final schools = [
      {
        'name': 'Granby Elementary School',
        'sub': 'Grades K-5 • 0.8 miles',
        'test': 'Test score 6/10',
        'progress': 'Student progress 3/10',
        'rating': '5/10',
      },
      {
        'name': 'McCord Middle School',
        'sub': 'Grades 6-8 • 1.4 miles',
        'test': 'Test score 8/10',
        'progress': 'Student progress 6/10',
        'rating': '7/10',
      },
      {
        'name': 'Worthington Kilbourne High School',
        'sub': 'Grades 9-12 • 2.1 miles',
        'test': 'Test score 9/10',
        'progress': 'Student progress 7/10',
        'rating': '8/10',
      },
    ];

    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nearby Schools.",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: const [
                Icon(Icons.info_outline, size: 14, color: textSecondary),
                SizedBox(width: 4),
                Text(
                  "Source: GreatSchools®",
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...schools.map((school) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            school['sub']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${school['test']} • ${school['progress']}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF444444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF2C7A5D),
                      child: Text(
                        school['rating']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── ADDENDUM 5: HOMES FOR YOU CARD ────────────────────────────────────────
  Widget _buildCardHomesForYou() {
    final recommendedHomes = [
      {
        'image':
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=500',
        'price': '\$349,000',
        'details': '3 bd | 2.5 ba | 1,465 sqft',
        'address': '1449 Tall Pine Ct, Columbus...',
      },
      {
        'image':
            'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=500',
        'price': '\$412,500',
        'details': '4 bd | 3 ba | 2,100 sqft',
        'address': '7822 Summerwood Dr, Columbus...',
      },
      {
        'image':
            'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=500',
        'price': '\$285,000',
        'details': '2 bd | 2 ba | 1,120 sqft',
        'address': '501 Oak Ave, Columbus...',
      },
    ];

    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Homes for you.",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedHomes.length,
                itemBuilder: (context, index) {
                  final home = recommendedHomes[index];
                  return Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Image.network(
                              home['image']!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "For sale",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white70,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_border,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryBlue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Text(
                                  "MLS",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                home['price']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                home['details']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                home['address']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    "MLS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Columbus and Central Ohio Regional MLS Rasmus Real Estate Group, Inc...",
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "IDX information is provided exclusively for personal, non-commercial use and may not be used for any purpose other than to identify prospective properties consumers may be interested in purchasing.",
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard11TourBooking() {
    final dates = [
      {"day": "Tue", "date": "18 Aug"},
      {"day": "Wed", "date": "19 Aug"},
      {"day": "Thu", "date": "20 Aug"},
    ];

    final times = ["5:00 PM", "5:30 PM", "6:00 PM"];

    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tour with a buyer's agent",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Grey Info Box with Lightbulb
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: primaryBlue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Go on a personalized tour of this home with a local buyer's agent.",
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              "Select a date",
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // Date Picker (3 square boxes)
            Row(
              children: List.generate(dates.length, (index) {
                final isSelected = _selectedDateIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDateIndex = index),
                    child: Container(
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE3F2FD) : bgGrey,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? primaryBlue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dates[index]["day"]!,
                            style: TextStyle(
                              color: isSelected ? primaryBlue : textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dates[index]["date"]!,
                            style: TextStyle(
                              color: isSelected ? primaryBlue : textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),
            const Text(
              "Select a time",
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // Time Picker (3 pill buttons)
            Row(
              children: List.generate(times.length, (index) {
                final isSelected = _selectedTimeIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTimeIndex = index),
                    child: Container(
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue : bgGrey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          times[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final date = dates[_selectedDateIndex];
                  final time = times[_selectedTimeIndex];
                  Fluttertoast.showToast(
                    msg: "Tour scheduled for ${date['day']} ${date['date']} at $time!",
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CARD 12: CONTACT AGENT FORM ──────────────────────────────────────────
  Widget _buildCard12ContactAgentForm() {
    return Card(
      color: cardBg,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contact a buyer's agent",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildFormField("Name *", _nameController),
            const SizedBox(height: 12),
            _buildFormField("Phone *", _phoneController, isPhone: true),
            const SizedBox(height: 12),
            _buildFormField("Email *", _emailController, isEmail: true),
            const SizedBox(height: 12),
            _buildFormField("Message", _messageController, maxLines: 3),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Fluttertoast.showToast(msg: "Message sent to agent!");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _wantFinancing,
                  activeColor: primaryBlue,
                  onChanged: (v) {
                    setState(() => _wantFinancing = v ?? false);
                  },
                ),
                const Expanded(
                  child: Text(
                    "I want financing information",
                    style: TextStyle(color: textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Text(
              "By pressing Next, you agree that Zillow Group and its real estate professionals may call/text you about your inquiry, which may involve the use of automated means and prerecorded voices. Consent is not a condition of purchasing any property, goods or services. Message/data rates may apply. Terms of Use & Privacy Policy.",
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Fluttertoast.showToast(msg: "Calling local agent...");
              },
              child: const Row(
                children: [
                  Icon(Icons.phone, color: primaryBlue, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "Ready to talk now? Call a local agent. (833) 404-2614",
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
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

  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    bool isEmail = false,
    bool isPhone = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: true,
          maxLines: maxLines,
          keyboardType: isEmail
              ? TextInputType.emailAddress
              : (isPhone ? TextInputType.phone : TextInputType.text),
          style: const TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: bgGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── STICKY BOTTOM NAVIGATION BAR ─────────────────────────────────────────
  void _open3DTourViewerModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return const _TourViewerModal();
      },
    );
  }

  Widget _buildStickyBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Button: Contact (Outlined blue, weight 1)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () {
                Fluttertoast.showToast(msg: "Contacting agent...");
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryBlue, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Contact",
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right Button: Request a tour (Solid blue, weight 2)
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Fluttertoast.showToast(msg: "Requesting a tour...");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Request a tour",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "as early as today at 5:00 PM",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
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
}

class _TourViewerModal extends StatefulWidget {
  const _TourViewerModal();

  @override
  State<_TourViewerModal> createState() => _TourViewerModalState();
}

class _TourViewerModalState extends State<_TourViewerModal> {
  bool _isFloorPlanView = false;
  int _selectedFloor = 1; // 1 or 2
  int _current3DStep = 0; // 0: Entrance, 1: Living room
  bool _isFavorited = false;

  final List<String> _3dImages = [
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200',
    'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=1200',
  ];

  final List<String> _3dLabels = ['Entrance', 'Living room', 'Kitchen'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with 5 icons
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.blue, size: 28),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.image_outlined, color: Colors.white, size: 22),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.crop_free, color: Colors.white, size: 22),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFloorPlanView = !_isFloorPlanView;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: _isFloorPlanView
                                ? const Border(bottom: BorderSide(color: Colors.blue, width: 2))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.map_outlined,
                                color: _isFloorPlanView ? Colors.blue : Colors.white,
                                size: 22,
                              ),
                              if (_isFloorPlanView) ...[
                                const SizedBox(width: 4),
                                const Text(
                                  'Floor plan',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isFavorited = !_isFavorited;
                          });
                        },
                        icon: Icon(
                          _isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorited ? Colors.red : Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Main Content Area
            Expanded(
              child: _isFloorPlanView
                  ? _buildFloorPlanContent()
                  : _build3DWalkthroughContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DWalkthroughContent() {
    return Stack(
      children: [
        InteractiveViewer(
          minScale: 0.8,
          maxScale: 3.5,
          child: SizedBox.expand(
            child: Image.network(
              _3dImages[_current3DStep],
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Floating pill top-center over image
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(200),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _3dLabels[_current3DStep],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        // Bottom interaction layer
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Living room button / nav arrow
              GestureDetector(
                onTap: () {
                  setState(() {
                    _current3DStep = (_current3DStep + 1) % _3dImages.length;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _3dLabels[(_current3DStep + 1) % _3dLabels.length],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white38,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Step progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _3dImages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _current3DStep ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _current3DStep
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloorPlanContent() {
    return Column(
      children: [
        // Floor Toggle
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: const Color(0xFF1E1E1E),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFloorButton(1, 'Floor 1'),
              const SizedBox(width: 16),
              _buildFloorButton(2, 'Floor 2'),
            ],
          ),
        ),
        // Floor Plan Interactive Map
        Expanded(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: CustomPaint(
                    painter: _FloorPlanPainter(floor: _selectedFloor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloorButton(int floor, String label) {
    final isSelected = _selectedFloor == floor;
    return GestureDetector(
      onTap: () => setState(() => _selectedFloor = floor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white54,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _FloorPlanPainter extends CustomPainter {
  final int floor;
  _FloorPlanPainter({required this.floor});

  @override
  void paint(Canvas canvas, Size size) {
    final wallPaint = Paint()
      ..color = const Color(0xFF0F4C81) // Thick blue walls
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Background room fills and walls
    if (floor == 1) {
      // Living Room
      final rect1 = Rect.fromLTWH(10, 10, size.width * 0.55, size.height * 0.45);
      canvas.drawRect(rect1, fillPaint);
      canvas.drawRect(rect1, wallPaint);
      _drawText(canvas, 'Living Room\n14\'2" x 16\'8"', rect1.center);

      // Dining Room
      final rect2 = Rect.fromLTWH(size.width * 0.55, 10, size.width * 0.4, size.height * 0.45);
      canvas.drawRect(rect2, fillPaint);
      canvas.drawRect(rect2, wallPaint);
      _drawText(canvas, 'Dining Room\n9\'5" x 10\'6"', rect2.center);

      // Kitchen
      final rect3 = Rect.fromLTWH(10, size.height * 0.45, size.width * 0.5, size.height * 0.5);
      canvas.drawRect(rect3, fillPaint);
      canvas.drawRect(rect3, wallPaint);
      _drawText(canvas, 'Kitchen\n11\'0" x 12\'4"', rect3.center);

      // Garage
      final rect4 = Rect.fromLTWH(size.width * 0.5, size.height * 0.45, size.width * 0.45, size.height * 0.5);
      canvas.drawRect(rect4, fillPaint);
      canvas.drawRect(rect4, wallPaint);
      _drawText(canvas, 'Garage\n18\'0" x 20\'0"', rect4.center);

      // Interactive Blue Dots
      canvas.drawCircle(rect1.center + const Offset(15, 15), 6, dotPaint);
      canvas.drawCircle(rect3.center + const Offset(-10, 10), 6, dotPaint);
    } else {
      // Primary Bedroom
      final rect1 = Rect.fromLTWH(10, 10, size.width * 0.6, size.height * 0.5);
      canvas.drawRect(rect1, fillPaint);
      canvas.drawRect(rect1, wallPaint);
      _drawText(canvas, 'Primary Bedroom\n15\'0" x 14\'2"', rect1.center);

      // Bathroom
      final rect2 = Rect.fromLTWH(size.width * 0.6, 10, size.width * 0.35, size.height * 0.3);
      canvas.drawRect(rect2, fillPaint);
      canvas.drawRect(rect2, wallPaint);
      _drawText(canvas, 'Bathroom', rect2.center);

      // Laundry Room
      final rect3 = Rect.fromLTWH(size.width * 0.6, size.height * 0.3, size.width * 0.35, size.height * 0.2);
      canvas.drawRect(rect3, fillPaint);
      canvas.drawRect(rect3, wallPaint);
      _drawText(canvas, 'Laundry', rect3.center);

      // Bedroom 2
      final rect4 = Rect.fromLTWH(10, size.height * 0.5, size.width * 0.45, size.height * 0.45);
      canvas.drawRect(rect4, fillPaint);
      canvas.drawRect(rect4, wallPaint);
      _drawText(canvas, 'Bedroom 2\n11\'2" x 10\'8"', rect4.center);

      // Bedroom 3
      final rect5 = Rect.fromLTWH(size.width * 0.45, size.height * 0.5, size.width * 0.5, size.height * 0.45);
      canvas.drawRect(rect5, fillPaint);
      canvas.drawRect(rect5, wallPaint);
      _drawText(canvas, 'Bedroom 3\n10\'5" x 11\'0"', rect5.center);

      // Interactive Blue Dots
      canvas.drawCircle(rect1.center + const Offset(0, 10), 6, dotPaint);
      canvas.drawCircle(rect4.center, 6, dotPaint);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0xFF0F4C81),
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter oldDelegate) => oldDelegate.floor != floor;
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE8ECEF);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final highwayPaint = Paint()
      ..color = const Color(0xFFF9D8A7)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    // Highway 270
    final hPath = Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(size.width * 0.3, size.height * 0.25, size.width * 0.7, size.height * 0.45, size.width, size.height * 0.4);
    canvas.drawPath(hPath, highwayPaint);

    // Other roads
    final rPath1 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.5, size.height);
    canvas.drawPath(rPath1, roadPaint);

    final rPath2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.7);
    canvas.drawPath(rPath2, roadPaint);

    // Highway 270 Label
    const textStyle = TextStyle(
      color: Color(0xFF8C6430),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
    const textSpan = TextSpan(text: 'Hwy 270', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.2, size.height * 0.22));
  }

  @override
  bool shouldRepaint(_) => false;
}
