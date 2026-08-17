import '../../../core/app_export.dart';
import '../../../core/layout/directional_layout.dart';

class TransactionHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionHeaderWidget({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final refNum = transaction['reference_number'] as String? ?? 'MADAR-XXX';
    final address =
        transaction['property_address_snapshot'] as String? ?? 'العنوان';
    final txType = transaction['transaction_type'] as String? ?? 'sale';
    final amount = transaction['total_amount'] as double? ?? 0;
    final currency = transaction['currency_code'] as String? ?? 'IQD';
    final currentStage = transaction['current_stage_index'] as int? ?? 0;
    final status = transaction['status'] as String? ?? 'in_progress';

    final progress = (currentStage + 1) / 6;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      refNum,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getTypeLabel(txType),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatAmount(amount, currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المرحلة ${currentStage + 1} من 6',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withAlpha(40),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPartyChip(
                icon: Icons.person,
                label: transaction['seller_name'] as String? ?? 'البائع',
                role: 'البائع',
              ),
              const SizedBox(width: 8),
              DirectionalForwardIcon(
                color: Colors.white.withAlpha(150),
                size: 16,
              ),
              const SizedBox(width: 8),
              _buildPartyChip(
                icon: Icons.person_outline,
                label: transaction['buyer_name'] as String? ?? 'المشتري',
                role: 'المشتري',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartyChip({
    required IconData icon,
    required String label,
    required String role,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: TextStyle(
                      color: Colors.white.withAlpha(160),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'sale':
        return 'بيع';
      case 'rent':
        return 'إيجار';
      case 'mortgage':
        return 'رهن';
      default:
        return type;
    }
  }

  String _formatAmount(double amount, String currency) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} مليار $currency';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} مليون $currency';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} ألف $currency';
    }
    return '${amount.toStringAsFixed(0)} $currency';
  }
}
