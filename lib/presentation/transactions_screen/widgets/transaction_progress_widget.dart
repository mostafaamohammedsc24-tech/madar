import '../../../core/app_export.dart';

class TransactionProgressWidget extends StatelessWidget {
  final List<Map<String, dynamic>> stages;
  final int currentStage;
  final Function(int) onStageTap;

  const TransactionProgressWidget({
    super.key,
    required this.stages,
    required this.currentStage,
    required this.onStageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مراحل الصفقة',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(stages.length, (i) {
            final stage = stages[i];
            final status = stage['status'] as String? ?? 'pending';
            final isCompleted = status == 'completed';
            final isActive = status == 'in_progress';
            final isPending = status == 'pending';
            final isLast = i == stages.length - 1;

            return InkWell(
              onTap: () => onStageTap(i),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppTheme.success
                              : isActive
                              ? AppTheme.primary
                              : Colors.grey.withAlpha(40),
                          border: isActive
                              ? Border.all(
                                  color: AppTheme.primary.withAlpha(60),
                                  width: 3,
                                )
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : isActive
                              ? const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: isPending
                                        ? Colors.grey
                                        : Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                      if (!isLast)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 2,
                          height: 32,
                          color: isCompleted
                              ? AppTheme.success
                              : Colors.grey.withAlpha(40),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage['title'] as String? ?? 'مرحلة ${i + 1}',
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isPending
                                  ? Colors.grey
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                              fontSize: 14,
                            ),
                          ),
                          if (isActive)
                            Text(
                              'جارية الآن',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (isCompleted)
                            Text(
                              'مكتملة',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
