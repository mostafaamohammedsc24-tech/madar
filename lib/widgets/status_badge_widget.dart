import '../core/app_export.dart';

enum PropertyStatus { active, underReview, sold, rented, pending, rejected }

enum TransactionStageStatus { completed, inProgress, pending, failed }

class StatusBadgeWidget extends StatelessWidget {
  final PropertyStatus status;
  final bool compact;

  const StatusBadgeWidget({
    required this.status,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig(PropertyStatus s) {
    switch (s) {
      case PropertyStatus.active:
        return _BadgeConfig(
          label: 'Active',
          bgColor: AppTheme.successLight,
          dotColor: AppTheme.success,
          textColor: AppTheme.success,
        );
      case PropertyStatus.underReview:
        return _BadgeConfig(
          label: 'Under Review',
          bgColor: AppTheme.warningLight,
          dotColor: AppTheme.warning,
          textColor: AppTheme.warning,
        );
      case PropertyStatus.sold:
        return _BadgeConfig(
          label: 'Sold',
          bgColor: const Color(0xFFE3F2FD),
          dotColor: AppTheme.primary,
          textColor: AppTheme.primary,
        );
      case PropertyStatus.rented:
        return _BadgeConfig(
          label: 'Rented',
          bgColor: const Color(0xFFE8F5E9),
          dotColor: AppTheme.rentColor,
          textColor: AppTheme.rentColor,
        );
      case PropertyStatus.pending:
        return _BadgeConfig(
          label: 'Pending',
          bgColor: const Color(0xFFF3E5F5),
          dotColor: const Color(0xFF7B1FA2),
          textColor: const Color(0xFF7B1FA2),
        );
      case PropertyStatus.rejected:
        return _BadgeConfig(
          label: 'Rejected',
          bgColor: AppTheme.errorLight,
          dotColor: AppTheme.error,
          textColor: AppTheme.error,
        );
    }
  }
}

class TransactionStageBadge extends StatelessWidget {
  final TransactionStageStatus status;

  const TransactionStageBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TransactionStageStatus.completed:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.success,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CustomIconWidget(
              iconName: 'check',
              color: Colors.white,
              size: 16,
            ),
          ),
        );
      case TransactionStageStatus.inProgress:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        );
      case TransactionStageStatus.pending:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFBDBDBD), width: 2),
          ),
        );
      case TransactionStageStatus.failed:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.error,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CustomIconWidget(
              iconName: 'close',
              color: Colors.white,
              size: 16,
            ),
          ),
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color bgColor;
  final Color dotColor;
  final Color textColor;

  const _BadgeConfig({
    required this.label,
    required this.bgColor,
    required this.dotColor,
    required this.textColor,
  });
}
