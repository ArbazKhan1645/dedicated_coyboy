// views/sign_up/controller/sign_up_controller.dart
import 'package:dedicated_cowboy/views/mails/mail_structure.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/utils/exceptions.dart';
import 'package:dedicated_cowboy/bottombar/bottom_bar_widegt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpController extends GetxController {
  // Form controllers
  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;
  final confirmPasswordController = TextEditingController().obs;
  final usernameController = TextEditingController().obs;
  final facebookpageIdController = TextEditingController().obs;

  // Form key for validation
  final formKey = GlobalKey<FormState>();

  // Loading and UI states
  final isLoading = false.obs;
  final agreePrivacy = false.obs;
  final agreeTerms = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  // Auth service
  late final AuthService _authService;

  // Error messages
  final emailError = ''.obs;
  final passwordError = ''.obs;
  final confirmPasswordError = ''.obs;
  final generalError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _initializeAuthService();
  }

  @override
  void onClose() {
    // Dispose controllers
    emailController.value.dispose();
    passwordController.value.dispose();
    confirmPasswordController.value.dispose();
    super.onClose();
  }

  Future<void> _initializeAuthService() async {
    try {
      await _authService.initialize();
    } catch (e) {
      _showError('Failed to initialize authentication service');
    }
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  // Clear all errors
  void clearErrors() {
    emailError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
    generalError.value = '';
  }

  // Validate individual fields
  String? _validateFields() {
    clearErrors();

    String? firstError;
    final usernameValidation = AuthValidator.validateUsernameOrEmail(
      usernameController.value.text,
      false,
    );
    if (usernameValidation != null) {
      firstError ??= usernameValidation;
    }

    final emailValidation = AuthValidator.validateUsernameOrEmail(
      emailController.value.text,
      true,
    );
    if (emailValidation != null) {
      emailError.value = emailValidation;
      firstError ??= emailValidation;
    }

    final passwordValidation = AuthValidator.validatePassword(
      passwordController.value.text,
    );
    if (passwordValidation != null) {
      passwordError.value = passwordValidation;
      firstError ??= passwordValidation;
    }

    final confirmPasswordValidation = AuthValidator.validateConfirmPassword(
      passwordController.value.text,
      confirmPasswordController.value.text,
    );
    if (confirmPasswordValidation != null) {
      confirmPasswordError.value = confirmPasswordValidation;
      firstError ??= confirmPasswordValidation;
    }

    return firstError;
  }

  // Main sign up function
  Future<void> signUp() async {
    try {
      // Clear previous errors
      clearErrors();

      // Validate form
      final validationError = _validateFields();
      if (validationError != null) {
        _showError(validationError);
        return;
      }

      if (agreePrivacy.value == false || agreeTerms.value == false) {
        _showError('Please accept our terms and conditions.');
        return;
      }

      // Start loading
      isLoading.value = true;

      final email = emailController.value.text.trim();
      final password = passwordController.value.text;

      // Attempt to sign up
      final user = await _authService.signUp(
        email: email,
        password: password,
        displayName: usernameController.value.text,
        facebookPageId: facebookpageIdController.value.text,
      );

      // Set onboarding as seen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);

      // Show success message
      Get.snackbar(
        'Success',
        'Account created successfully! Welcome to Dedicated Cowboy!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Navigate to main app
      Get.offAll(() => CustomCurvedNavBar());
      try {
        await EmailTemplates.sendRegistrationWelcomeEmail(
          recipientEmail: email,
          recipientName: 'User',
        );
      } catch (e) {
        print(e);
      }
    } on AuthException catch (e) {
      _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign up error: $e');
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void _handleAuthException(AuthException e) {
    switch (e.code) {
      case 'email-already-exists':
      case 'email-already-in-use':
        emailError.value = 'This email is already registered';
        _showError(
          'An account with this email already exists. Please use a different email or try signing in.',
        );
        break;
      case 'invalid-email':
        emailError.value = 'Please enter a valid email address';
        _showError('The email address format is invalid.');
        break;
      case 'weak-password':
        passwordError.value =
            'Password is too weak. Please choose a stronger password';
        _showError(
          'Your password is too weak. Please use a stronger password with at least 6 characters.',
        );
        break;
      case 'password-too-short':
        passwordError.value = e.message;
        _showError(e.message);
        break;
      case 'network-error':
        _showError(
          'Network error. Please check your internet connection and try again.',
        );
        break;
      case 'too-many-requests':
        _showError('Too many attempts. Please try again later.');
        break;
      case 'server-error':
        _showError('Server error. Please try again later.');
        break;
      case 'validation-error':
        _showError(e.message);
        break;
      default:
        _showError(
          e.message.isNotEmpty
              ? e.message
              : 'An authentication error occurred. Please try again.',
        );
        break;
    }
  }

  void _showError(String message) {
    generalError.value = message;
    Get.snackbar(
      'Validation',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.black,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  // Show forgot password dialog
  void showForgotPasswordDialog() {
    final forgotPasswordController = TextEditingController();
    final isResettingPassword = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: forgotPasswordController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(
            () => ElevatedButton(
              onPressed:
                  isResettingPassword.value
                      ? null
                      : () => _sendPasswordResetEmail(
                        forgotPasswordController.text,
                        isResettingPassword,
                      ),
              child:
                  isResettingPassword.value
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Send Reset Link'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordResetEmail(String email, RxBool isLoading) async {
    try {
      // Validate email
      final emailValidation = AuthValidator.validateUsernameOrEmail(
        email,
        true,
      );
      if (emailValidation != null) {
        Get.snackbar(
          'Error',
          emailValidation,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      isLoading.value = true;

      await _authService.sendPasswordResetEmail(email.trim());

      Get.back(); // Close dialog

      Get.snackbar(
        'Success',
        'Password reset link sent to $email',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } on AuthException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send reset email. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Clear form
  void clearForm() {
    emailController.value.clear();
    passwordController.value.clear();
    confirmPasswordController.value.clear();
    clearErrors();
  }
}
