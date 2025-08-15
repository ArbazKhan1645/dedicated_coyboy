// views/sign_in/controller/sign_in_controller.dart
import 'package:dedicated_cowboy/app/models/user_model.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/utils/exceptions.dart';
import 'package:dedicated_cowboy/bottombar/bottom_bar_widegt.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInController extends GetxController {
  // Form controllers
  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;
  final forgotPasswordEmailController = TextEditingController();
  
  // Form key for validation
  final formKey = GlobalKey<FormState>();
  
  // Observable states
  final showPassword = false.obs;
  final rememberMe = false.obs;
  final isLoading = false.obs;
  final isForgotPasswordLoading = false.obs;
  
  // Services
  late final AuthService _authService;
  
  @override
  void onInit() {
    super.onInit();
    _authService = AuthService();
    _loadRememberMeState();
  }

  @override
  void onClose() {
    emailController.value.dispose();
    passwordController.value.dispose();
    forgotPasswordEmailController.dispose();
    super.onClose();
  }

  // Load remember me state from SharedPreferences
  Future<void> _loadRememberMeState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      rememberMe.value = prefs.getBool('remember_me') ?? false;
      
      if (rememberMe.value) {
        final savedEmail = prefs.getString('saved_email');
        if (savedEmail != null) {
          emailController.value.text = savedEmail;
        }
      }
    } catch (e) {
      debugPrint('Error loading remember me state: $e');
    }
  }

  // Save remember me state to SharedPreferences
  Future<void> _saveRememberMeState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe.value);
      
      if (rememberMe.value) {
        await prefs.setString('saved_email', emailController.value.text.trim());
      } else {
        await prefs.remove('saved_email');
      }
    } catch (e) {
      debugPrint('Error saving remember me state: $e');
    }
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  // Toggle remember me checkbox
  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  // Validate form inputs
  String? validateEmail(String? email) {
    return AuthValidator.validateEmail(email);
  }

  String? validatePassword(String? password) {
    return AuthValidator.validatePassword(password);
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword() async {
    // Validate form
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      final email = emailController.value.text.trim();
      final password = passwordController.value.text;

      // Sign in using auth service
      final UserModel user = await _authService.signIn(
        email: email,
        password: password,
      );

      // Save remember me state
      await _saveRememberMeState();

      // Mark onboarding as seen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);

      // Show success message
      Get.snackbar(
        'Success',
        'Welcome back, ${user.displayName ?? user.email}!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0xffF3B340),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Navigate to main app
      Get.offAll(() => CustomCurvedNavBar());

    } on AuthException catch (e) {
      _handleAuthException(e);
    } catch (e) {
      _handleGenericError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Show forgot password dialog
  void showForgotPasswordDialog() {
    // Pre-fill with current email if available
    if (emailController.value.text.trim().isNotEmpty) {
      forgotPasswordEmailController.text = emailController.value.text.trim();
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: forgotPasswordEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              validator: validateEmail,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              forgotPasswordEmailController.clear();
              Get.back();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: isForgotPasswordLoading.value 
                ? null 
                : sendPasswordResetEmail,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isForgotPasswordLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Send Reset Link'),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail() async {
    final email = forgotPasswordEmailController.text.trim();
    
    // Validate email
    final emailError = validateEmail(email);
    if (emailError != null) {
      Get.snackbar(
        'Invalid Email',
        emailError,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    try {
      isForgotPasswordLoading.value = true;

      await _authService.sendPasswordResetEmail(email);

      // Close dialog
      Get.back();
      
      // Clear controller
      forgotPasswordEmailController.clear();

      // Show success message
      Get.snackbar(
        'Email Sent',
        'Password reset link has been sent to $email. Please check your inbox.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0xffF3B340),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.mark_email_read, color: Colors.white),
      );

    } on AuthException catch (e) {
      _handleAuthException(e);
    } catch (e) {
      _handleGenericError(e);
    } finally {
      isForgotPasswordLoading.value = false;
    }
  }

  // Handle authentication exceptions
  void _handleAuthException(AuthException e) {
    String message = e.message;
    
    // Customize messages based on error codes
    switch (e.code) {
      case 'user-not-found':
        message = 'No account found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Please contact support.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your internet connection.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      default:
        message = e.message;
    }

    Get.snackbar(
      'Sign In Failed',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  // Handle generic errors
  void _handleGenericError(dynamic error) {
    debugPrint('Sign in error: $error');
    
    Get.snackbar(
      'Error',
      'An unexpected error occurred. Please try again.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  // Clear all form data
  void clearForm() {
    emailController.value.clear();
    passwordController.value.clear();
    showPassword.value = false;
    rememberMe.value = false;
  }
}