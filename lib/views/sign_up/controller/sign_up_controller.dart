import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/utils/exceptions.dart';
import 'package:dedicated_cowboy/bottombar/bottom_bar_widegt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpController extends GetxController {
  // Form controllers
  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;
  final firstNameController = TextEditingController().obs;
  final lastNameController = TextEditingController().obs;
  final phoneController = TextEditingController().obs;
  final confirmPasswordController = TextEditingController().obs;

  // Form key for validation
  final formKey = GlobalKey<FormState>();

  // Loading and UI states
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final rememberMe = false.obs;

  // Auth service
  final AuthService _authService = AuthService();

  // Error messages
  final emailError = ''.obs;
  final passwordError = ''.obs;
  final firstNameError = ''.obs;
  final lastNameError = ''.obs;
  final phoneError = ''.obs;
  final confirmPasswordError = ''.obs;
  final generalError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeAuthService();
  }

  @override
  void onClose() {
    // Dispose controllers
    emailController.value.dispose();
    passwordController.value.dispose();
    firstNameController.value.dispose();
    lastNameController.value.dispose();
    phoneController.value.dispose();
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

  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
  }

  // Clear all errors
  void clearErrors() {
    emailError.value = '';
    passwordError.value = '';
    firstNameError.value = '';
    lastNameError.value = '';
    phoneError.value = '';
    confirmPasswordError.value = '';
    generalError.value = '';
  }

  // Validate individual fields
  String? _validateFields() {
    clearErrors();

    String? firstError;

    final firstNameValidation = _validateFirstName(
      firstNameController.value.text,
    );
    if (firstNameValidation != null) {
      firstNameError.value = firstNameValidation;
      firstError ??= firstNameValidation;
    }

    final lastNameValidation = _validateLastName(lastNameController.value.text);
    if (lastNameValidation != null) {
      lastNameError.value = lastNameValidation;
      firstError ??= lastNameValidation;
    }

    final emailValidation = AuthValidator.validateEmail(
      emailController.value.text,
    );
    if (emailValidation != null) {
      emailError.value = emailValidation;
      firstError ??= emailValidation;
    }

    final phoneValidation = _validatePhone(phoneController.value.text);
    if (phoneValidation != null) {
      phoneError.value = phoneValidation;
      firstError ??= phoneValidation;
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

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }
    if (value.trim().length < 2) {
      return 'First name must be at least 2 characters';
    }
    if (value.trim().length > 30) {
      return 'First name must be less than 30 characters';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }
    if (value.trim().length < 2) {
      return 'Last name must be at least 2 characters';
    }
    if (value.trim().length > 30) {
      return 'Last name must be less than 30 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number is too long';
    }

    return null;
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

      // Start loading
      isLoading.value = true;

      // Create display name from first and last name
      final displayName =
          '${firstNameController.value.text.trim()} ${lastNameController.value.text.trim()}';

      // Attempt to sign up
      await _authService.signUp(
        email: emailController.value.text.trim(),
        password: passwordController.value.text,
        displayName: displayName,
      );

      // Set onboarding as seen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);

      // Show success message
      Get.snackbar(
        'Success',
        'Account created successfully! Welcome to Dedicated Cowboy!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 3),
      );

      // Navigate to main app
      Get.offAll(() => CustomCurvedNavBar());
    } on AuthException catch (e) {
      _handleAuthException(e);
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void _handleAuthException(AuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        emailError.value = 'This email is already registered';
        _showError('An account with this email already exists');
        break;
      case 'invalid-email':
        emailError.value = 'Please enter a valid email address';
        break;
      case 'weak-password':
        passwordError.value =
            'Password is too weak. Please choose a stronger password';
        break;
      case 'password-too-short':
        passwordError.value = e.message;
        break;
      case 'network-request-failed':
        _showError('Network error. Please check your internet connection');
        break;
      case 'too-many-requests':
        _showError('Too many attempts. Please try again later');
        break;
      default:
        _showError(e.message);
        break;
    }
  }

  void _showError(String message) {
    generalError.value = message;
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 4),
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
      final emailValidation = AuthValidator.validateEmail(email);
      if (emailValidation != null) {
        Get.snackbar('Error', emailValidation);
        return;
      }

      isLoading.value = true;

      await _authService.sendPasswordResetEmail(email.trim());

      Get.back(); // Close dialog

      Get.snackbar(
        'Success',
        'Password reset link sent to $email',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 4),
      );
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message);
    } catch (e) {
      Get.snackbar('Error', 'Failed to send reset email. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // Clear form
  void clearForm() {
    emailController.value.clear();
    passwordController.value.clear();
    firstNameController.value.clear();
    lastNameController.value.clear();
    phoneController.value.clear();
    confirmPasswordController.value.clear();
    clearErrors();
  }
}
