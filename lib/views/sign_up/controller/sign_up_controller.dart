// views/sign_up/controller/sign_up_controller.dart
import 'package:dedicated_cowboy/views/mails/mail_structure.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/utils/exceptions.dart';
import 'package:dedicated_cowboy/bottombar/bottom_bar_widegt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/models/user_model.dart';

class SignUpController extends GetxController {
  // Form controllers
  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;
  final firstNameController = TextEditingController().obs;
  final lastNameController = TextEditingController().obs;
  final phoneController = TextEditingController().obs;
  final confirmPasswordController = TextEditingController().obs;
  final facebookPageIdController = TextEditingController().obs;

  // Form key for validation
  final formKey = GlobalKey<FormState>();

  // Loading and UI states
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final rememberMe = false.obs;

  // Auth service and Firestore
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Error messages
  final emailError = ''.obs;
  final passwordError = ''.obs;
  final firstNameError = ''.obs;
  final lastNameError = ''.obs;
  final phoneError = ''.obs;
  final confirmPasswordError = ''.obs;
  final facebookPageIdError = ''.obs;
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
    facebookPageIdController.value.dispose();
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
    facebookPageIdError.value = '';
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

    // Facebook Page ID validation (optional)
    final facebookPageIdValidation = _validateFacebookPageId(
      facebookPageIdController.value.text,
    );
    if (facebookPageIdValidation != null) {
      facebookPageIdError.value = facebookPageIdValidation;
      firstError ??= facebookPageIdValidation;
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
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'First name can only contain letters, spaces, hyphens, and apostrophes';
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
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'Last name can only contain letters, spaces, hyphens, and apostrophes';
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
      return 'Please enter a valid phone number with at least 10 digits';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number is too long (maximum 15 digits)';
    }

    return null;
  }

  String? _validateFacebookPageId(String? value) {
    // Facebook Page ID is optional
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    // Basic validation for Facebook Page ID
    if (value.trim().length < 3) {
      return 'Facebook Page ID must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Facebook Page ID must be less than 50 characters';
    }

    return null;
  }

  // Create comprehensive user document in Firestore
  Future<void> _createUserDocument(UserModel user) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': emailController.value.text.trim(),
        'displayName':
            '${firstNameController.value.text.trim()} ${lastNameController.value.text.trim()}',
        'firstName': firstNameController.value.text.trim(),
        'lastName': lastNameController.value.text.trim(),
        'phoneNumber': phoneController.value.text.trim(),
        'facebookPageId': facebookPageIdController.value.text.trim(),
        'photoURL': user.photoURL ?? '',
        'emailVerified': user.emailVerified,
        'signInMethod': 'email',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isProfileComplete': true,
        'accountStatus': 'active',
      };

      await _firestore.collection('users').doc(user.uid).set(userData);

      debugPrint('User document created successfully for ${user.uid}');
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
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

      final email = emailController.value.text.trim();
      final password = passwordController.value.text;
      final displayName =
          '${firstNameController.value.text.trim()} ${lastNameController.value.text.trim()}';

      // Attempt to sign up
      final user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Create comprehensive user document in Firestore
      await _createUserDocument(user);

      // Update user profile with display name
      await _authService.updateProfile(displayName: displayName);

      await EmailTemplates.sendRegistrationWelcomeEmail(
        recipientEmail: emailController.value.text.trim(),
        recipientName: displayName,
        loginUrl: 'https://dedicatedcowboy.com/login', // Optional
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
      case 'network-request-failed':
        _showError(
          'Network error. Please check your internet connection and try again.',
        );
        break;
      case 'too-many-requests':
        _showError('Too many attempts. Please try again later.');
        break;
      case 'operation-not-allowed':
        _showError(
          'Email/password accounts are not enabled. Please contact support.',
        );
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
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
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
      final emailValidation = AuthValidator.validateEmail(email);
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
    firstNameController.value.clear();
    lastNameController.value.clear();
    phoneController.value.clear();
    confirmPasswordController.value.clear();
    facebookPageIdController.value.clear();
    clearErrors();
  }
}
