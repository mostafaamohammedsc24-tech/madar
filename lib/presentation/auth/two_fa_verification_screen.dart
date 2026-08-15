import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';

class TwoFaVerificationScreen extends StatefulWidget {
  const TwoFaVerificationScreen({super.key});

  @override
  State<TwoFaVerificationScreen> createState() =>
      _TwoFaVerificationScreenState();
}

class _TwoFaVerificationScreenState extends State<TwoFaVerificationScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0; // 0=intro, 1=OTP, 2=face, 3=national_id, 4=done
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  String _generatedOtp = '';
  bool _otpVerified = false;
  bool _faceVerified = false;
  bool _idUploaded = false;
  bool _isProcessing = false;
  XFile? _idImage;
  XFile? _selfieImage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _checkController;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnim = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _generateOtp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _generateOtp() {
    final rng = Random();
    _generatedOtp = List.generate(6, (_) => rng.nextInt(10).toString()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A0E1A),
                  Color(0xFF0D1B2A),
                  Color(0xFF0A0E1A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1565C0).withAlpha(50),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildStepIndicator(),
                Expanded(child: _buildCurrentStep()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(30)),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identity Verification',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '2FA · Secure your account',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(140),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1565C0).withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, color: Color(0xFF42A5F5), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Secure',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF42A5F5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Intro', 'OTP', 'Face', 'ID', 'Done'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = i < _currentStep;
          final active = i == _currentStep;
          final color = done || active
              ? const Color(0xFF1565C0)
              : Colors.white.withAlpha(30);
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: active ? 32 : 24,
                        height: active ? 32 : 24,
                        decoration: BoxDecoration(
                          color: done
                              ? const Color(0xFF388E3C)
                              : active
                              ? const Color(0xFF1565C0)
                              : Colors.white.withAlpha(15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color,
                            width: active ? 2 : 1,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1565C0,
                                    ).withAlpha(80),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: GoogleFonts.dmSans(
                                    color: active
                                        ? Colors.white
                                        : Colors.white.withAlpha(80),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i],
                        style: GoogleFonts.dmSans(
                          color: active
                              ? Colors.white
                              : Colors.white.withAlpha(80),
                          fontSize: 9,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: i < _currentStep
                            ? const Color(0xFF388E3C)
                            : Colors.white.withAlpha(20),
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

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildIntroStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildFaceStep();
      case 3:
        return _buildIdStep();
      case 4:
        return _buildDoneStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── STEP 0: INTRO ────────────────────────────────────────────────────────

  Widget _buildIntroStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withAlpha(80),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_user,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Secure Your Account',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete 3-step identity verification to enable 2FA and participate in property transactions.',
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(160),
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildVerificationStep(
            1,
            Icons.sms,
            'OTP Verification',
            'Receive a 6-digit code via SMS to your registered phone number',
            const Color(0xFF1565C0),
          ),
          const SizedBox(height: 12),
          _buildVerificationStep(
            2,
            Icons.face_retouching_natural,
            'Face Verification',
            'Take a selfie to verify your identity using facial recognition',
            const Color(0xFF7B1FA2),
          ),
          const SizedBox(height: 12),
          _buildVerificationStep(
            3,
            Icons.badge,
            'National ID Upload',
            'Upload a clear photo of your national ID card for document verification',
            const Color(0xFF388E3C),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Verification',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStep(
    int num,
    IconData icon,
    String title,
    String desc,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$num',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withAlpha(140),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 1: OTP ──────────────────────────────────────────────────────────

  Widget _buildOtpStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withAlpha(80),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(Icons.sms, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 20),
          Text(
            'Enter OTP Code',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A 6-digit code has been sent to your phone number',
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(160),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Demo OTP hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1565C0).withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF42A5F5),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'Demo OTP: $_generatedOtp',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF42A5F5),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return Container(
                width: 46,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _otpFocusNodes[i].hasFocus
                        ? const Color(0xFF1565C0)
                        : Colors.white.withAlpha(25),
                    width: _otpFocusNodes[i].hasFocus ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _otpControllers[i],
                  focusNode: _otpFocusNodes[i],
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && i < 5) {
                      FocusScope.of(
                        context,
                      ).requestFocus(_otpFocusNodes[i + 1]);
                    } else if (val.isEmpty && i > 0) {
                      FocusScope.of(
                        context,
                      ).requestFocus(_otpFocusNodes[i - 1]);
                    }
                    setState(() {});
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Verify OTP',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _generateOtp();
              setState(() {});
            },
            child: Text(
              'Resend Code',
              style: GoogleFonts.dmSans(
                color: const Color(0xFF42A5F5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final entered = _otpControllers.map((c) => c.text).join();
    if (entered.length < 6) return;
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (entered == _generatedOtp) {
      if (mounted) {
        setState(() {
          _otpVerified = true;
          _isProcessing = false;
          _currentStep = 2;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid OTP. Hint: $_generatedOtp'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── STEP 2: FACE ─────────────────────────────────────────────────────────

  Widget _buildFaceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: _faceVerified ? 1.0 : _pulseAnim.value,
              child: child,
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _faceVerified
                      ? [const Color(0xFF388E3C), const Color(0xFF4CAF50)]
                      : [const Color(0xFF7B1FA2), const Color(0xFFAB47BC)],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_faceVerified
                                ? const Color(0xFF388E3C)
                                : const Color(0xFF7B1FA2))
                            .withAlpha(80),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Icon(
                _faceVerified
                    ? Icons.check_circle
                    : Icons.face_retouching_natural,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _faceVerified ? 'Face Verified!' : 'Face Verification',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _faceVerified
                ? 'Your face has been successfully verified and registered.'
                : 'Take a clear selfie in good lighting. Make sure your face is fully visible.',
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(160),
              fontSize: 13,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_selfieImage != null && !_faceVerified) ...[
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7B1FA2), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B1FA2).withAlpha(60),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (!_faceVerified) ...[
            // Camera preview placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF7B1FA2).withAlpha(60),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: Colors.white.withAlpha(60),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Camera Preview',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withAlpha(80),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Position your face in the frame',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withAlpha(60),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickSelfie(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: Text(
                      'Gallery',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withAlpha(40)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickSelfie(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Take Selfie',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _currentStep = 3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue to ID Upload',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickSelfie(ImageSource source) async {
    setState(() => _isProcessing = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null && mounted) {
        setState(() {
          _selfieImage = image;
          _isProcessing = false;
        });
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() => _faceVerified = true);
          _checkController.forward();
        }
      } else {
        if (mounted) setState(() => _isProcessing = false);
      }
    } catch (e) {
      // Simulate success for demo
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _faceVerified = true;
        });
        _checkController.forward();
      }
    }
  }

  // ─── STEP 3: NATIONAL ID ──────────────────────────────────────────────────

  Widget _buildIdStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _idUploaded
                    ? [const Color(0xFF388E3C), const Color(0xFF4CAF50)]
                    : [const Color(0xFF1B5E20), const Color(0xFF388E3C)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF388E3C).withAlpha(80),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              _idUploaded ? Icons.check_circle : Icons.badge,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _idUploaded ? 'ID Uploaded!' : 'Upload National ID',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _idUploaded
                ? 'Your national ID has been uploaded and is under review.'
                : 'Upload a clear, well-lit photo of your national ID card (front side).',
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(160),
              fontSize: 13,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // ID card preview area
          GestureDetector(
            onTap: _idUploaded ? null : () => _pickIdImage(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: _idUploaded
                    ? const Color(0xFF388E3C).withAlpha(15)
                    : Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _idUploaded
                      ? const Color(0xFF388E3C).withAlpha(80)
                      : const Color(0xFF388E3C).withAlpha(40),
                  width: 2,
                  style: _idUploaded ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: _idImage != null || _idUploaded
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=200&fit=crop',
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            color: Colors.black.withAlpha(60),
                            colorBlendMode: BlendMode.darken,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF388E3C).withAlpha(200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ID Uploaded',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file,
                          color: const Color(0xFF388E3C).withAlpha(160),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload National ID',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withAlpha(120),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG · Max 5MB',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withAlpha(60),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_idUploaded) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickIdImage(source: ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: Text(
                      'Gallery',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withAlpha(40)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickIdImage(source: ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Take Photo',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF388E3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _currentStep = 4),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Complete Verification',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF42A5F5),
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your ID is encrypted and stored securely. It will only be used for identity verification during transactions.',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withAlpha(140),
                      fontSize: 11,
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

  Future<void> _pickIdImage({ImageSource source = ImageSource.gallery}) async {
    setState(() => _isProcessing = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 90);
      if (image != null && mounted) {
        setState(() {
          _idImage = image;
          _isProcessing = false;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _idUploaded = true);
      } else {
        if (mounted) setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _idUploaded = true;
        });
      }
    }
  }

  // ─── STEP 4: DONE ─────────────────────────────────────────────────────────

  Widget _buildDoneStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          ScaleTransition(
            scale: _checkAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withAlpha(80),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.verified, color: Colors.white, size: 60),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Verification Complete!',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your identity has been verified. You can now participate in property transactions securely.',
            style: GoogleFonts.dmSans(
              color: Colors.white.withAlpha(160),
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4CAF50).withAlpha(40)),
            ),
            child: Column(
              children: [
                _buildVerificationResult(
                  'OTP Verification',
                  _otpVerified,
                  Icons.sms,
                ),
                const SizedBox(height: 12),
                _buildVerificationResult(
                  'Face Verification',
                  _faceVerified,
                  Icons.face_retouching_natural,
                ),
                const SizedBox(height: 12),
                _buildVerificationResult(
                  'National ID Upload',
                  _idUploaded,
                  Icons.badge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Back to Dashboard',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationResult(String label, bool done, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: done
                ? const Color(0xFF388E3C).withAlpha(25)
                : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: done ? const Color(0xFF4CAF50) : Colors.white.withAlpha(60),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: done
                ? const Color(0xFF388E3C).withAlpha(25)
                : Colors.orange.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            done ? '✓ Verified' : 'Pending',
            style: GoogleFonts.dmSans(
              color: done ? const Color(0xFF4CAF50) : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
