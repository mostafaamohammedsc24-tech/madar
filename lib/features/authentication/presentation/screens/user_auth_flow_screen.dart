import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/models/user_auth_state.dart';
import '../providers/user_auth_notifier.dart';
import 'auth_loading_screen.dart';
import 'face_verification_setup_screen.dart';
import 'location_permission_screen.dart';
import 'otp_verification_screen.dart';
import 'phone_number_screen.dart';

/// Root user authentication flow — renders the correct step based on state.
class UserAuthFlowScreen extends StatefulWidget {
  const UserAuthFlowScreen({super.key});

  @override
  State<UserAuthFlowScreen> createState() => _UserAuthFlowScreenState();
}

class _UserAuthFlowScreenState extends State<UserAuthFlowScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserAuthNotifier>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<UserAuthNotifier>();
    final status = auth.state.status;

    if (status == UserAuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/search-map-screen');
      });
      return const AuthLoadingScreen();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: switch (status) {
        UserAuthStatus.initializing => const AuthLoadingScreen(key: ValueKey('init')),
        UserAuthStatus.unauthenticated => const PhoneNumberScreen(key: ValueKey('phone')),
        UserAuthStatus.awaitingOtpVerification => const OtpVerificationScreen(key: ValueKey('otp')),
        UserAuthStatus.awaitingLocationPermission => const LocationPermissionScreen(key: ValueKey('location')),
        UserAuthStatus.awaitingFaceVerification => const FaceVerificationSetupScreen(key: ValueKey('face')),
        UserAuthStatus.failure => const PhoneNumberScreen(key: ValueKey('failure')),
        UserAuthStatus.authenticated => const AuthLoadingScreen(key: ValueKey('done')),
      },
    );
  }
}
