import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const String routeName = '/onboarding';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    18,
                    24,
                    22,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _buildLogo(),

                      const SizedBox(height: 36),

                      _buildHeading(),

                      const SizedBox(height: 14),

                      _buildDescription(),

                      const SizedBox(height: 24),

                      const _RoomPreview(),

                      const SizedBox(height: 26),

                      const _PageIndicator(),

                      const SizedBox(height: 110),

                      _GetStartedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/login',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/branding/roomstylo_logo.png',
        height: 58,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return const _FallbackLogo();
        },
      ),
    );
  }

  Widget _buildHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Room',
          style: TextStyle(
            color: AppColors.forestDark,
            fontSize: 36,
            height: 1.05,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.1,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'New Possibilities',
          style: TextStyle(
            color: AppColors.goldDark,
            fontSize: 36,
            height: 1.05,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return const Text(
      'Upload your room, get stunning\n'
          'design ideas with AI.',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _RoomPreview extends StatelessWidget {
  const _RoomPreview();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.20,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 16,
            right: 40,
            top: 4,
            bottom: 25,
            child: Transform.rotate(
              angle: -0.035,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius:
                  BorderRadius.circular(28),
                ),
              ),
            ),
          ),

          Positioned(
            left: 2,
            right: 22,
            top: 32,
            bottom: 5,
            child: Transform.rotate(
              angle: 0.035,
              child: Container(
                decoration: BoxDecoration(
                  gradient:
                  AppColors.goldGradient,
                  borderRadius:
                  BorderRadius.circular(28),
                ),
              ),
            ),
          ),

          Positioned(
            left: 14,
            right: 14,
            top: 20,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.12,
                    ),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/onboarding/'
                      'onboarding_room_1.webp',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Positioned(
            right: 2,
            top: 0,
            child: Transform.rotate(
              angle: 0.20,
              child: const Icon(
                Icons.south_east_rounded,
                color: AppColors.forestDark,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(
          active: true,
        ),
        SizedBox(width: 9),
        _Dot(),
        SizedBox(width: 9),
        _Dot(),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    this.active = false,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 250,
      ),
      width: active ? 9 : 8,
      height: active ? 9 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? AppColors.forest
            : AppColors.divider,
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius:
          BorderRadius.circular(32),
          child: Ink(
            decoration: BoxDecoration(
              gradient:
              AppColors.primaryGradient,
              borderRadius:
              BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color:
                  AppColors.forest.withValues(
                    alpha: 0.18,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 9,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),

                  const Expanded(
                    child: Text(
                      'Get Started',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),

                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                    const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.forest,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.chair_alt_rounded,
          color: AppColors.forest,
          size: 34,
        ),
        SizedBox(width: 9),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
            ),
            children: [
              TextSpan(
                text: 'Room',
                style: TextStyle(
                  color: AppColors.forestDark,
                ),
              ),
              TextSpan(
                text: 'Stylo',
                style: TextStyle(
                  color: AppColors.goldDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}