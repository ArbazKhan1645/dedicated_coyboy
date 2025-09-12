// views/sign_in/controller/sign_in_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/models/user_model.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/services/socail.dart';
import 'package:dedicated_cowboy/app/utils/exceptions.dart';
import 'package:dedicated_cowboy/bottombar/bottom_bar_widegt.dart';
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final isGoogleLoading = false.obs;
  final isFacebookLoading = false.obs;

  // Services
  late final AuthService _authService;
  final SocialService _authServiceSocial = SocialService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Check if user exists in Firestore and has complete profile
  Future<Map<String, dynamic>> _checkUserInFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        return {'exists': false, 'isComplete': false, 'data': null};
      }

      final userData = doc.data()!;

      // Check for required fields
      final bool isComplete =
          userData.containsKey('email') &&
          userData.containsKey('displayName') &&
          userData['email'] != null &&
          userData['displayName'] != null &&
          userData['email'].toString().isNotEmpty &&
          userData['displayName'].toString().isNotEmpty;

      return {'exists': true, 'isComplete': isComplete, 'data': userData};
    } catch (e) {
      debugPrint('Error checking user in Firestore: $e');
      return {'exists': false, 'isComplete': false, 'data': null};
    }
  }

  // Create or update user document in Firestore
  Future<void> _createOrUpdateUserDocument(
    UserModel user, {
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? facebookPageId,
  }) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'emailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'firstName': firstName ?? _extractFirstName(user.displayName),
        'lastName': lastName ?? _extractLastName(user.displayName),
        'phoneNumber': phoneNumber ?? '',
        'facebookPageId': facebookPageId ?? '',
        'signInMethod': 'email', // Will be updated for social sign-ins
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error creating/updating user document: $e');
      rethrow;
    }
  }

  String _extractFirstName(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '';
    final parts = displayName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  String _extractLastName(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '';
    final parts = displayName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  // Show dialog to collect missing information
  Future<Map<String, String>?> _showMissingInfoDialog({
    String? currentDisplayName,
    String? currentEmail,
  }) async {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final facebookPageIdController = TextEditingController();

    // Pre-fill if display name exists
    if (currentDisplayName != null && currentDisplayName.isNotEmpty) {
      firstNameController.text = _extractFirstName(currentDisplayName);
      lastNameController.text = _extractLastName(currentDisplayName);
    }

    return await Get.dialog<Map<String, String>>(
      AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Complete Your Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please provide the following information to complete your account setup:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: facebookPageIdController,
                decoration: const InputDecoration(
                  labelText: 'Facebook Page ID (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (firstNameController.text.trim().isEmpty ||
                  lastNameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please fill in all required fields',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              Get.back(
                result: {
                  'firstName': firstNameController.text.trim(),
                  'lastName': lastNameController.text.trim(),
                  'phoneNumber': phoneController.text.trim(),
                  'facebookPageId': facebookPageIdController.text.trim(),
                },
              );
            },
            child: const Text('Complete'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword() async {
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

      // Check if user exists in Firestore
      final userCheck = await _checkUserInFirestore(user.uid);

      if (!userCheck['exists']) {
        // User doesn't exist in Firestore - sign them out and show error
        await _authService.signOut();

        Get.snackbar(
          'Account Not Found',
          'Your account was not found in our database. Please contact support or sign up again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.error, color: Colors.white),
        );
        return;
      }

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
        backgroundColor: Color(0xFFF2B342),
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

  // Google Sign In with improved loading and validation
  Future<void> handleGoogleSignIn() async {
    if (isGoogleLoading.value || isLoading.value) return;

    try {
      isGoogleLoading.value = true;

      UserCredential? result = await _authServiceSocial.signInWithGoogle();

      if (result != null && result.user != null) {
        final user = UserModel.fromFirebaseUser(result.user!);

        // Check user in Firestore
        final userCheck = await _checkUserInFirestore(user.uid);

        if (!userCheck['exists'] || !userCheck['isComplete']) {
          // Get missing information
          final missingInfo = await _showMissingInfoDialog(
            currentDisplayName: user.displayName,
            currentEmail: user.email,
          );

          if (missingInfo == null) {
            // User cancelled, sign them out
            await _authService.signOut();
            return;
          }

          // Create/update user document with complete information
          await _createOrUpdateUserDocument(
            user,
            firstName: missingInfo['firstName'],
            lastName: missingInfo['lastName'],
            phoneNumber: missingInfo['phoneNumber'],
            facebookPageId: missingInfo['facebookPageId'],
          );

          // Update sign-in method
          await _firestore.collection('users').doc(user.uid).update({
            'signInMethod': 'google',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        Get.snackbar(
          'Success',
          'Welcome back, ${result.user!.displayName ?? 'User'}!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );

        Get.offAll(() => CustomCurvedNavBar());
      }
    } catch (e) {
      _handleGenericError(e);
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // Facebook Sign In with improved loading and validation
  Future<void> handleFacebookSignIn() async {
    if (isFacebookLoading.value || isLoading.value) return;

    try {
      isFacebookLoading.value = true;

      final result = await _authServiceSocial.signInWithFacebook();

      if (result != null && result.user != null) {
        final user = UserModel.fromFirebaseUser(result.user!);

        // Check user in Firestore
        final userCheck = await _checkUserInFirestore(user.uid);

        if (!userCheck['exists'] || !userCheck['isComplete']) {
          // Get missing information
          final missingInfo = await _showMissingInfoDialog(
            currentDisplayName: user.displayName,
            currentEmail: user.email,
          );

          if (missingInfo == null) {
            // User cancelled, sign them out
            await _authService.signOut();
            return;
          }

          // Create/update user document with complete information
          await _createOrUpdateUserDocument(
            user,
            firstName: missingInfo['firstName'],
            lastName: missingInfo['lastName'],
            phoneNumber: missingInfo['phoneNumber'],
            facebookPageId: missingInfo['facebookPageId'],
          );

          // Update sign-in method
          await _firestore.collection('users').doc(user.uid).update({
            'signInMethod': 'facebook',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        Get.snackbar(
          'Success',
          'Welcome back, ${result.user!.displayName ?? 'User'}!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );

        Get.offAll(() => CustomCurvedNavBar());
      }
    } catch (e) {
      _handleGenericError(e);
    } finally {
      isFacebookLoading.value = false;
    }
  }

  // Show forgot password dialog
  void showForgotPasswordDialog() {
    // Pre-fill with current email if available
    if (emailController.value.text.trim().isNotEmpty) {
      forgotPasswordEmailController.text = emailController.value.text.trim();
    }

    Get.dialog(
      Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 24,
                      right: 16,
                    ),
                    child: Row(
                      children: [
                        // Lock icon
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title
                        const Expanded(
                          child: Text(
                            'Forget Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // Close button
                        GestureDetector(
                          onTap: () {
                            forgotPasswordEmailController.clear();
                            Get.back();
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8A317),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Description text
                        const Text(
                          'Please enter your email or phone number to recover or set your password.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Email or Phone label
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Input field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: forgotPasswordEmailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade400,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F8F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8A317),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: validateEmail,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Send button
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 55.h,
                            child: CustomElevatedButton(
                              borderRadius: 25.r,
                              text: 'Send',
                              backgroundColor: appColors.pYellow,
                              isLoading: isForgotPasswordLoading.value,
                              onTap:
                                  isForgotPasswordLoading.value
                                      ? null
                                      : sendPasswordResetEmail,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
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
        backgroundColor: Color(0xFFF2B342),
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
      backgroundColor: Color(0xFFF2B342),
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
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
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
