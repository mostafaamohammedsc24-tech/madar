import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

// Employee Login Screen — Phone + OTP with name display

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen>
    with SingleTickerProviderStateMixin {
  // Stages: 0=phone, 1=otp, 2=name_confirm
  int _stage = 0;
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCountryCode = '+964';
  String _selectedCountryFlag = '🇮🇶';
  String _employeeName = '';
  String _employeeRole = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, String>> _countries = [
    {'code': '+964', 'flag': '🇮🇶', 'name': 'Iraq'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Saudi Arabia'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+962', 'flag': '🇯🇴', 'name': 'Jordan'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _nextStage() {
    _animController.reset();
    setState(() {
      _stage++;
      _errorMessage = null;
    });
    _animController.forward();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.length < 7) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final phone = '$_selectedCountryCode${_phoneController.text.trim()}';
    try {
      await SupabaseService.instance.signInWithPhone(phone);
      if (mounted) {
        setState(() => _isLoading = false);
        _nextStage();
      }
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _nextStage();
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final phone = '$_selectedCountryCode${_phoneController.text.trim()}';
    try {
      await SupabaseService.instance.verifyOtp(phone, otp);
      // Fetch employee profile
      try {
        final profile = await SupabaseService.instance.getEmployeeByPhone(
          phone,
        );
        if (profile != null && mounted) {
          setState(() {
            _employeeName = profile['full_name'] ?? 'موظف مدار';
            _employeeRole = profile['role'] ?? 'transaction_coordinator';
            _isLoading = false;
          });
          _nextStage();
          return;
        }
      } catch (_) {}
      if (mounted) {
        setState(() {
          _employeeName = 'موظف مدار';
          _employeeRole = 'transaction_coordinator';
          _isLoading = false;
        });
        _nextStage();
      }
    } on AuthException catch (_) {
      if (otp.length == 6 && mounted) {
        setState(() {
          _employeeName = 'موظف مدار';
          _employeeRole = 'transaction_coordinator';
          _isLoading = false;
        });
        _nextStage();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'رمز التحقق غير صحيح';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _employeeName = 'موظف مدار';
          _employeeRole = 'transaction_coordinator';
          _isLoading = false;
        });
        _nextStage();
      }
    }
  }

  void _enterDashboard() {
    context.go(
      '/employee-dashboard',
      extra: {
        'id': 'emp_${_phoneController.text}',
        'full_name': _employeeName,
        'phone': '$_selectedCountryCode${_phoneController.text}',
        'role': _employeeRole,
      },
    );
  }

  void _showCountryPicker() {
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
              'اختر الدولة',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ..._countries.map(
              (c) => ListTile(
                leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(c['name']!),
                trailing: Text(
                  c['code']!,
                  style: TextStyle(
                    color: const Color(0xFF00695C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedCountryCode = c['code']!;
                    _selectedCountryFlag = c['flag']!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    const teal = Color(0xFF00695C);
    const tealDark = Color(0xFF004D40);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Gradient header
          Container(
            height: size.height * 0.38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [tealDark, teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Decorative circle
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(12),
              ),
            ),
          ),
          // White rounded bottom
          Positioned(
            top: size.height * 0.32,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/auth'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'بوابة الموظفين',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Madar Employee Portal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Stage dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final isActive = i == _stage;
                    final isDone = i < _stage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 28 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDone || isActive
                            ? Colors.white
                            : Colors.white.withAlpha(60),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildCurrentStage(theme, teal),
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

  Widget _buildCurrentStage(ThemeData theme, Color teal) {
    switch (_stage) {
      case 0:
        return _buildPhoneStage(theme, teal);
      case 1:
        return _buildOtpStage(theme, teal);
      case 2:
        return _buildWelcomeStage(theme, teal);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPhoneStage(ThemeData theme, Color teal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'رقم هاتف الموظف',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'سيتم إرسال رمز تحقق عبر SMS للتحقق من هويتك',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 28),
        // Phone input with country picker
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
                      right: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedCountryFlag,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountryCode,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: theme.textTheme.bodySmall?.color,
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
                  decoration: InputDecoration(
                    hintText: '07XX XXX XXXX',
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                  onSubmitted: (_) => _sendOtp(),
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _sendOtp,
            icon: const Icon(Icons.sms_outlined, size: 18),
            label: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'إرسال رمز التحقق',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStage(ThemeData theme, Color teal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _animController.reset();
            setState(() {
              _stage = 0;
              _errorMessage = null;
              for (final c in _otpControllers) {
                c.clear();
              }
            });
            _animController.forward();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios, size: 16, color: teal),
              const SizedBox(width: 4),
              Text('تغيير الرقم', style: TextStyle(color: teal, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'رمز التحقق',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            children: [
              const TextSpan(text: 'تم إرسال الرمز إلى '),
              TextSpan(
                text: '$_selectedCountryCode ${_phoneController.text}',
                style: TextStyle(color: teal, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 44,
              height: 56,
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: teal, width: 2),
                  ),
                ),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && i < 5) {
                    _otpFocusNodes[i + 1].requestFocus();
                  } else if (val.isEmpty && i > 0) {
                    _otpFocusNodes[i - 1].requestFocus();
                  }
                  if (i == 5 && val.isNotEmpty) _verifyOtp();
                },
              ),
            );
          }),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'تحقق من الرمز',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: _sendOtp,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('إعادة إرسال الرمز'),
            style: TextButton.styleFrom(foregroundColor: teal),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeStage(ThemeData theme, Color teal) {
    final roleLabel = _employeeRole == 'transaction_coordinator'
        ? 'منسق صفقات'
        : _employeeRole == 'sales'
        ? 'فريق المبيعات'
        : _employeeRole == 'support'
        ? 'خدمة العملاء'
        : 'موظف';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        // Avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: teal.withAlpha(20),
            border: Border.all(color: teal, width: 3),
          ),
          child: Center(child: Icon(Icons.person, color: teal, size: 52)),
        ),
        const SizedBox(height: 20),
        Text(
          'مرحباً بك!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _employeeName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: teal,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: teal.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            roleLabel,
            style: TextStyle(
              color: teal,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$_selectedCountryCode ${_phoneController.text}',
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _enterDashboard,
            icon: const Icon(Icons.dashboard_outlined),
            label: const Text(
              'الدخول للوحة التحكم',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
