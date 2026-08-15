import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

/// Real-time transaction notification overlay
/// Shows animated banners when transaction stages update
class TransactionNotificationService {
  static final TransactionNotificationService _instance =
      TransactionNotificationService._();
  static TransactionNotificationService get instance => _instance;
  TransactionNotificationService._();

  final List<RealtimeChannel> _channels = [];
  OverlayEntry? _currentOverlay;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void subscribeToUserTransactions(
    List<String> transactionIds,
    BuildContext context,
  ) {
    _unsubscribeAll();
    for (final txId in transactionIds) {
      final channel = Supabase.instance.client
          .channel('notif_tx_$txId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'transactions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: txId,
            ),
            callback: (payload) {
              final updated = payload.newRecord;
              final stageIndex = updated['current_stage_index'] as int?;
              if (stageIndex != null) {
                _showStageNotification(context, stageIndex, updated);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'transaction_stages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'transaction_id',
              value: txId,
            ),
            callback: (payload) {
              final updated = payload.newRecord;
              final status = updated['status'] as String?;
              final stageIndex = updated['stage_index'] as int?;
              if (status == 'completed' && stageIndex != null) {
                _showStageCompletedNotification(context, stageIndex, updated);
              }
            },
          )
          .subscribe();
      _channels.add(channel);
    }
  }

  void _unsubscribeAll() {
    for (final ch in _channels) {
      ch.unsubscribe();
    }
    _channels.clear();
  }

  void dispose() {
    _unsubscribeAll();
    _dismissOverlay();
  }

  void _showStageNotification(
    BuildContext context,
    int stageIndex,
    Map<String, dynamic> tx,
  ) {
    final stageInfo = _getStageInfo(stageIndex);
    _showOverlayNotification(
      context,
      icon: stageInfo.icon,
      title: 'تحديث الصفقة',
      message: 'انتقلت الصفقة إلى: ${stageInfo.title}',
      color: stageInfo.color,
      txRef: tx['reference_number'] as String? ?? '',
    );
  }

  void _showStageCompletedNotification(
    BuildContext context,
    int stageIndex,
    Map<String, dynamic> stage,
  ) {
    final stageInfo = _getStageInfo(stageIndex);
    _showOverlayNotification(
      context,
      icon: Icons.check_circle,
      title: 'اكتملت المرحلة ${stageIndex + 1}',
      message: '${stageInfo.title} — تم الإنجاز بنجاح ✓',
      color: Colors.green,
      txRef: '',
    );
  }

  void showDemoNotification(BuildContext context, int stageIndex) {
    final stageInfo = _getStageInfo(stageIndex);
    _showOverlayNotification(
      context,
      icon: stageInfo.icon,
      title: 'تحديث فوري — المرحلة ${stageIndex + 1}',
      message: stageInfo.title,
      color: stageInfo.color,
      txRef: 'MADAR-IQ-2026-001',
    );
  }

  void _showOverlayNotification(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    required String txRef,
  }) {
    _dismissOverlay();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _TransactionNotificationBanner(
        icon: icon,
        title: title,
        message: message,
        color: color,
        txRef: txRef,
        onDismiss: () {
          entry.remove();
          if (_currentOverlay == entry) _currentOverlay = null;
        },
      ),
    );

    _currentOverlay = entry;
    overlay.insert(entry);

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) {
        entry.remove();
        if (_currentOverlay == entry) _currentOverlay = null;
      }
    });
  }

  void _dismissOverlay() {
    if (_currentOverlay != null && _currentOverlay!.mounted) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }
  }

  _StageInfo _getStageInfo(int index) {
    switch (index) {
      case 0:
        return _StageInfo(
          'التحقق من الهوية',
          Icons.verified_user,
          const Color(0xFF7B1FA2),
        );
      case 1:
        return _StageInfo(
          'المستمسكات والوثائق',
          Icons.description,
          Colors.orange,
        );
      case 2:
        return _StageInfo(
          'العقد والتوقيع',
          Icons.gavel,
          const Color(0xFF7B1FA2),
        );
      case 3:
        return _StageInfo(
          'الإيداع الضماني',
          Icons.savings,
          const Color(0xFF1565C0),
        );
      case 4:
        return _StageInfo(
          'نقل الملكية',
          Icons.transfer_within_a_station,
          Colors.teal,
        );
      case 5:
        return _StageInfo('التسوية النهائية', Icons.receipt_long, Colors.green);
      default:
        return _StageInfo(
          'تحديث الصفقة',
          Icons.notifications,
          AppTheme.primary,
        );
    }
  }
}

class _StageInfo {
  final String title;
  final IconData icon;
  final Color color;
  const _StageInfo(this.title, this.icon, this.color);
}

// ─── Notification Banner Widget ───────────────────────────────────────────────

class _TransactionNotificationBanner extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String txRef;
  final VoidCallback onDismiss;

  const _TransactionNotificationBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.txRef,
    required this.onDismiss,
  });

  @override
  State<_TransactionNotificationBanner> createState() =>
      _TransactionNotificationBannerState();
}

class _TransactionNotificationBannerState
    extends State<_TransactionNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1E1E2E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.color.withAlpha(80),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withAlpha(30),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Colored icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.color.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.txRef.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.color.withAlpha(15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.txRef.length > 12
                                        ? '...${widget.txRef.substring(widget.txRef.length - 8)}'
                                        : widget.txRef,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: widget.color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── In-App Notification Bell Badge ──────────────────────────────────────────

class TransactionNotificationBadge extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const TransactionNotificationBadge({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  State<TransactionNotificationBadge> createState() =>
      _TransactionNotificationBadgeState();
}

class _TransactionNotificationBadgeState
    extends State<TransactionNotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(TransactionNotificationBadge old) {
    super.didUpdateWidget(old);
    if (widget.count > old.count) {
      _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (context, child) =>
            Transform.rotate(angle: _shakeAnim.value, child: child),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 24,
            ),
            if (widget.count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.count > 9 ? '9+' : '${widget.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
