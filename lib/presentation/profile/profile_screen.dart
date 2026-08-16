import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/layout/directional_layout.dart';
import '../../providers/country_context_provider.dart';
import '../../widgets/currency_selector_sheet.dart';
import '../../widgets/language_selector_sheet.dart';
import '../../widgets/madar_country_selector_sheet.dart';
import '../../features/authentication/presentation/providers/user_auth_notifier.dart';
import '../../services/supabase_service.dart';
import '../notifications/notification_center_screen.dart';
import './documents_archive_screen.dart';
import './edit_profile_screen.dart';
import './seller_commission_dashboard.dart';

// Profile Screen — settings, archive, language, dark mode

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _favoriteProperties = [];
  List<Map<String, dynamic>> _savedSearches = [];
  List<Map<String, dynamic>> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await SupabaseService.instance.getUserProfile();
      final notifications = await SupabaseService.instance.getNotifications();
      final favorites = await SupabaseService.instance.getFavoriteProperties();
      final savedSearches = await SupabaseService.instance.getSavedSearches();
      final transactions = await SupabaseService.instance.getUserTransactions();
      if (mounted) {
        setState(() {
          _profile = profile;
          _notifications = notifications;
          _favoriteProperties = favorites;
          _savedSearches = savedSearches;
          _allTransactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.logout),
        content: Text(loc.authLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(
              loc.logout,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<UserAuthNotifier>().signOut();
      if (!mounted) return;
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final countryProvider = context.watch<CountryContextProvider>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
        ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            loc.navProfile,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileCard(theme, loc),
                    const SizedBox(height: 16),
                    _buildVerificationCard(theme, loc),
                    const SizedBox(height: 16),
                    _buildSettingsSection(
                      theme,
                      localeProvider,
                      countryProvider,
                      loc,
                    ),
                    const SizedBox(height: 16),
                    _buildArchiveSection(theme, loc),
                    const SizedBox(height: 16),
                    _buildFavoritesSection(theme, loc),
                    const SizedBox(height: 16),
                    _buildSavedSearchesSection(theme, loc),
                    const SizedBox(height: 16),
                    _buildDangerZone(theme, loc),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, AppLocalizations loc) {
    final displayName =
        _profile?['display_name'] as String? ??
        '${_profile?['first_name'] ?? ''} ${_profile?['last_name'] ?? ''}'
            .trim();
    final phone =
        _profile?['phone_e164'] as String? ??
        (loc.notSet);
    final photoUrl = _profile?['profile_photo_url'] as String?;
    final accountStatus = _profile?['account_status'] as String? ?? 'pending';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
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
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(30),
              border: Border.all(color: Colors.white.withAlpha(80), width: 2),
            ),
            child: photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isEmpty
                      ? loc.madarUser
                      : displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(accountStatus, loc),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _editProfile,
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart, color: Colors.white),
                tooltip: loc.commissionDashboard,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SellerCommissionDashboard(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(ThemeData theme, AppLocalizations loc) {
    final idStatus =
        _profile?['identity_verification_status'] as String? ?? 'unverified';
    final phoneStatus =
        _profile?['phone_verification_status'] as String? ?? 'unverified';

    return Container(
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
            loc.verificationSecurity,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildVerificationRow(
            icon: Icons.phone,
            label: loc.phoneNumberLabel,
            status: phoneStatus,
            theme: theme,
            loc: loc,
          ),
          const Divider(height: 24),
          _buildVerificationRow(
            icon: Icons.face,
            label: loc.biometricVerification,
            status: 'verified',
            theme: theme,
            loc: loc,
          ),
          const Divider(height: 24),
          _buildVerificationRow(
            icon: Icons.badge,
            label: loc.nationalId,
            status: idStatus,
            theme: theme,
            loc: loc,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationRow({
    required IconData icon,
    required String label,
    required String status,
    required ThemeData theme,
    required AppLocalizations loc,
  }) {
    final isVerified = status == 'verified';
    final color = isVerified ? AppTheme.success : Colors.orange;
    final statusLabel = isVerified ? loc.verified : loc.unverified;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    ThemeData theme,
    LocaleProvider localeProvider,
    CountryContextProvider countryProvider,
    AppLocalizations loc,
  ) {
    return Container(
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
        children: [
          _buildSettingsTile(
            icon: Icons.dark_mode,
            label: loc.darkMode,
            trailing: Switch(
              value: localeProvider.isDarkMode,
              onChanged: (v) => localeProvider.toggleDarkMode(),
              activeColor: AppTheme.primary,
            ),
            theme: theme,
          ),
          const Divider(height: 1, indent: 56),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            icon: Icons.public,
            label: loc.settingsCountry,
            trailing: Text(
              countryProvider.activeCountry.localizedName(loc.languageCode),
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              final selected = await MadarCountrySelectorSheet.show(
                context,
                selectedCountry: countryProvider.activeCountry,
              );
              if (selected != null && mounted) {
                await countryProvider.setCountry(selected);
                await SupabaseService.instance.updateUserProfile({
                  'country_code': selected.isoCode,
                  'preferred_currency': countryProvider.activeCurrency,
                });
              }
            },
            theme: theme,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            icon: Icons.payments_outlined,
            label: loc.settingsCurrency,
            trailing: Text(
              '${countryProvider.activeCurrencySymbol} ${countryProvider.activeCurrency}',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              final code = await CurrencySelectorSheet.show(
                context,
                selectedCode: countryProvider.activeCurrency,
              );
              if (code != null && mounted) {
                await countryProvider.setCurrency(code);
                await SupabaseService.instance.updateUserProfile({
                  'preferred_currency': code,
                });
              }
            },
            theme: theme,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            icon: Icons.language,
            label: loc.languageLabel,
            trailing: Text(
              localeProvider.language == AppLanguage.arabic
                  ? loc.langArabic
                  : localeProvider.language == AppLanguage.kurdish
                  ? loc.langKurdish
                  : loc.langEnglish,
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => LanguageSelectorSheet.show(context),
            theme: theme,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            icon: Icons.phone_android,
            label: loc.changePhone,
            onTap: _requestPhoneChange,
            theme: theme,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            icon: Icons.notifications,
            label: loc.notifications,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen(),
              ),
            ),
            theme: theme,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            icon: Icons.bar_chart,
            label: loc.sellerCommissionDashboard,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SellerCommissionDashboard(),
              ),
            ),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          trailing ?? const DirectionalListArrow(),
      onTap: onTap,
    );
  }

  Widget _buildArchiveSection(ThemeData theme, AppLocalizations loc) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_special, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    loc.documentsArchive,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentsArchiveScreen(),
                    ),
                  );
                },
                icon: DirectionalForwardIcon(size: 14),
                label: Text(loc.viewAll, style: const TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildArchiveItem(
                icon: Icons.receipt_long,
                label: loc.transactions,
                count: '${_allTransactions.length}',
                theme: theme,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentsArchiveScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildArchiveItem(
                icon: Icons.gavel,
                label: loc.contracts,
                count:
                    '${_allTransactions.where((t) => (t['current_stage_index'] as int? ?? 0) >= 2).length}',
                theme: theme,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentsArchiveScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildArchiveItem(
                icon: Icons.home_work,
                label: loc.titleDeeds,
                count:
                    '${_allTransactions.where((t) => (t['current_stage_index'] as int? ?? 0) >= 5).length}',
                theme: theme,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentsArchiveScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentsArchiveScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withAlpha(15),
                    AppTheme.primary.withAlpha(5),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withAlpha(30)),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_open, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.allDocumentsContractsDeeds,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          loc.tapToViewTransactionDocs,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DirectionalListArrow(
                    color: AppTheme.primary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveItem({
    required IconData icon,
    required String label,
    required String count,
    required ThemeData theme,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withAlpha(30)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone(ThemeData theme, AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.error.withAlpha(40)),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.error.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.logout, color: AppTheme.error, size: 18),
        ),
        title: Text(
          loc.logout,
          style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600),
        ),
        onTap: _signOut,
      ),
    );
  }

  Widget _buildFavoritesSection(ThemeData theme, AppLocalizations loc) {
    return Container(
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
          Row(
            children: [
              Icon(Icons.favorite, color: AppTheme.error, size: 18),
              const SizedBox(width: 8),
              Text(
                loc.favorites,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_favoriteProperties.length}',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_favoriteProperties.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 40,
                      color: Colors.grey.withAlpha(100),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.noFavoritePropertiesYet,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _favoriteProperties.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final fav = _favoriteProperties[i];
                  final prop = fav['properties_v3'] as Map<String, dynamic>?;
                  if (prop == null) return const SizedBox.shrink();
                  final media = prop['property_media_v3'] as List?;
                  final imageUrl = media?.isNotEmpty == true
                      ? (media!.first['media_url'] as String? ?? '')
                      : '';
                  final title =
                      prop['title'] as String? ??
                      (loc.property);
                  final price = prop['asking_price_usd'] as num? ?? 0;
                  return GestureDetector(
                    onTap: () => context.push('/property-detail', extra: prop),
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: theme.colorScheme.surfaceContainerHighest
                            .withAlpha(60),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(13),
                            ),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    height: 70,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 70,
                                      color: AppTheme.primary.withAlpha(20),
                                      child: Icon(
                                        Icons.home,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 70,
                                    color: AppTheme.primary.withAlpha(20),
                                    child: Center(
                                      child: Icon(
                                        Icons.home,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '\$${price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSavedSearchesSection(ThemeData theme, AppLocalizations loc) {
    if (_savedSearches.isEmpty) return const SizedBox.shrink();
    return Container(
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
          Row(
            children: [
              Icon(Icons.bookmarks, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                loc.savedSearchesTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_savedSearches.length}',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_savedSearches.take(5).map((s) {
            final query = s['query'] as String? ?? '';
            final filters = s['filters'] as Map<String, dynamic>?;
            final city = filters?['city'] as String? ?? '';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.search, color: AppTheme.primary, size: 18),
              ),
              title: Text(
                query.isNotEmpty
                    ? query
                    : (filters?['filter'] as String? ??
                          (loc.search)),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: city.isNotEmpty && city != 'All'
                  ? Text(city, style: const TextStyle(fontSize: 11))
                  : null,
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppTheme.error.withAlpha(180),
                  size: 18,
                ),
                onPressed: () async {
                  await SupabaseService.instance.deleteSavedSearch(
                    s['id'] as String? ?? '',
                  );
                  _loadProfile();
                },
              ),
              onTap: () => context.go('/'),
            );
          })),
        ],
      ),
    );
  }

  void _showNotifications() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
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
                loc.notifications,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              loc.noNotificationsYet,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: _notifications.length,
                        itemBuilder: (_, i) {
                          final n = _notifications[i];
                          return ListTile(
                            leading: Icon(
                              Icons.notifications,
                              color: AppTheme.primary,
                            ),
                            title: Text(
                              n['title'] as String? ?? loc.notifications,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              n['body'] as String? ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile)),
    ).then((_) => _loadProfile());
  }

  void _requestPhoneChange() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.changePhone),
        content: Text(
          loc.phoneChangeSupportNote,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status, AppLocalizations loc) {
    switch (status) {
      case 'active':
        return loc.activeAccount;
      case 'pending':
        return loc.underReview;
      case 'suspended':
        return loc.accountSuspended;
      default:
        return status;
    }
  }
}
