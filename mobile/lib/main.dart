import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const RoomStyloApp());
}

class RoomStyloApp extends StatelessWidget {
  const RoomStyloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomStylo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
      routes: {
        OnboardingScreen.routeName:
            (context) =>
        const OnboardingScreen(),

        LoginScreen.routeName:
            (context) =>
        const LoginScreen(),

        RegisterScreen.routeName:
            (context) =>
        const RegisterScreen(),

        ForgotPasswordScreen.routeName:
            (context) =>
        const ForgotPasswordScreen(),

        HomeScreen.routeName:
            (context) =>
        const HomeScreen(),
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() =>
      _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _authService = AuthService();

  bool? _isAuthenticated;

  @override
  void initState() {
    super.initState();

    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final authenticated =
      await _authService.restoreSession();

      if (!mounted) {
        return;
      }

      setState(() {
        _isAuthenticated = authenticated;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAuthenticated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated == null) {
      return const _StartupScreen();
    }

    if (_isAuthenticated!) {
      return const HomeScreen();
    }

    return const OnboardingScreen();
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.forest,
        ),
      ),
    );
  }
}