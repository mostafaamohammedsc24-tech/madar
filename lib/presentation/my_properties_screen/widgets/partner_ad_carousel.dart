import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../partner_whatsapp.dart';

class PartnerAdCarousel extends StatefulWidget {
  const PartnerAdCarousel({super.key});

  @override
  State<PartnerAdCarousel> createState() => _PartnerAdCarouselState();
}

class _PartnerAdCarouselState extends State<PartnerAdCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final ads = _ads(loc);

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: ads.length,
          itemBuilder: (context, index, _) {
            return _PartnerAdCard(
              ad: ads[index],
              onTap: PartnerWhatsApp.openChat,
            );
          },
          options: CarouselOptions(
            height: 168,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 650),
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            enableInfiniteScroll: true,
            padEnds: true,
            onPageChanged: (i, _) => setState(() => _index = i),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(ads.length, (i) {
            final selected = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary
                    : AppTheme.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }

  List<_PartnerAd> _ads(AppLocalizations loc) {
    return [
      _PartnerAd(
        icon: Icons.local_shipping_outlined,
        title: loc.adMovingTitle,
        subtitle: loc.adMovingSubtitle,
        colors: const [Color(0xFF0D47A1), Color(0xFF1565C0)],
      ),
      _PartnerAd(
        icon: Icons.chair_outlined,
        title: loc.adStagingTitle,
        subtitle: loc.adStagingSubtitle,
        colors: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
      ),
      _PartnerAd(
        icon: Icons.handyman_outlined,
        title: loc.adWarrantyTitle,
        subtitle: loc.adWarrantySubtitle,
        colors: const [Color(0xFF0D47A1), Color(0xFF1E88E5)],
      ),
    ];
  }
}

class _PartnerAd {
  const _PartnerAd({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
}

class _PartnerAdCard extends StatelessWidget {
  const _PartnerAdCard({required this.ad, required this.onTap});

  final _PartnerAd ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: ad.colors,
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            boxShadow: [
              BoxShadow(
                color: ad.colors.first.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                PositionedDirectional(
                  end: -28,
                  top: -36,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 18,
                  bottom: -40,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(ad.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                loc.partnerAdTag,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ad.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ad.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chat_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
