import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../services/transaction_notification_service.dart';
import './widgets/barcode_upload_widget.dart';
import './widgets/transaction_header_widget.dart';
import './widgets/transaction_progress_widget.dart';
import './widgets/transaction_stage_detail_widget.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isLoadingTransactions = true;
  Map<String, dynamic>? _activeTransaction;
  List<Map<String, dynamic>> _allTransactions = [];
  int? _selectedStageIndex;
  RealtimeChannel? _realtimeChannel;
  int _unreadNotifCount = 0;

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();
    _loadTransactions();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoadingTransactions = true);
    try {
      final txs = await SupabaseService.instance.getUserTransactions();
      if (mounted) {
        setState(() {
          _allTransactions = txs;
          _isLoadingTransactions = false;
          if (txs.isNotEmpty) {
            _activeTransaction = txs.first;
            _subscribeToTransaction(txs.first['id'] as String);
          }
        });
        // Subscribe to real-time notifications for all transactions
        if (txs.isNotEmpty) {
          final ids = txs
              .map((t) => t['id'] as String?)
              .whereType<String>()
              .toList();
          TransactionNotificationService.instance.subscribeToUserTransactions(
            ids,
            context,
          );
        }
        _entranceController.reset();
        _entranceController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTransactions = false);
    }
  }

  void _subscribeToTransaction(String txId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = SupabaseService.instance.subscribeToTransaction(txId, (
      updated,
    ) {
      if (mounted) setState(() => _activeTransaction = updated);
    });
  }

  Future<void> _onBarcodeScanned(String barcodeCode) async {
    setState(() => _isLoading = true);
    try {
      final result = await SupabaseService.instance.getTransactionByBarcode(
        barcodeCode,
      );
      if (result != null && mounted) {
        final tx = result['transactions'] as Map<String, dynamic>?;
        if (tx != null) {
          // Redeem barcode
          await SupabaseService.instance.redeemBarcode(result['id'] as String);
          setState(() {
            _isLoading = false;
            _activeTransaction = tx;
            _allTransactions = [tx, ..._allTransactions];
          });
          _subscribeToTransaction(tx['id'] as String);
          _entranceController.reset();
          _entranceController.forward();
        } else {
          setState(() => _isLoading = false);
          _showError('لم يتم العثور على الصفقة');
        }
      } else {
        setState(() => _isLoading = false);
        _showError('رمز الباركود غير صالح');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('حدث خطأ، يرجى المحاولة مرة أخرى');
    }
  }

  void _onBarcodeUploaded() {
    // Demo mode - load mock transaction
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activeTransaction = _mockTransaction;
          _allTransactions = [_mockTransaction];
          _unreadNotifCount = 1;
        });
        _entranceController.reset();
        _entranceController.forward();
        // Show real-time notification demo
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            TransactionNotificationService.instance.showDemoNotification(
              context,
              3,
            );
          }
        });
      }
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static final Map<String, dynamic> _mockTransaction = {
    'id': 'demo_txn_001',
    'reference_number': 'MADAR-IQ-2026-001',
    'property_address_snapshot': 'شارع النضال، الكرادة، بغداد',
    'transaction_type': 'sale',
    'total_amount': 185000000.0,
    'currency_code': 'IQD',
    'current_stage_index': 3,
    'status': 'in_progress',
    'created_at': '2026-08-01T10:00:00Z',
    'buyer_name': 'أحمد الراشدي',
    'seller_name': 'مريم خليل',
    'transaction_stages': [
      {
        'stage_index': 0,
        'title': 'التحقق من الهوية',
        'status': 'completed',
        'completed_at': '2026-08-02T10:00:00Z',
        'icon': 'verified_user',
      },
      {
        'stage_index': 1,
        'title': 'المستمسكات والوثائق',
        'status': 'completed',
        'completed_at': '2026-08-05T10:00:00Z',
        'icon': 'description',
      },
      {
        'stage_index': 2,
        'title': 'العقد والتوقيع',
        'status': 'completed',
        'completed_at': '2026-08-08T10:00:00Z',
        'icon': 'gavel',
      },
      {
        'stage_index': 3,
        'title': 'الإيداع الضماني',
        'status': 'in_progress',
        'completed_at': null,
        'icon': 'savings',
      },
      {
        'stage_index': 4,
        'title': 'نقل الملكية',
        'status': 'pending',
        'completed_at': null,
        'icon': 'transfer_within_a_station',
      },
      {
        'stage_index': 5,
        'title': 'التسوية النهائية',
        'status': 'pending',
        'completed_at': null,
        'icon': 'receipt',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildAppBar(theme),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading || _isLoadingTransactions
            ? _buildLoadingState()
            : _activeTransaction == null
            ? _buildEmptyState()
            : isTablet
            ? _buildTabletLayout()
            : _buildPhoneLayout(),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'صفقاتي',
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        if (_allTransactions.length > 1)
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: _showTransactionsList,
            tooltip: 'كل الصفقات',
          ),
        if (_activeTransaction != null)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTransactions,
            tooltip: 'تحديث',
          ),
        // Real-time notification bell
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                if (_unreadNotifCount > 0)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_unreadNotifCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              setState(() => _unreadNotifCount = 0);
              // Demo: show a notification banner
              if (_activeTransaction != null) {
                final stage =
                    (_activeTransaction!['current_stage_index'] as int?) ?? 3;
                TransactionNotificationService.instance.showDemoNotification(
                  context,
                  stage,
                );
              }
            },
            tooltip: 'الإشعارات',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.9,
                child: BarcodeUploadWidget(
                  onUpload: _onBarcodeUploaded,
                  onBarcodeScanned: _onBarcodeScanned,
                ),
              ),
            );
          },
          tooltip: 'مسح الباركود',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'جاري التحقق...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: BarcodeUploadWidget(
          onUpload: _onBarcodeUploaded,
          onBarcodeScanned: _onBarcodeScanned,
        ),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    final tx = _activeTransaction!;
    final stages = _getStages(tx);
    final currentStage = tx['current_stage_index'] as int? ?? 0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: TransactionHeaderWidget(transaction: tx)),
            SliverToBoxAdapter(
              child: TransactionProgressWidget(
                stages: stages,
                currentStage: currentStage,
                onStageTap: (i) => setState(() => _selectedStageIndex = i),
              ),
            ),
            SliverToBoxAdapter(
              child: TransactionStageDetailWidget(
                transaction: tx,
                stages: stages,
                currentStage: currentStage,
                selectedStageIndex: _selectedStageIndex ?? currentStage,
                onActionComplete: _loadTransactions,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    final tx = _activeTransaction!;
    final stages = _getStages(tx);
    final currentStage = tx['current_stage_index'] as int? ?? 0;

    return Row(
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              TransactionHeaderWidget(transaction: tx),
              Expanded(
                child: TransactionProgressWidget(
                  stages: stages,
                  currentStage: currentStage,
                  onStageTap: (i) => setState(() => _selectedStageIndex = i),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TransactionStageDetailWidget(
            transaction: tx,
            stages: stages,
            currentStage: currentStage,
            selectedStageIndex: _selectedStageIndex ?? currentStage,
            onActionComplete: _loadTransactions,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getStages(Map<String, dynamic> tx) {
    final rawStages = tx['transaction_stages'];
    if (rawStages is List) {
      return List<Map<String, dynamic>>.from(rawStages)..sort(
        (a, b) => (a['stage_index'] as int).compareTo(b['stage_index'] as int),
      );
    }
    return _mockTransaction['transaction_stages'] as List<Map<String, dynamic>>;
  }

  void _showTransactionsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'جميع الصفقات',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ..._allTransactions.map(
              (tx) => ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  tx['reference_number'] as String? ?? 'صفقة',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  tx['property_address_snapshot'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  setState(() => _activeTransaction = tx);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
