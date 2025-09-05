// views/sign_in/sign_in_view.dart

import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';

import 'package:dedicated_cowboy/views/sign_in/controller/sign_in_controller.dart';

import 'package:dedicated_cowboy/views/sign_in/widgets/divider_with_text_widget.dart';
import 'package:dedicated_cowboy/views/sign_up/sign_up_view.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';

import 'package:dedicated_cowboy/widgets/textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView>
    with SingleTickerProviderStateMixin {
  late final SignInController controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controller
    controller = Get.put(SignInController());

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors.pYellow,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: appColors.transparent,
        automaticallyImplyLeading: true,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: GestureDetector(
              onTap: () {
                Get.off(() => SignUpView());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'JOIN',
                  style: Appthemes.textSmall.copyWith(
                    fontFamily: 'popins-bold',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildBody(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Login Title with Hero Animation
          Hero(
            tag: 'login_title',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(
                'LOGIN',
                style: Appthemes.textLarge.copyWith(
                  fontFamily: 'popins-bold',
                  fontWeight: FontWeight.bold,
                  fontSize: 32.sp,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Main Content Container
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            decoration: BoxDecoration(
              color: appColors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // Email Field
          Obx(
            () => CustomTextField(
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              controller: controller.emailController.value,
              keyboardType: TextInputType.emailAddress,
              // textInputAction: TextInputAction.next,
              prefixIcon: Icon(Icons.email_outlined),
              validator: controller.validateEmail,
              onChanged: (value) {
                // Real-time validation can be added here
              },
            ),
          ),

          const SizedBox(height: 20),

          // Password Field
          Obx(
            () => CustomTextField(
              labelText: 'Password',
              hintText: 'Enter your password',
              controller: controller.passwordController.value,
              keyboardType: TextInputType.visiblePassword,
              // textInputAction: TextInputAction.done,
              isPassword: !controller.showPassword.value,
              prefixIcon: Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.showPassword.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
              validator: controller.validatePassword,
              // onFieldSubmitted: (_) => controller.signInWithEmailAndPassword(),
            ),
          ),

          const SizedBox(height: 15),

          // Remember Me and Forgot Password Row
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Remember Me Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: controller.rememberMe.value,
                      onChanged: controller.toggleRememberMe,
                      activeColor: appColors.pYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Text(
                      'Remember me',
                      style: Appthemes.textSmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                // Forgot Password Button
                TextButton(
                  onPressed: controller.showForgotPasswordDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: Appthemes.textSmall.copyWith(
                      color: appColors.darkBlue,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Login Button
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 55.h,
              child: CustomElevatedButton(
                borderRadius: 25.r,
                text: controller.isLoading.value ? '' : 'LOGIN',
                backgroundColor: appColors.pYellow,
                isLoading: controller.isLoading.value,
                onTap:
                    controller.isLoading.value
                        ? null
                        : controller.signInWithEmailAndPassword,
         
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Divider with Text
          TextWithDividers(
            text: 'or login with',
            dividerColor: appColors.black.withOpacity(0.3),
            dividerThickness: 1.0,
            textStyle: Appthemes.textMedium.copyWith(color: Colors.grey[600]),
          ),

          const SizedBox(height: 25),

          // Social Login Buttons
          Row(
            children: [
              // Google Login Button
              Expanded(
                child: SizedBox(
                  height: 55.h,
                  child: CustomElevatedButton(
                    imageAsset:
                        'assets/images/e7e19efc3d82bb411c1f92df035c4f0b8dfcf272.png',
                    borderRadius: 25.r,
                    text: 'Google',
                    backgroundColor: appColors.white,
                    textColor: appColors.black,

                    isLoading: false,
                    onTap: () {
                      controller.handleGoogleSignIn();
                      // TODO: Implement Google Sign In
                      // Get.snackbar(
                      //   'Coming Soon',
                      //   'Google sign-in will be available soon',
                      //   snackPosition: SnackPosition.TOP,
                      //   backgroundColor: Colors.blue,
                      //   colorText: Colors.white,
                      // );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 15),

              // Facebook Login Button
              Expanded(
                child: SizedBox(
                  height: 55.h,
                  child: CustomElevatedButton(
                    imageAsset: 'assets/images/Google__G__logo.svg 1.png',
                    borderRadius: 25.r,
                    text: 'Facebook',
                    backgroundColor: appColors.darkBlue,
                    textColor: appColors.white,
                    isLoading: false,
                    onTap: () {
                      controller.handleFacebookSignIn();
                      // TODO: Implement Facebook Sign In
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Sign Up Link
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text(
                  'Don\'t have an account? ',
                  style: Appthemes.textSmall.copyWith(color: Colors.grey[600]),
                ),
                GestureDetector(
                  onTap: () {
                    Get.off(() => SignUpView());
                  },
                  child: Text(
                    'Sign Up',
                    style: Appthemes.textSmall.copyWith(
                      color: appColors.pYellow,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
