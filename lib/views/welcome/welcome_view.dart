import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/bottombar/bottom_bar_widegt.dart';
import 'package:dedicated_cowboy/consts/appcolors.dart';

import 'package:dedicated_cowboy/views/sign_in/sign_in_view.dart';
import 'package:dedicated_cowboy/views/sign_up/sign_up_view.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:google_fonts/google_fonts.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _bottomSheetController;
  late AnimationController _logoPositionController;

  late Animation<double> _logoAnimation;
  late Animation<Offset> _bottomSheetAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _logoPositionAnimation;

  bool _showBottomSheet = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo position animation controller
    _logoPositionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Bottom sheet animation controller - Reduced duration for smoother animation
    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Logo fade and scale animation
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Fade animation for logo
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Logo position animation (center to top)
    _logoPositionAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0), // center
      end: const Offset(0.0, -0.3), // move up
    ).animate(
      CurvedAnimation(parent: _logoPositionController, curve: Curves.easeInOut),
    );

    // Bottom sheet slide animation - Using better curve
    _bottomSheetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _bottomSheetController,
        curve: Curves.fastOutSlowIn, // Better curve for smoother animation
      ),
    );
  }

  Future<void> _startSplashSequence() async {
    // Start logo animation
    _logoController.forward();

    // Wait for 2.5 seconds to show the splash
    await Future.delayed(const Duration(milliseconds: 2500));

    // Check Firebase Auth
    final authService = Get.find<AuthService>();

    if (authService.isSignedIn) {
      // User is logged in, navigate to home screen
      Get.offAll(() => CustomCurvedNavBar());
    } else {
      // User is not logged in, show welcome screen
      setState(() {
        _showBottomSheet = true;
      });

      // Animate logo to top and show bottom sheet
      _logoPositionController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _bottomSheetController.forward();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _logoPositionController.dispose();
    _bottomSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
            ),

            // Logo (animated position) - Separated animations to avoid unnecessary rebuilds
            AnimatedBuilder(
              animation: _logoPositionController,
              builder: (context, child) {
                return SlideTransition(
                  position: _logoPositionAnimation,
                  child: child,
                );
              },
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(scale: _logoAnimation, child: child),
                  );
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Image.asset(
                      'assets/images/Original on transparent[1] 1 (1).png',
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Sheet with welcome content
            if (_showBottomSheet)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _bottomSheetController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _bottomSheetAnimation,
                      child: child,
                    );
                  },
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: BoxDecoration(
                      color: appColors.pYellow,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: _buildWelcomeContent(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeContent() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(), // Better scroll physics
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),

            // Pre-build all widgets to avoid repeated calculations
            _buildStaggeredContent(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStaggeredContent() {
    // Pre-create all text styles to avoid repeated GoogleFonts calls
    final poppinsStyle = GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );

    final playfairStyle = GoogleFonts.playfairDisplaySc(
      fontSize: 20.sp,
      fontWeight: FontWeight.w700,
    );

    return AnimatedBuilder(
      animation: _bottomSheetController,
      builder: (context, child) {
        final animationValue = _bottomSheetController.value;

        return Column(
          children: [
            // LOGIN Button
            _buildOptimizedStaggeredItem(
              delay: 0.1,
              animationValue: animationValue,
              child: SizedBox(
                width: 130.w,
                height: 55.h,
                child: CustomElevatedButton(
                  borderRadius: 25.r,
                  text: 'LOGIN',
                  backgroundColor: appColors.darkBlue,
                  isLoading: false,
                  onTap: () => Get.to(() => const SignInView()),
                ),
              ),
            ),

            // OR Text
            _buildOptimizedStaggeredItem(
              delay: 0.25,
              animationValue: animationValue,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('OR', style: poppinsStyle),
              ),
            ),

            // JOIN Button
            _buildOptimizedStaggeredItem(
              delay: 0.4,
              animationValue: animationValue,
              child: SizedBox(
                width: 130.w,
                height: 55.h,
                child: CustomElevatedButton(
                  borderRadius: 25.r,
                  text: 'JOIN',
                  textColor: appColors.black,
                  backgroundColor: appColors.white,
                  isLoading: false,
                  onTap: () => Get.to(() => const SignUpView()),
                ),
              ),
            ),

            // AND Text
            _buildOptimizedStaggeredItem(
              delay: 0.55,
              animationValue: animationValue,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('AND', style: poppinsStyle),
              ),
            ),

            // BE A PART OF Text
            _buildOptimizedStaggeredItem(
              delay: 0.7,
              animationValue: animationValue,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('BE A PART OF', style: poppinsStyle),
              ),
            ),

            // WHERE THE WEST CONTINUES Text
            _buildOptimizedStaggeredItem(
              delay: 0.85,
              animationValue: animationValue,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  '...WHERE THE WEST CONTINUES...',
                  textAlign: TextAlign.center,
                  style: playfairStyle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptimizedStaggeredItem({
    required double delay,
    required double animationValue,
    required Widget child,
  }) {
    // Calculate staggered animation progress
    double progress = ((animationValue - delay) / 0.3).clamp(0.0, 1.0);

    if (progress <= 0) return const SizedBox.shrink();

    // Use Curves.easeOut for smoother staggered animation
    final curvedProgress = Curves.easeOut.transform(progress);

    return Transform.translate(
      offset: Offset(0, 15 * (1 - curvedProgress)),
      child: Opacity(opacity: curvedProgress, child: child),
    );
  }
}
