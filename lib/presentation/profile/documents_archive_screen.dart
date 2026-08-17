import '../../core/app_export.dart';
import '../../core/layout/directional_layout.dart';
import '../../services/supabase_service.dart';

class DocumentsArchiveScreen extends StatefulWidget {
  const DocumentsArchiveScreen({super.key});

  @override
  State<DocumentsArchiveScreen> createState() => _DocumentsArchiveScreenState();
}

class _DocumentsArchiveScreenState extends State<DocumentsArchiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  List<_ArchiveDocument> _allDocuments = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final txs = await SupabaseService.instance.getUserTransactions();
      if (mounted) {
        setState(() {
          _transactions = txs;
          _allDocuments = _buildDocumentsFromTransactions(txs);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_ArchiveDocument> _buildDocumentsFromTransactions(
    List<Map<String, dynamic>> txs,
  ) {
    final docs = <_ArchiveDocument>[];

    // Add mock documents for demo
    docs.addAll([
      _ArchiveDocument(
        id: 'doc_001',
        title: 'عقد البيع العقاري',
        subtitle: 'شارع النضال، الكرادة، بغداد',
        type: 'contract',
        date: DateTime(2026, 8, 8),
        size: '2.4 MB',
        transactionRef: 'MADAR-IQ-2026-001',
        isDownloadable: true,
      ),
      _ArchiveDocument(
        id: 'doc_002',
        title: 'سند الملكية الجديد',
        subtitle: 'شارع النضال، الكرادة، بغداد',
        type: 'title_deed',
        date: DateTime(2026, 8, 12),
        size: '1.8 MB',
        transactionRef: 'MADAR-IQ-2026-001',
        isDownloadable: false,
      ),
      _ArchiveDocument(
        id: 'doc_003',
        title: 'وصل التسوية المالية',
        subtitle: '185,000,000 د.ع - صفقة بيع',
        type: 'receipt',
        date: DateTime(2026, 8, 14),
        size: '0.5 MB',
        transactionRef: 'MADAR-IQ-2026-001',
        isDownloadable: true,
      ),
      _ArchiveDocument(
        id: 'doc_004',
        title: 'شهادة التحقق من الهوية',
        subtitle: 'أحمد الراشدي - مريم خليل',
        type: 'identity',
        date: DateTime(2026, 8, 2),
        size: '0.3 MB',
        transactionRef: 'MADAR-IQ-2026-001',
        isDownloadable: true,
      ),
      _ArchiveDocument(
        id: 'doc_005',
        title: 'تقرير التفتيش العقاري',
        subtitle: 'شارع النضال، الكرادة، بغداد',
        type: 'inspection',
        date: DateTime(2026, 8, 5),
        size: '3.1 MB',
        transactionRef: 'MADAR-IQ-2026-001',
        isDownloadable: true,
      ),
    ]);

    // Add real transaction documents
    for (final tx in txs) {
      final ref = tx['reference_number'] as String? ?? '';
      final address = tx['property_address_snapshot'] as String? ?? '';
      final stages = tx['transaction_stages'] as List? ?? [];
      final currentStage = tx['current_stage_index'] as int? ?? 0;

      if (currentStage >= 2) {
        docs.add(
          _ArchiveDocument(
            id: 'tx_contract_${tx['id']}',
            title: 'عقد البيع',
            subtitle: address,
            type: 'contract',
            date: DateTime.now().subtract(const Duration(days: 5)),
            size: '2.1 MB',
            transactionRef: ref,
            isDownloadable: true,
          ),
        );
      }
      if (currentStage >= 5) {
        docs.add(
          _ArchiveDocument(
            id: 'tx_deed_${tx['id']}',
            title: 'سند الملكية',
            subtitle: address,
            type: 'title_deed',
            date: DateTime.now().subtract(const Duration(days: 1)),
            size: '1.5 MB',
            transactionRef: ref,
            isDownloadable: true,
          ),
        );
      }
    }

    return docs;
  }

  List<_ArchiveDocument> get _filteredDocuments {
    if (_selectedFilter == 'all') return _allDocuments;
    return _allDocuments.where((d) => d.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
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
          leading: IconButton(
            icon: const DirectionalBackIcon(color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'أرشيف الوثائق',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _showSearch,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildStatsRow(theme)),
                  SliverToBoxAdapter(child: _buildFilterChips(theme)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        '${_filteredDocuments.length} وثيقة',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  _filteredDocuments.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState(theme))
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _buildDocumentCard(
                              theme,
                              _filteredDocuments[i],
                            ),
                            childCount: _filteredDocuments.length,
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    final contracts = _allDocuments.where((d) => d.type == 'contract').length;
    final deeds = _allDocuments.where((d) => d.type == 'title_deed').length;
    final receipts = _allDocuments.where((d) => d.type == 'receipt').length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard(
            theme,
            icon: Icons.folder_special,
            label: 'الكل',
            count: _allDocuments.length,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            theme,
            icon: Icons.gavel,
            label: 'عقود',
            count: contracts,
            color: const Color(0xFF7B1FA2),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            theme,
            icon: Icons.home_work,
            label: 'سندات',
            count: deeds,
            color: AppTheme.success,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            theme,
            icon: Icons.receipt_long,
            label: 'وصولات',
            count: receipts,
            color: AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    final filters = [
      {'key': 'all', 'label': 'الكل', 'icon': Icons.folder_open},
      {'key': 'contract', 'label': 'العقود', 'icon': Icons.gavel},
      {'key': 'title_deed', 'label': 'السندات', 'icon': Icons.home_work},
      {'key': 'receipt', 'label': 'الوصولات', 'icon': Icons.receipt_long},
      {'key': 'identity', 'label': 'الهوية', 'icon': Icons.badge},
      {'key': 'inspection', 'label': 'التفتيش', 'icon': Icons.search},
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSelected = _selectedFilter == f['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : theme.dividerColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f['icon'] as IconData,
                    size: 14,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(ThemeData theme, _ArchiveDocument doc) {
    final typeConfig = _getTypeConfig(doc.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: typeConfig.color.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(typeConfig.icon, color: typeConfig.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doc.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeConfig.color.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeConfig.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: typeConfig.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today, size: 10, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        '${doc.date.day}/${doc.date.month}/${doc.date.year}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.storage, size: 10, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        doc.size,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الصفقة: ${doc.transactionRef}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primary.withAlpha(180),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                if (doc.isDownloadable)
                  IconButton(
                    icon: Icon(
                      Icons.download_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                    onPressed: () => _downloadDocument(doc),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: Colors.grey,
                    size: 18,
                  ),
                  onPressed: () => _shareDocument(doc),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey.withAlpha(80)),
          const SizedBox(height: 16),
          Text(
            'لا توجد وثائق في هذا القسم',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر الوثائق هنا بعد إتمام الصفقات',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _downloadDocument(_ArchiveDocument doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text('جاري تحميل: ${doc.title}'),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareDocument(_ArchiveDocument doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('مشاركة: ${doc.title}'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ابحث في الوثائق...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (q) {
                  // Search logic
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  _TypeConfig _getTypeConfig(String type) {
    switch (type) {
      case 'contract':
        return _TypeConfig(
          icon: Icons.gavel,
          label: 'عقد',
          color: const Color(0xFF7B1FA2),
        );
      case 'title_deed':
        return _TypeConfig(
          icon: Icons.home_work,
          label: 'سند ملكية',
          color: AppTheme.success,
        );
      case 'receipt':
        return _TypeConfig(
          icon: Icons.receipt_long,
          label: 'وصل مالي',
          color: AppTheme.warning,
        );
      case 'identity':
        return _TypeConfig(
          icon: Icons.badge,
          label: 'هوية',
          color: AppTheme.primary,
        );
      case 'inspection':
        return _TypeConfig(
          icon: Icons.search,
          label: 'تفتيش',
          color: const Color(0xFF00897B),
        );
      default:
        return _TypeConfig(
          icon: Icons.description,
          label: 'وثيقة',
          color: Colors.grey,
        );
    }
  }
}

class _ArchiveDocument {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final DateTime date;
  final String size;
  final String transactionRef;
  final bool isDownloadable;

  const _ArchiveDocument({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.date,
    required this.size,
    required this.transactionRef,
    required this.isDownloadable,
  });
}

class _TypeConfig {
  final IconData icon;
  final String label;
  final Color color;

  const _TypeConfig({
    required this.icon,
    required this.label,
    required this.color,
  });
}
