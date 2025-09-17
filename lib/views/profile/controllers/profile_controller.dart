// profile/controller/profile_controller.dart

import 'package:dedicated_cowboy/app/models/api_user_model.dart';

import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/utils/api_client.dart';
import 'package:dedicated_cowboy/app/utils/exceptions.dart';
import 'package:dedicated_cowboy/views/chats/rooms.dart';
import 'package:dedicated_cowboy/views/my_listings/my_listings.dart';
import 'package:dedicated_cowboy/views/notifications/notifications.dart';
import 'package:dedicated_cowboy/views/profile/views/edit.dart';
import 'package:dedicated_cowboy/views/sign_in/sign_in_view.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  // Auth service instance
  late final AuthService _authService;

  // Observable user data
  final Rx<ApiUserModel?> currentUser = Rx<ApiUserModel?>(null);

  // Basic Info - extracted from API response
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userAvatar = ''.obs;
  final RxString displayName = ''.obs;
  final RxString firstName = ''.obs;
  final RxString lastName = ''.obs;
  final RxString website = ''.obs;
  final RxString address = ''.obs;
  final RxString about = ''.obs;

  // Social Media - from meta fields
  final RxString facebookUrl = ''.obs;
  final RxString instagramUrl = ''.obs;
  final RxString linkedinUrl = ''.obs;
  final RxString youtubeUrl = ''.obs;

  // Subscription info
  final RxString subscriptionPlan = 'free'.obs;
  final RxBool isActiveSubscription = false.obs;
  final RxString stripeCustomerId = ''.obs;

  // Additional fields from meta
  final RxString billingFirstName = ''.obs;
  final RxString billingLastName = ''.obs;
  final RxString billingEmail = ''.obs;
  final RxString billingPhone = ''.obs;
  final RxString billingAddress = ''.obs;
  final RxString billingCity = ''.obs;
  final RxString billingPostcode = ''.obs;
  final RxString billingCountry = ''.obs;
  final RxString billingState = ''.obs;

  // Form controllers
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Social Media Controllers
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController youtubeController = TextEditingController();

  // Billing Controllers
  final TextEditingController billingFirstNameController =
      TextEditingController();
  final TextEditingController billingLastNameController =
      TextEditingController();
  final TextEditingController billingEmailController = TextEditingController();
  final TextEditingController billingPhoneController = TextEditingController();
  final TextEditingController billingAddressController =
      TextEditingController();
  final TextEditingController billingCityController = TextEditingController();
  final TextEditingController billingPostcodeController =
      TextEditingController();
  final TextEditingController billingCountryController =
      TextEditingController();
  final TextEditingController billingStateController = TextEditingController();

  // UI state
  final RxBool isEditing = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingProfile = true.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _initializeUserData();

    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _updateUserData(user);
      } else {
        _clearUserData();
      }
    });
  }

  @override
  void onClose() {
    // _disposeControllers();
    super.onClose();
  }

  void _disposeControllers() {
    displayNameController.dispose();
    userNameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    descriptionController.dispose();
    facebookController.dispose();
    instagramController.dispose();
    linkedinController.dispose();
    youtubeController.dispose();
    billingFirstNameController.dispose();
    billingLastNameController.dispose();
    billingEmailController.dispose();
    billingPhoneController.dispose();
    billingAddressController.dispose();
    billingCityController.dispose();
    billingPostcodeController.dispose();
    billingCountryController.dispose();
    billingStateController.dispose();
  }

  // Initialize user data
  void _initializeUserData() async {
    try {
      await loadUserProfile();
    } catch (e) {
      debugPrint('Error initializing user data: $e');
    }
  }

  // Load user profile from API
  Future<void> loadUserProfile() async {
    try {
      isLoadingProfile.value = true;

      // Get current user from auth service
      final user = _authService.currentUser;
      if (user != null) {
        _updateUserData(user);
      } else {
        // Refresh user data from API
        await _authService.refreshUser();
        final refreshedUser = _authService.currentUser;
        if (refreshedUser != null) {
          _updateUserData(refreshedUser);
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _showError('Failed to load profile data');
    } finally {
      isLoadingProfile.value = false;
    }
  }

  // Update user data from ApiUserModel
  void _updateUserData(ApiUserModel user) {
    currentUser.value = user;
    _updateObservablesFromModel(user);
    _updateControllersFromModel(user);
  }

  // Update observables from ApiUserModel
  void _updateObservablesFromModel(ApiUserModel user) {
    displayName.value = user.displayName;
    userName.value = user.username;
    firstName.value = user.firstName;
    lastName.value = user.lastName;
    userEmail.value = user.email;
    userAvatar.value = user.photoURL;
    website.value = user.url;
    about.value = user.description;

    // Subscription info
    subscriptionPlan.value = user.subscriptionPlan;
    isActiveSubscription.value = user.isActiveSubscription;
    stripeCustomerId.value = user.stripeCustomerId ?? '';

    // Extract meta data
    if (user.meta != null) {
      final meta = user.meta!;

      // Social media from meta
      facebookUrl.value = _getMetaValue(meta, 'facebook') ?? '';
      instagramUrl.value = _getMetaValue(meta, 'instagram') ?? '';
      linkedinUrl.value = _getMetaValue(meta, 'linkedin') ?? '';
      youtubeUrl.value = _getMetaValue(meta, 'youtube') ?? '';

      // Billing info from meta
      billingFirstName.value = _getMetaValue(meta, 'billing_first_name') ?? '';
      billingLastName.value = _getMetaValue(meta, 'billing_last_name') ?? '';
      billingEmail.value = _getMetaValue(meta, 'billing_email') ?? '';
      billingPhone.value = _getMetaValue(meta, 'billing_phone') ?? '';
      billingAddress.value = _getMetaValue(meta, 'billing_address_1') ?? '';
      billingCity.value = _getMetaValue(meta, 'billing_city') ?? '';
      billingPostcode.value = _getMetaValue(meta, 'billing_postcode') ?? '';
      billingCountry.value = _getMetaValue(meta, 'billing_country') ?? '';
      billingState.value = _getMetaValue(meta, 'billing_state') ?? '';
    }
  }

  // Helper to get meta value (handles WordPress array format)
  String? _getMetaValue(Map<String, dynamic> meta, String key) {
    final value = meta[key];
    if (value is List && value.isNotEmpty) {
      return value.first?.toString();
    }
    return value?.toString();
  }

  // Update form controllers with current data
  void _updateControllersFromModel(ApiUserModel user) {
    displayNameController.text = user.displayName;
    userNameController.text = user.username;
    firstNameController.text = user.firstName;
    lastNameController.text = user.lastName;
    emailController.text = user.email;
    websiteController.text = user.url;
    descriptionController.text = user.description;

    // Update social media controllers
    facebookController.text = facebookUrl.value;
    instagramController.text = instagramUrl.value;
    linkedinController.text = linkedinUrl.value;
    youtubeController.text = youtubeUrl.value;

    // Update billing controllers
    billingFirstNameController.text = billingFirstName.value;
    billingLastNameController.text = billingLastName.value;
    billingEmailController.text = billingEmail.value;
    billingPhoneController.text = billingPhone.value;
    billingAddressController.text = billingAddress.value;
    billingCityController.text = billingCity.value;
    billingPostcodeController.text = billingPostcode.value;
    billingCountryController.text = billingCountry.value;
    billingStateController.text = billingState.value;
  }

  // Toggle edit mode
  void toggleEdit() {
    isEditing.value = !isEditing.value;
    if (isEditing.value) {
      // Navigate to edit screen
      Get.to(() => UserProfileEditScreen());
    }
    HapticFeedback.lightImpact();
  }

  // Change profile picture
  Future<void> changeProfilePicture() async {
    try {
      isUploadingImage.value = true;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        // Note: You'll need to implement your own image upload service
        // For now, this is a placeholder
        _showError(
          'Image upload not implemented yet. Please implement uploadMedia function.',
        );

        // Example of how it would work:
        // final String imageUrl = await uploadMedia([File(image.path)]);
        // await updateUserProfile({'avatar_url': imageUrl});
      }
    } catch (e) {
      debugPrint('Error changing profile picture: $e');
      _showError('Failed to update profile picture');
    } finally {
      isUploadingImage.value = false;
    }
  }

  // Save all profile changes
  Future<void> saveProfileChanges() async {
    try {
      isSaving.value = true;

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'name': displayNameController.text.trim(),
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'url': websiteController.text.trim(),
        'description': descriptionController.text.trim(),
      };

      // Prepare meta data updates
      final Map<String, dynamic> metaData = {
        'facebook': facebookController.text.trim(),
        'instagram': instagramController.text.trim(),
        'linkedin': linkedinController.text.trim(),
        'youtube': youtubeController.text.trim(),
        'billing_first_name': billingFirstNameController.text.trim(),
        'billing_last_name': billingLastNameController.text.trim(),
        'billing_email': billingEmailController.text.trim(),
        'billing_phone': billingPhoneController.text.trim(),
        'billing_address_1': billingAddressController.text.trim(),
        'billing_city': billingCityController.text.trim(),
        'billing_postcode': billingPostcodeController.text.trim(),
        'billing_country': billingCountryController.text.trim(),
        'billing_state': billingStateController.text.trim(),
      };

      // Add meta data to update data
      updateData['meta'] = metaData;

      // Update profile using auth service
      await _authService.updateProfile(
        name: updateData['name'],
        firstName: updateData['first_name'],
        lastName: updateData['last_name'],
        email: updateData['email'],
        url: updateData['url'],
        description: updateData['description'],
      );
      await _authService.updateUserProfileDetails(
        updateData: {"meta": metaData},
      );

      // If you need to update meta fields, you'll need to make a separate API call
      // as the standard WordPress REST API doesn't directly support meta updates
      // You might need to create a custom endpoint for meta updates

      // Reload user profile to get updated data
      await loadUserProfile();

      isEditing.value = false;

      _showSuccess('Profile updated successfully');
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (e is AuthException) {
        _showError(e.message);
      } else {
        _showError('Failed to update profile. Please try again.');
      }
    } finally {
      isSaving.value = false;
    }
  }

  // Update specific user profile field
  Future<void> updateUserProfile(Map<String, dynamic> updateData) async {
    try {
      final token = _authService.currentToken;
      if (token == null) {
        throw const AuthException(
          message: 'No authentication token found',
          code: 'no-token',
        );
      }

      final response = await ApiClient.updateUserProfile(
        token: token,
        updateData: updateData,
      );

      if (response.success && response.data != null) {
        _updateUserData(response.data!);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user favourites
  List<int> get favouriteListingIds {
    return currentUser.value?.favouriteListingIds ?? [];
  }

  // Check if listing is favourite
  bool isListingFavourite(int listingId) {
    return currentUser.value?.isListingFavourite(listingId) ?? false;
  }

  // Toggle favourite listing
  Future<void> toggleFavouriteListing(int listingId) async {
    try {
      final user = currentUser.value;
      if (user == null) return;

      // Update local state optimistically
      final updatedUser = user.toggleFavourite(listingId);
      currentUser.value = updatedUser;

      // Prepare meta update for API
      final metaUpdate = {
        'atbdp_favourites': updatedUser.meta?['atbdp_favourites'] ?? '',
      };

      // Update on server (you'll need to implement meta update endpoint)
      // await updateUserProfile({'meta': metaUpdate});

      _showSuccess(
        updatedUser.isListingFavourite(listingId)
            ? 'Added to favourites'
            : 'Removed from favourites',
      );
    } catch (e) {
      // Revert local state on error
      await loadUserProfile();
      _showError('Failed to update favourites');
    }
  }

  // Logout
  void logout() {
    _showLogoutDialog();
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: const EdgeInsets.all(30),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout,
                color: Color(0xFF3182CE),
                size: 24,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Are You Sure You Want To Logout',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Logging out will end your current session. You\'ll need to sign in again to access your account.',
              style: TextStyle(fontSize: 16, color: Color(0xFF718096)),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 25),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _performLogout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBB040),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF4A5568),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      await _authService.signOut();
      Get.delete<ChatRoomsController>(force: true);

      Get.offAll(() => SignInView());
      _showSuccess('Logged out successfully');
    } catch (e) {
      debugPrint('Logout error: $e');
      _showError('Failed to logout. Please try again.');
    }
  }

  // Forgot password
  Future<void> sendPasswordResetEmail() async {
    Get.to(() => NotificationsScreen());
  }

  // Show change password dialog
  void showChangePasswordDialog() {
    Get.to(() => ListingFavoritesScreen());
  }

  // Clear all user data
  void _clearUserData() {
    currentUser.value = null;

    // Clear observables
    userName.value = '';
    userEmail.value = '';
    userPhone.value = '';
    userAvatar.value = '';
    displayName.value = '';
    firstName.value = '';
    lastName.value = '';
    website.value = '';
    about.value = '';
    facebookUrl.value = '';
    instagramUrl.value = '';
    linkedinUrl.value = '';
    youtubeUrl.value = '';
    subscriptionPlan.value = 'free';
    isActiveSubscription.value = false;
    stripeCustomerId.value = '';

    // Clear all controllers
    displayNameController.clear();
    userNameController.clear();
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    websiteController.clear();
    descriptionController.clear();
    facebookController.clear();
    instagramController.clear();
    linkedinController.clear();
    youtubeController.clear();
    billingFirstNameController.clear();
    billingLastNameController.clear();
    billingEmailController.clear();
    billingPhoneController.clear();
    billingAddressController.clear();
    billingCityController.clear();
    billingPostcodeController.clear();
    billingCountryController.clear();
    billingStateController.clear();
  }

  // Helper methods for UI feedback
  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }
}
