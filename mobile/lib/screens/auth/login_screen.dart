import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import 'forgot_password_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController =
  TextEditingController();

  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get _isFormValid {
    return _isValidEmail(
      _emailController.text.trim(),
    ) &&
        _passwordController.text.isNotEmpty;
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
  }

  void _refreshForm() {
    setState(() {});
  }

  Future<void> _login() async {
    if (!_isFormValid || _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeScreen.routeName,
            (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _googleLogin() async {
    if (_isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.loginWithGoogle();

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeScreen.routeName,
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to sign in with Google. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _emailController.addListener(_refreshForm);
    _passwordController.addListener(_refreshForm);
  }

  @override
  void dispose() {
    _emailController.removeListener(_refreshForm);
    _passwordController.removeListener(_refreshForm);

    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            30,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/branding/roomstylo_logo.png',
                  height: 62,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: AppColors.forestDark,
                  fontSize: 34,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sign in to continue designing your perfect space.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 34),
              const _FieldLabel(
                text: 'Email',
              ),
              const SizedBox(height: 9),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType:
                TextInputType.emailAddress,
                textInputAction:
                TextInputAction.next,
                autocorrect: false,
                autofillHints: const [
                  AutofillHints.email,
                ],
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    color:
                    AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const _FieldLabel(
                text: 'Password',
              ),
              const SizedBox(height: 9),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                textInputAction:
                TextInputAction.done,
                onSubmitted: (_) {
                  _login();
                },
                autofillHints: const [
                  AutofillHints.password,
                ],
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color:
                    AppColors.textSecondary,
                  ),
                  suffixIcon: IconButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      setState(() {
                        _obscurePassword =
                        !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons
                          .visibility_off_outlined
                          : Icons
                          .visibility_outlined,
                      color:
                      AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                    Navigator.pushNamed(
                      context,
                      ForgotPasswordScreen.routeName,
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                    AppColors.goldDark,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _PrimaryAuthButton(
                text: 'Sign In',
                enabled: _isFormValid,
                isLoading: _isLoading,
                onPressed: _login,
              ),
              const SizedBox(height: 30),
              const _OrDivider(),
              const SizedBox(height: 24),
              _GoogleButton(
                enabled: !_isLoading,
                onPressed: _googleLogin,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  const Text(
                    'New to RoomStylo?',
                    style: TextStyle(
                      color:
                      AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      Navigator.pushNamed(
                        context,
                        '/register',
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor:
                      AppColors.forest,
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    required this.text,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final String text;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final canPress = enabled && !isLoading;

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 220,
      ),
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: canPress
            ? [
          BoxShadow(
            color:
            AppColors.forest.withValues(
              alpha: 0.17,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ]
            : [],
      ),
      child: ElevatedButton(
        onPressed:
        canPress ? onPressed : null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor:
          AppColors.forest.withValues(
            alpha: 0.16,
          ),
          disabledForegroundColor:
          AppColors.forest.withValues(
            alpha: 0.45,
          ),
          backgroundColor:
          AppColors.forest,
          foregroundColor:
          AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child:
          CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.white,
          ),
        )
            : Text(text),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Divider(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
          ),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Divider(),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed:
        enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor:
          AppColors.surface,
          foregroundColor:
          AppColors.textPrimary,
          side: const BorderSide(
            color: AppColors.divider,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(18),
          ),
        ),
        child: const Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            _GoogleMark(),
            SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: TextStyle(
                color:
                AppColors.textPrimary,
                fontSize: 15,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}