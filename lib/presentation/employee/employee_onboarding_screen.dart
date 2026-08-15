
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../providers/country_context_provider.dart';
import '../../services/mixpanel_service.dart';

/// Employee Onboarding Profile Screen
/// Multi-step flow: Welcome → Personal Info → Role & Department
/// → Documents Upload → Emergency Contact → Review & Submit
class EmployeeOnboardingScreen extends StatefulWidget {
  final Map<String, dynamic>? employeeData;

  const EmployeeOnboardingScreen({super.key, this.employeeData});

  @override
  State<EmployeeOnboardingScreen> createState() =>
      _EmployeeOnboardingScreenState();
}

class _EmployeeOnboardingScreenState extends State<EmployeeOnboardingScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 5;

  late AnimationController _pageCtrl;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;

  // Step 1 — Personal Info
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String _selectedGender = 'Male';

  // Step 2 — Role & Department
  String _selectedRole = 'Transaction Coordinator';
  String _selectedDepartment = 'Operations';
  String _selectedCountry = 'Iraq';
  final _employeeCodeCtrl = TextEditingController();

  // Step 3 — Documents
  bool _nationalIdUploaded = false;
  bool _cvUploaded = false;
  bool _contractUploaded = false;
  bool _photoUploaded = false;

  // Step 4 — Emergency Contact
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _emergencyRelationCtrl = TextEditingController();

  // Step 5 — Review
  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _roles = [
    'Transaction Coordinator',
    'Lawyer / Legal Counsel',
    'Bank Escrow Officer',
    'Finance Officer',
    'Call Center Agent',
    'Publishing Manager',
    'Photographer',
    'Property Info Specialist',
    'Property Manager',
    'Customer Support',
    'Risk Analyst',
    'Marketing Specialist',
    'Visit Manager',
    'Network Expansion',
    'Executive',
  ];

  final List<String> _departments = [
    'Operations',
    'Legal',
    'Finance',
    'Marketing',
    'Technology',
    'Customer Experience',
    'Risk & Compliance',
    'Network',
    'Executive',
  ];

  final List<String> _countries = kSupportedCountries
      .map((c) => c.nameEn)
      .toList();

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic));
    _pageCtrl.forward();

    // Pre-fill from employee data if available
    if (widget.employeeData != null) {
      _fullNameCtrl.text = widget.employeeData!['full_name'] ?? '';
      _employeeCodeCtrl.text = widget.employeeData!['employee_code'] ?? '';
    }

    // Track onboarding started
    final empId = widget.employeeData?['id']?.toString() ?? 'unknown';
    MixpanelService.instance.trackOnboardingStarted(
      employeeId: empId,
      role: _selectedRole,
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _employeeCodeCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _emergencyRelationCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageCtrl.reset();
      setState(() => _currentStep++);
      _pageCtrl.forward();

      // Track step completion
      final empId = widget.employeeData?['id']?.toString() ?? 'unknown';
      MixpanelService.instance.trackOnboardingStepCompleted(
        employeeId: empId,
        step: _currentStep,
        stepName: _stepTitles[_currentStep - 1],
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageCtrl.reset();
      setState(() => _currentStep--);
      _pageCtrl.forward();
    }
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });

    final empId = widget.employeeData?['id']?.toString() ?? 'unknown';
    MixpanelService.instance.trackOnboardingCompleted(
      employeeId: empId,
      role: _selectedRole,
      country: _selectedCountry,
    );
  }

  final List<String> _stepTitles = [
    'Welcome',
    'Personal Info',
    'Role & Department',
    'Documents',
    'Emergency Contact',
  ];

  final List<IconData> _stepIcons = [
    Icons.waving_hand_rounded,
    Icons.person_rounded,
    Icons.work_rounded,
    Icons.folder_rounded,
    Icons.emergency_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_submitted) return _buildSuccessScreen(theme, isDark);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1421)
          : const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, isDark),
            _buildProgressBar(theme),
            Expanded(
              child: FadeTransition(
                opacity: _pageFade,
                child: SlideTransition(
                  position: _pageSlide,
                  child: _buildCurrentStep(theme, isDark),
                ),
              ),
            ),
            _buildBottomActions(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employee Onboarding',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps — ${_stepTitles[_currentStep]}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Step icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primary.withAlpha(180)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _stepIcons[_currentStep],
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progress = (_currentStep + 1) / _totalSteps;
    return Container(
      height: 4,
      color: theme.colorScheme.surfaceContainerHighest,
      child: FractionallySizedBox(
        widthFactor: progress,
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primary.withAlpha(200)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(theme, isDark);
      case 1:
        return _buildPersonalInfoStep(theme, isDark);
      case 2:
        return _buildRoleDeptStep(theme, isDark);
      case 3:
        return _buildDocumentsStep(theme, isDark);
      case 4:
        return _buildReviewStep(theme, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Welcome ──────────────────────────────────────────────────────────

  Widget _buildWelcomeStep(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primary.withAlpha(160)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(60),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Welcome to Madar! 🎉',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            widget.employeeData?['full_name'] != null
                ? 'Hello, ${widget.employeeData!['full_name']}!\nLet\'s complete your employee profile.'
                : 'Let\'s complete your employee profile to get you started.',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          // Steps overview
          ..._buildStepOverview(theme, isDark),
        ],
      ),
    );
  }

  List<Widget> _buildStepOverview(ThemeData theme, bool isDark) {
    final steps = [
      (
        'Personal Information',
        'Name, email, date of birth',
        Icons.person_rounded,
      ),
      ('Role & Department', 'Your position and team', Icons.work_rounded),
      ('Documents Upload', 'ID, CV, and contract', Icons.folder_rounded),
      ('Emergency Contact', 'Safety contact details', Icons.emergency_rounded),
    ];

    return steps.asMap().entries.map((entry) {
      final i = entry.key;
      final step = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2540) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(30)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(step.$3, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.$1,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    step.$2,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ── Step 1: Personal Info ────────────────────────────────────────────────────

  Widget _buildPersonalInfoStep(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Personal Information', theme),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _fullNameCtrl,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline_rounded,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _emailCtrl,
            label: 'Email Address',
            hint: 'your@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _dobCtrl,
            label: 'Date of Birth',
            hint: 'DD/MM/YYYY',
            icon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.datetime,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Text(
            'Gender',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['Male', 'Female', 'Prefer not to say'].map((g) {
              final isSelected = _selectedGender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withAlpha(20)
                          : isDark
                          ? const Color(0xFF1A2540)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : theme.colorScheme.outline.withAlpha(40),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      g,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Role & Department ────────────────────────────────────────────────

  Widget _buildRoleDeptStep(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Role & Department', theme),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _employeeCodeCtrl,
            label: 'Employee Code',
            hint: 'e.g. MDR-IQ-001',
            icon: Icons.badge_outlined,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildDropdown(
            label: 'Role',
            value: _selectedRole,
            items: _roles,
            icon: Icons.work_outline_rounded,
            onChanged: (v) => setState(() => _selectedRole = v!),
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildDropdown(
            label: 'Department',
            value: _selectedDepartment,
            items: _departments,
            icon: Icons.business_outlined,
            onChanged: (v) => setState(() => _selectedDepartment = v!),
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildDropdown(
            label: 'Country',
            value: _selectedCountry,
            items: _countries,
            icon: Icons.public_outlined,
            onChanged: (v) => setState(() => _selectedCountry = v!),
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          // Role info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withAlpha(40)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your role determines your dashboard access and permissions within the Madar platform.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.primary,
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

  // ── Step 3: Documents ────────────────────────────────────────────────────────

  Widget _buildDocumentsStep(ThemeData theme, bool isDark) {
    final docs = [
      (
        'National ID / Passport',
        _nationalIdUploaded,
        Icons.credit_card_rounded,
        () => setState(() => _nationalIdUploaded = true),
      ),
      (
        'CV / Resume',
        _cvUploaded,
        Icons.description_rounded,
        () => setState(() => _cvUploaded = true),
      ),
      (
        'Employment Contract',
        _contractUploaded,
        Icons.article_rounded,
        () => setState(() => _contractUploaded = true),
      ),
      (
        'Profile Photo',
        _photoUploaded,
        Icons.photo_camera_rounded,
        () => setState(() => _photoUploaded = true),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Documents Upload', theme),
          const SizedBox(height: 8),
          Text(
            'Upload required documents for verification',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ...docs.map(
            (doc) => _buildDocumentTile(
              title: doc.$1,
              uploaded: doc.$2,
              icon: doc.$3,
              onTap: doc.$4,
              theme: theme,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile({
    required String title,
    required bool uploaded,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: uploaded
              ? const Color(0xFF00C853).withAlpha(12)
              : isDark
              ? const Color(0xFF1A2540)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded
                ? const Color(0xFF00C853).withAlpha(100)
                : theme.colorScheme.outline.withAlpha(40),
            width: uploaded ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: uploaded
                    ? const Color(0xFF00C853).withAlpha(20)
                    : AppTheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: uploaded ? const Color(0xFF00C853) : AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    uploaded ? 'Uploaded ✓' : 'Tap to upload',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: uploaded
                          ? const Color(0xFF00C853)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              uploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              color: uploaded
                  ? const Color(0xFF00C853)
                  : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 4: Review & Submit ──────────────────────────────────────────────────

  Widget _buildReviewStep(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Review & Submit', theme),
          const SizedBox(height: 8),
          Text(
            'Please review your information before submitting',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _buildReviewCard(
            title: 'Personal Information',
            icon: Icons.person_rounded,
            items: [
              (
                'Full Name',
                _fullNameCtrl.text.isEmpty ? '—' : _fullNameCtrl.text,
              ),
              ('Email', _emailCtrl.text.isEmpty ? '—' : _emailCtrl.text),
              ('Date of Birth', _dobCtrl.text.isEmpty ? '—' : _dobCtrl.text),
              ('Gender', _selectedGender),
            ],
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildReviewCard(
            title: 'Role & Department',
            icon: Icons.work_rounded,
            items: [
              (
                'Employee Code',
                _employeeCodeCtrl.text.isEmpty ? '—' : _employeeCodeCtrl.text,
              ),
              ('Role', _selectedRole),
              ('Department', _selectedDepartment),
              ('Country', _selectedCountry),
            ],
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildReviewCard(
            title: 'Documents',
            icon: Icons.folder_rounded,
            items: [
              ('National ID', _nationalIdUploaded ? '✓ Uploaded' : '✗ Missing'),
              ('CV / Resume', _cvUploaded ? '✓ Uploaded' : '✗ Missing'),
              ('Contract', _contractUploaded ? '✓ Uploaded' : '✗ Missing'),
              ('Profile Photo', _photoUploaded ? '✓ Uploaded' : '✗ Missing'),
            ],
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          // Terms agreement
          GestureDetector(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _agreedToTerms
                        ? AppTheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _agreedToTerms
                          ? AppTheme.primary
                          : theme.colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: _agreedToTerms
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'I confirm that all information provided is accurate and I agree to Madar\'s employee terms and conditions.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildReviewCard({
    required String title,
    required IconData icon,
    required List<(String, String)> items,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2540) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      item.$1,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Actions ───────────────────────────────────────────────────────────

  Widget _buildBottomActions(ThemeData theme, bool isDark) {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isLastStep
              ? (_agreedToTerms && !_isSubmitting ? _submitOnboarding : null)
              : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.primary.withAlpha(80),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  isLastStep ? 'Submit Profile' : 'Continue',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Success Screen ───────────────────────────────────────────────────────────

  Widget _buildSuccessScreen(ThemeData theme, bool isDark) {
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1421)
          : const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withAlpha(60),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Profile Submitted!',
                  style: GoogleFonts.dmSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your employee profile has been submitted for review. HR will verify your documents and activate your account within 1-2 business days.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Go to Dashboard',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
            ),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A2540) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withAlpha(40),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withAlpha(40),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2540) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
              dropdownColor: isDark ? const Color(0xFF1A2540) : Colors.white,
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Row(
                        children: [
                          Icon(icon, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.dmSans(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
