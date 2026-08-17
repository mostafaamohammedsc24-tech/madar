import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../core/layout/directional_layout.dart';
import '../../core/localization/app_localizations.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  final List<_NotifItem> _notifications = [
    _NotifItem(
      id: 'n1',
      type: NotifType.priceAlert,
      title: 'Price Drop Alert',
      titleAr: 'تنبيه انخفاض السعر',
      body: 'Villa in Mansour dropped by \$15,000 — now \$405,000',
      bodyAr: 'فيلا في المنصور انخفض سعرها بـ 15,000\$ — الآن 405,000\$',
      time: DateTime.now().subtract(const Duration(minutes: 12)),
      isRead: false,
    ),
    _NotifItem(
      id: 'n2',
      type: NotifType.newProperty,
      title: 'New Match Found',
      titleAr: 'تم العثور على تطابق جديد',
      body: '3 new apartments in Karrada match your saved search',
      bodyAr: '3 شقق جديدة في الكرادة تطابق بحثك المحفوظ',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    _NotifItem(
      id: 'n3',
      type: NotifType.transaction,
      title: 'Transaction Update',
      titleAr: 'تحديث الصفقة',
      body: 'Transaction #TXN-2024-001 moved to Stage 3: Contract Review',
      bodyAr: 'الصفقة #TXN-2024-001 انتقلت للمرحلة 3: مراجعة العقد',
      time: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
    _NotifItem(
      id: 'n4',
      type: NotifType.aiRecommendation,
      title: 'AI Recommendation',
      titleAr: 'توصية الذكاء الاصطناعي',
      body: 'Based on your activity, we found 5 properties you might love',
      bodyAr: 'بناءً على نشاطك، وجدنا 5 عقارات قد تعجبك',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: false,
    ),
    _NotifItem(
      id: 'n5',
      type: NotifType.message,
      title: 'New Message',
      titleAr: 'رسالة جديدة',
      body: 'Sales Team: Your property inquiry has been received',
      bodyAr: 'فريق المبيعات: تم استلام استفسارك عن العقار',
      time: DateTime.now().subtract(const Duration(hours: 8)),
      isRead: true,
    ),
    _NotifItem(
      id: 'n6',
      type: NotifType.priceAlert,
      title: 'Saved Area Alert',
      titleAr: 'تنبيه المنطقة المحفوظة',
      body: '7 new properties listed in your saved Adhamiya area',
      bodyAr: '7 عقارات جديدة في منطقة الأعظمية المحفوظة',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    _NotifItem(
      id: 'n7',
      type: NotifType.transaction,
      title: 'Document Ready',
      titleAr: 'الوثيقة جاهزة',
      body: 'Your signed contract is ready for download',
      bodyAr: 'عقدك الموقع جاهز للتنزيل',
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    _NotifItem(
      id: 'n8',
      type: NotifType.system,
      title: 'Account Verified',
      titleAr: 'تم التحقق من الحساب',
      body: 'Your national ID verification was successful',
      bodyAr: 'تم التحقق من هويتك الوطنية بنجاح',
      time: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_NotifItem> get _filteredNotifs {
    if (_selectedFilter == 'All') return _notifications;
    final type = _filterToType(_selectedFilter);
    return _notifications.where((n) => n.type == type).toList();
  }

  NotifType? _filterToType(String filter) {
    switch (filter) {
      case 'Prices':
        return NotifType.priceAlert;
      case 'Transactions':
        return NotifType.transaction;
      case 'Messages':
        return NotifType.message;
      case 'AI':
        return NotifType.aiRecommendation;
      default:
        return null;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _markRead(String id) {
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) _notifications[idx].isRead = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final filters = ['All', 'Prices', 'Transactions', 'Messages', 'AI'];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: DirectionalBackIcon(
            color: theme.colorScheme.onSurface,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          loc.notifications,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                loc.markAllRead,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Unread badge summary
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withAlpha(20),
                    AppTheme.primaryLight.withAlpha(15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withAlpha(40)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    loc.unreadCountLabel(_unreadCount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = filters[i];
                final isSelected = _selectedFilter == f;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _localizeFilter(f, loc),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Notifications list
          Expanded(
            child: _filteredNotifs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withAlpha(
                            100,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.noNotificationsYet,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredNotifs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final notif = _filteredNotifs[i];
                      return _NotifTile(
                        notif: notif,
                        onTap: () => _markRead(notif.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _localizeFilter(String filter, AppLocalizations loc) {
    switch (filter) {
      case 'All':
        return loc.all;
      case 'Prices':
        return loc.filterPrices;
      case 'Transactions':
        return loc.filterTransactions;
      case 'Messages':
        return loc.navMessages;
      case 'AI':
        return loc.filterAi;
      default:
        return filter;
    }
  }
}

// ─── Notification Tile ────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final _NotifItem notif;
  final VoidCallback onTap;

  const _NotifTile({
    required this.notif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final timeAgo = _formatTime(notif.time, loc);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.isRead
            ? Colors.transparent
            : AppTheme.primary.withAlpha(8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notif.type.color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notif.type.icon, color: notif.type.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          loc.language == AppLanguage.english
                              ? notif.title
                              : notif.titleAr,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    loc.language == AppLanguage.english
                        ? notif.body
                        : notif.bodyAr,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!notif.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time, AppLocalizations loc) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return loc.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return loc.hoursAgo(diff.inHours);
    } else {
      return loc.daysAgo(diff.inDays);
    }
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────
enum NotifType {
  priceAlert,
  newProperty,
  transaction,
  message,
  aiRecommendation,
  system,
}

extension NotifTypeExt on NotifType {
  Color get color {
    switch (this) {
      case NotifType.priceAlert:
        return const Color(0xFFE53935);
      case NotifType.newProperty:
        return const Color(0xFF388E3C);
      case NotifType.transaction:
        return const Color(0xFF1565C0);
      case NotifType.message:
        return const Color(0xFF7B1FA2);
      case NotifType.aiRecommendation:
        return const Color(0xFFF57C00);
      case NotifType.system:
        return const Color(0xFF00838F);
    }
  }

  IconData get icon {
    switch (this) {
      case NotifType.priceAlert:
        return Icons.trending_down_rounded;
      case NotifType.newProperty:
        return Icons.home_work_rounded;
      case NotifType.transaction:
        return Icons.handshake_rounded;
      case NotifType.message:
        return Icons.chat_bubble_rounded;
      case NotifType.aiRecommendation:
        return Icons.auto_awesome_rounded;
      case NotifType.system:
        return Icons.verified_rounded;
    }
  }
}

class _NotifItem {
  final String id;
  final NotifType type;
  final String title;
  final String titleAr;
  final String body;
  final String bodyAr;
  final DateTime time;
  bool isRead;

  _NotifItem({
    required this.id,
    required this.type,
    required this.title,
    required this.titleAr,
    required this.body,
    required this.bodyAr,
    required this.time,
    required this.isRead,
  });
}
