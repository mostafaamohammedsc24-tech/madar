import '../../../core/app_export.dart';
import '../../../widgets/status_badge_widget.dart';

class SubmissionData {
  final String status;
  final String imageUrl;
  final String semanticLabel;
  final String title;
  final String address;
  final String submittedDate;
  final String note;

  const SubmissionData({
    required this.status,
    required this.imageUrl,
    required this.semanticLabel,
    required this.title,
    required this.address,
    required this.submittedDate,
    this.note = '',
  });
}

class SubmissionItemWidget extends StatelessWidget {
  final SubmissionData submission;

  const SubmissionItemWidget({required this.submission, super.key});

  PropertyStatus _parseStatus(String s) {
    switch (s) {
      case 'underReview':
        return PropertyStatus.underReview;
      case 'pending':
        return PropertyStatus.pending;
      case 'rejected':
        return PropertyStatus.rejected;
      default:
        return PropertyStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = submission;
    final status = _parseStatus(s.status);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppTheme.warningLight, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: CustomImageWidget(
                  imageUrl: s.imageUrl,
                  width: 80,
                  height: 90,
                  fit: BoxFit.cover,
                  semanticLabel: s.semanticLabel,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.title,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusBadgeWidget(status: status, compact: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'location_on',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              s.address,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'calendar_today',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Submitted ${s.submittedDate}',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Note
          if (s.note.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: AppTheme.warningLight.withAlpha(128),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.warning,
                    size: 13,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.note,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.warning,
                        height: 1.4,
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