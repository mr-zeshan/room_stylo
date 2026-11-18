import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
  TextEditingController();

  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool get _passwordsMatch {
    return _passwordController.text ==
        _confirmPasswordController.text;
  }

  bool get _isFormValid {
    return _nameController.text.trim().length >= 2 &&
        _isValidEmail(_emailController.text.trim()) &&
        _passwordController.text.length >= 8 &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordsMatch;
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
  }

  void _refreshForm() {
    setState(() {});
  }

  Future<void> _register() async {
    if (!_isFormValid || _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully. Please sign in.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
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

  Future<void> _googleRegister() async {
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
            'Unable to continue with Google. Please try again.',
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

    _nameController.addListener(_refreshForm);
    _emailController.addListener(_refreshForm);
    _passwordController.addListener(_refreshForm);
    _confirmPasswordController.addListener(_refreshForm);
  }

  @override
  void dispose() {
    _nameController.removeListener(_refreshForm);
    _emailController.removeListener(_refreshForm);
    _passwordController.removeListener(_refreshForm);
    _confirmPasswordController.removeListener(_refreshForm);

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showConfirmError =
        _confirmPasswordController.text.isNotEmpty &&
            !_passwordsMatch;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            24,
            18,
            24,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: _isLoading
                    ? null
                    : () {
                  Navigator.pop(context);
                },
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.forestDark,
                  size: 27,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Image.asset(
                  'assets/branding/roomstylo_logo.png',
                  height: 55,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 34),
              const Text(
                'Create Your Account',
                style: TextStyle(
                  color: AppColors.forestDark,
                  fontSize: 32,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Start transforming your rooms with personalized AI design.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _AuthField(
                label: 'Name',
                controller: _nameController,
                hint: 'Enter your name',
                icon: Icons.person_outline_rounded,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.name,
                ],
              ),
              const SizedBox(height: 19),
              _AuthField(
                label: 'Email',
                controller: _emailController,
                hint: 'Enter your email',
                icon: Icons.mail_outline_rounded,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.email,
                ],
              ),
              const SizedBox(height: 19),
              _PasswordField(
                label: 'Password',
                hint: 'Create a password',
                controller: _passwordController,
                obscure: _obscurePassword,
                enabled: !_isLoading,
                onToggle: () {
                  setState(() {
                    _obscurePassword =
                    !_obscurePassword;
                  });
                },
              ),
              const SizedBox(height: 7),
              const Padding(
                padding: EdgeInsets.only(
                  left: 4,
                ),
                child: Text(
                  'Use at least 8 characters.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              _PasswordField(
                label: 'Confirm Password',
                hint: 'Enter password again',
                controller:
                _confirmPasswordController,
                obscure: _obscureConfirmPassword,
                enabled: !_isLoading,
                errorText: showConfirmError
                    ? 'Passwords do not match'
                    : null,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  _register();
                },
                onToggle: () {
                  setState(() {
                    _obscureConfirmPassword =
                    !_obscureConfirmPassword;
                  });
                },
              ),
              const SizedBox(height: 28),
              _PrimaryAuthButton(
                text: 'Create Account',
                enabled: _isFormValid,
                isLoading: _isLoading,
                onPressed: _register,
              ),
              const SizedBox(height: 26),
              const _OrDivider(),
              const SizedBox(height: 22),
              _GoogleButton(
                enabled: !_isLoading,
                onPressed: _googleRegister,
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.goldDark,
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
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

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autocorrect: false,
          autofillHints: autofillHints,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.enabled,
    required this.onToggle,
    this.errorText,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final bool enabled;
  final VoidCallback onToggle;
  final String? errorText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autofillHints: const [
            AutofillHints.newPassword,
          ],
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
            ),
            suffixIcon: IconButton(
              onPressed: enabled ? onToggle : null,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
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
            color: AppColors.forest.withValues(
              alpha: 0.17,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: canPress ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.white,
          disabledBackgroundColor:
          AppColors.forest.withValues(
            alpha: 0.16,
          ),
          disabledForegroundColor:
          AppColors.forest.withValues(
            alpha: 0.45,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
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
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(
            color: AppColors.divider,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleMark(),
            SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
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