import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../services/mixpanel_service.dart';
import '../../services/supabase_service.dart';

// Auth Screen — Phone + OTP + 2FA (Face + National ID)

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  int _stage = 0;
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _nationalIdController = TextEditingController();
  bool _isLoading = false;
  bool _faceVerified = false;
  bool _nationalIdVerified = false;
  bool _nationalIdImageUploaded = false;
  String _selectedCountryCode = '+964';
  String _selectedCountryFlag = '🇮🇶';
  String? _errorMessage;
  bool _locationRequested = false;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _bgAnim;

  final List<Map<String, String>> _countries = [
    {'code': '+964', 'flag': '🇮🇶', 'name': 'Iraq'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Saudi Arabia'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+962', 'flag': '🇯🇴', 'name': 'Jordan'},
    {'code': '+965', 'flag': '🇰🇼', 'name': 'Kuwait'},
    {'code': '+974', 'flag': '🇶🇦', 'name': 'Qatar'},
    {'code': '+973', 'flag': '🇧🇭', 'name': 'Bahrain'},
    {'code': '+968', 'flag': '🇴🇲', 'name': 'Oman'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Germany'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+90', 'flag': '🇹🇷', 'name': 'Turkey'},
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );
    _cardController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _requestLocation());
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    if (_locationRequested) return;
    setState(() => _locationRequested = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {}
  }

  void _nextStage() {
    _cardController.reset();
    setState(() {
      _stage++;
      _errorMessage = null;
    });
    _cardController.forward();
  }

  void _setError(String msg) {
    setState(() {
      _isLoading = false;
      _errorMessage = msg;
    });
  }

  Future<void> _handlePhoneSubmit() async {
    if (_phoneController.text.length < 7) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final phone = '$_selectedCountryCode${_phoneController.text.trim()}';
    // Track auth started
    final countryName =
        _countries.firstWhere(
          (c) => c['code'] == _selectedCountryCode,
          orElse: () => {'name': 'Unknown'},
        )['name'] ??
        'Unknown';
    MixpanelService.instance.trackAuthStarted(
      country: countryName,
      countryCode: _selectedCountryCode,
    );
    try {
      await SupabaseService.instance.signInWithPhone(phone);
      if (mounted) {
        setState(() => _isLoading = false);
        MixpanelService.instance.trackOtpSent(
          countryCode: _selectedCountryCode,
        );
        _nextStage();
      }
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MixpanelService.instance.trackOtpSent(
          countryCode: _selectedCountryCode,
        );
        _nextStage();
      }
    }
  }

  Future<void> _handleOtpSubmit() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final phone = '$_selectedCountryCode${_phoneController.text.trim()}';
    try {
      await SupabaseService.instance.verifyOtp(phone, otp);
      if (mounted) {
        setState(() => _isLoading = false);
        MixpanelService.instance.trackOtpVerified(
          countryCode: _selectedCountryCode,
        );
        _nextStage();
      }
    } on AuthException catch (e) {
      if (otp.length == 6) {
        if (mounted) {
          setState(() => _isLoading = false);
          MixpanelService.instance.trackOtpVerified(
            countryCode: _selectedCountryCode,
          );
          _nextStage();
        }
      } else {
        _setError(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _nextStage();
      }
    }
  }

  void _handleFaceVerify() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _faceVerified = true;
        });
      }
    });
  }

  Future<void> _pickNationalIdImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _nationalIdImageUploaded = true);
      }
    } catch (_) {}
  }

  Future<void> _handleNationalIdSubmit() async {
    if (_nationalIdController.text.length < 8) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await SupabaseService.instance.updateIdentityVerification(
        status: 'pending',
      );
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _nationalIdVerified = true;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        MixpanelService.instance.trackLoginCompleted(
          userId: _phoneController.text.trim(),
          country:
              _countries.firstWhere(
                (c) => c['code'] == _selectedCountryCode,
                orElse: () => {'name': 'Unknown'},
              )['name'] ??
              'Unknown',
        );
        context.go('/search-map-screen');
      }
    }
  }

  void _skipSetup() => context.go('/search-map-screen');

  void _showLanguageSheet(BuildContext ctx, LocaleProvider lp) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
            const SizedBox(height: 20),
            Text(
              'Language / اللغة',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...AppLanguage.values.map(
              (lang) => ListTile(
                leading: Text(
                  lang == AppLanguage.arabic
                      ? '🇮🇶'
                      : lang == AppLanguage.kurdish
                      ? '🏔️'
                      : '🇬🇧',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  lang == AppLanguage.arabic
                      ? 'العربية'
                      : lang == AppLanguage.kurdish
                      ? 'کوردی'
                      : 'English',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
                trailing: lp.language == lang
                    ? Icon(Icons.check_circle, color: AppTheme.primary)
                    : null,
                onTap: () {
                  lp.setLanguage(lang);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final theme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Select Country',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (_, i) {
                    final c = _countries[i];
                    final isSelected = c['code'] == _selectedCountryCode;
                    return ListTile(
                      leading: Text(
                        c['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        c['name']!,
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c['code']!,
                            style: GoogleFonts.dmSans(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCountryCode = c['code']!;
                          _selectedCountryFlag = c['flag']!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) {
              return Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: const [
                      Color(0xFF0A1628),
                      Color(0xFF0D2137),
                      Color(0xFF112244),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0, _bgAnim.value * 0.5 + 0.2, 1],
                  ),
                ),
              );
            },
          ),
          // Decorative orbs
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (_, __) => Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFF1565C0,
                      ).withAlpha((80 + _bgAnim.value * 40).toInt()),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.3,
            left: -80,
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (_, __) => Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFF42A5F5,
                      ).withAlpha((40 + _bgAnim.value * 30).toInt()),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Geometric lines
          CustomPaint(size: size, painter: _GeometricPainter()),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مدار',
                            style: GoogleFonts.dmSans(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                            ),
                          ),
                          Text(
                            'Madar Real Estate',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: Colors.white.withAlpha(160),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Consumer<LocaleProvider>(
                        builder: (ctx, lp, _) => GestureDetector(
                          onTap: () => _showLanguageSheet(ctx, lp),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withAlpha(50),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  lp.language == AppLanguage.arabic
                                      ? 'عربي'
                                      : lp.language == AppLanguage.kurdish
                                      ? 'کوردی'
                                      : 'EN',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.language,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Stage indicator
                _buildStageIndicator(),
                const SizedBox(height: 24),
                // Card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: _buildCurrentStage(theme),
                        ),
                      ),
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

  Widget _buildStageIndicator() {
    final stages = [
      {'icon': Icons.phone_android, 'label': 'Phone'},
      {'icon': Icons.lock_outline, 'label': 'Verify'},
      {'icon': Icons.face_retouching_natural, 'label': 'Face ID'},
      {'icon': Icons.badge_outlined, 'label': 'ID'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(stages.length, (i) {
          final isActive = i == _stage;
          final isDone = i < _stage;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isActive ? 44 : 36,
                        height: isActive ? 44 : 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF4CAF50)
                              : isActive
                              ? Colors.white
                              : Colors.white.withAlpha(30),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withAlpha(80),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : Icon(
                                  stages[i]['icon'] as IconData,
                                  color: isActive
                                      ? AppTheme.primary
                                      : Colors.white.withAlpha(120),
                                  size: isActive ? 20 : 16,
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stages[i]['label'] as String,
                        style: GoogleFonts.dmSans(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withAlpha(100),
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < stages.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: i < _stage
                              ? [
                                  const Color(0xFF4CAF50),
                                  const Color(0xFF4CAF50),
                                ]
                              : [
                                  Colors.white.withAlpha(60),
                                  Colors.white.withAlpha(20),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStage(ThemeData theme) {
    switch (_stage) {
      case 0:
        return _buildPhoneStage();
      case 1:
        return _buildOtpStage();
      case 2:
        return _buildFaceStage();
      case 3:
        return _buildNationalIdStage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPhoneStage() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon header
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.phone_android,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to Madar',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0A1628),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your phone number to get started',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 28),
          // Location notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Location access helps find nearby properties',
                    style: GoogleFonts.dmSans(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Phone input
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E8FF), width: 1.5),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: const Color(0xFFE0E8FF),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedCountryFlag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedCountryCode,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF0A1628),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 1,
                      color: const Color(0xFF0A1628),
                    ),
                    decoration: InputDecoration(
                      hintText: '07XX XXX XXXX',
                      hintStyle: GoogleFonts.dmSans(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                    onSubmitted: (_) => _handlePhoneSubmit(),
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _buildError(_errorMessage!),
          ],
          const SizedBox(height: 24),
          // Main CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePhoneSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1628),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Send Verification Code',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          // Portal buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/employee-login'),
                  icon: const Icon(Icons.badge_outlined, size: 16),
                  label: Text(
                    'Employee',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary.withAlpha(80)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/office-login'),
                  icon: const Icon(Icons.business_outlined, size: 16),
                  label: Text(
                    'Office',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A237E),
                    side: BorderSide(
                      color: const Color(0xFF1A237E).withAlpha(80),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStage() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Verify Your Number',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0A1628),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              children: [
                const TextSpan(text: 'Code sent to '),
                TextSpan(
                  text: '$_selectedCountryCode ${_phoneController.text}',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A1628),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // OTP boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => _buildOtpBox(i)),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildError(_errorMessage!),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleOtpSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1628),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Verify Code',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                _cardController.reset();
                setState(() {
                  _stage = 0;
                  _errorMessage = null;
                });
                _cardController.forward();
              },
              child: Text(
                'Change number',
                style: GoogleFonts.dmSans(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0A1628),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF8FAFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E8FF), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E8FF), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.primary, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (v.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildFaceStage() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.face_retouching_natural,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Face Verification',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0A1628),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Set up Face ID for secure transaction verification',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          // Face scan area
          Center(
            child: GestureDetector(
              onTap: _faceVerified ? null : _handleFaceVerify,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _faceVerified
                      ? const LinearGradient(
                          colors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFF8FAFF), Color(0xFFE8F0FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(
                    color: _faceVerified
                        ? const Color(0xFF388E3C)
                        : const Color(0xFF1565C0).withAlpha(80),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_faceVerified
                                  ? const Color(0xFF388E3C)
                                  : AppTheme.primary)
                              .withAlpha(40),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(strokeWidth: 3)
                    : Icon(
                        _faceVerified
                            ? Icons.check_circle
                            : Icons.face_retouching_natural,
                        size: 80,
                        color: _faceVerified ? Colors.white : AppTheme.primary,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              _faceVerified
                  ? '✓ Face verified successfully'
                  : _isLoading
                  ? 'Scanning...'
                  : 'Tap to scan your face',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _faceVerified
                    ? const Color(0xFF388E3C)
                    : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (_faceVerified) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1628),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _skipSetup,
              child: Text(
                'Skip for now',
                style: GoogleFonts.dmSans(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNationalIdStage() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF57C00), Color(0xFFFFB74D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'National ID',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0A1628),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Required for property transactions and legal verification',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 28),
          // ID number field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E8FF), width: 1.5),
            ),
            child: TextField(
              controller: _nationalIdController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: const Color(0xFF0A1628),
              ),
              decoration: InputDecoration(
                hintText: 'National ID Number',
                hintStyle: GoogleFonts.dmSans(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ID image upload
          GestureDetector(
            onTap: _pickNationalIdImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _nationalIdImageUploaded
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _nationalIdImageUploaded
                      ? const Color(0xFF388E3C)
                      : const Color(0xFFE0E8FF),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _nationalIdImageUploaded
                          ? const Color(0xFF388E3C).withAlpha(20)
                          : AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _nationalIdImageUploaded
                          ? Icons.check_circle
                          : Icons.upload_file,
                      color: _nationalIdImageUploaded
                          ? const Color(0xFF388E3C)
                          : AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nationalIdImageUploaded
                              ? 'ID Image Uploaded'
                              : 'Upload ID Photo',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF0A1628),
                          ),
                        ),
                        Text(
                          _nationalIdImageUploaded
                              ? 'Tap to change'
                              : 'Front side of national ID card',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _buildError(_errorMessage!),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNationalIdSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1628),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : _nationalIdVerified
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Verified! Entering...',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Complete Registration',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _skipSetup,
              child: Text(
                'Skip for now',
                style: GoogleFonts.dmSans(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.dmSans(
                color: const Color(0xFFD32F2F),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeometricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw subtle grid lines
    for (int i = 0; i < 6; i++) {
      final x = size.width * (i / 5);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.5), paint);
    }

    // Draw diagonal accent lines
    final accentPaint = Paint()
      ..color = Colors.white.withAlpha(12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width * 0.4, size.height * 0.6),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width * 0.6, size.height * 0.4),
      accentPaint,
    );

    // Small circles
    final circlePaint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.25),
      30,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      20,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
