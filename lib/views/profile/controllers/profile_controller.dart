// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/models/user_model.dart';
import 'package:dedicated_cowboy/main.dart';
import 'package:dedicated_cowboy/views/chats/rooms.dart';
import 'package:dedicated_cowboy/views/my_listings/my_listings.dart';
import 'package:dedicated_cowboy/views/notifications/notifications.dart';
import 'package:dedicated_cowboy/views/profile/views/edit.dart';
import 'package:dedicated_cowboy/views/sign_in/sign_in_view.dart';
import 'package:dedicated_cowboy/views/welcome/welcome_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
// Import your UserModel and uploadMedia function
// import 'package:your_app/models/user_model.dart';
// import 'package:your_app/utils/upload_media.dart';

class ProfileController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String usersCollection = 'users';

  // Observable user data
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Basic Info
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

  // Business Info
  final RxString businessName = ''.obs;
  final RxString businessLink = ''.obs;
  final RxString businessAddress = ''.obs;
  final RxString professionalStatus = ''.obs;
  final RxString industry = ''.obs;

  // Social Media
  final RxString facebookUrl = ''.obs;
  final RxString twitterUrl = ''.obs;
  final RxString linkedinUrl = ''.obs;
  final RxString youtubeUrl = ''.obs;

  // Professional status and industry options
  final List<String> professionalStatuses = [
    "Business Owner",
    "Freelancer",
    "Contractor",
    "Employee",
  ];

  final List<String> industries = [
    "Technology",
    "Healthcare",
    "Finance",
    "Education",
    "Retail",
    "Manufacturing",
    "Real Estate",
    "Other",
  ];

  // Form controllers
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController businessLinkController = TextEditingController();
  final TextEditingController businessAddressController =
      TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Social Media Controllers
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController twitterController = TextEditingController();
  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController youtubeController = TextEditingController();

  // UI state
  final RxBool isEditing = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingProfile = true.obs;
  final RxBool isUpdatingPassword = false.obs;
  final RxBool showCurrentPassword = false.obs;
  final RxBool showNewPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isSaving = false.obs;

  // Selected values
  final RxString selectedProfessionalStatus = ''.obs;
  final RxString selectedIndustry = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUserData();
  }

  @override
  void onClose() {
    _disposeControllers();
    super.onClose();
  }

  void _disposeControllers() {
    displayNameController.dispose();
    userNameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    addressController.dispose();
    aboutController.dispose();
    businessNameController.dispose();
    businessLinkController.dispose();
    businessAddressController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    facebookController.dispose();
    twitterController.dispose();
    linkedinController.dispose();
    youtubeController.dispose();
  }

  // Initialize user data from Firebase
  void _initializeUserData() async {
    try {
      await loadUserProfile();
    } catch (e) {
      print('Error initializing user data: $e');
    }
  }

  // Load user profile from Firestore
  Future<void> loadUserProfile() async {
    try {
      isLoadingProfile.value = true;

      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No authenticated user found');
      }

      final DocumentSnapshot userDoc =
          await _firestore
              .collection(usersCollection)
              .doc(firebaseUser.uid)
              .get();

      if (userDoc.exists) {
        final userData = UserModel.fromJson(
          userDoc.data() as Map<String, dynamic>,
        );
        currentUser.value = userData;
        _updateObservablesFromModel(userData);
        _updateControllersFromModel(userData);
      } else {
        // Create user document if it doesn't exist
        await _createUserDocument(firebaseUser);
      }
    } catch (e) {
      print('Error loading user profile: $e');
      Get.snackbar(
        'Error',
        'Failed to load profile data',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingProfile.value = false;
    }
  }

  // Create user document if it doesn't exist
  Future<void> _createUserDocument(User firebaseUser) async {
    try {
      final userData = UserModel.fromFirebaseUser(firebaseUser);

      await _firestore
          .collection(usersCollection)
          .doc(firebaseUser.uid)
          .set(userData.toJson(), SetOptions(merge: true));

      currentUser.value = userData;
      _updateObservablesFromModel(userData);
      _updateControllersFromModel(userData);
    } catch (e) {
      print('Error creating user document: $e');
      throw e;
    }
  }

  // Update observables from UserModel
  void _updateObservablesFromModel(UserModel user) {
    displayName.value = user.displayName ?? '';
    userName.value = user.userName ?? '';
    firstName.value = user.firstName ?? '';
    lastName.value = user.lastName ?? '';
    userEmail.value = user.email;
    userPhone.value = user.phone ?? '';
    userAvatar.value = user.profileImageUrl;
    website.value = user.website ?? '';
    address.value = user.address ?? '';
    about.value = user.about ?? '';
    businessName.value = user.businessName ?? '';
    businessLink.value = user.businessLink ?? '';
    businessAddress.value = user.businessAddress ?? '';
    professionalStatus.value = user.professionalStatus ?? '';
    industry.value = user.industry ?? '';
    selectedProfessionalStatus.value = user.professionalStatus ?? '';
    selectedIndustry.value = user.industry ?? '';
    facebookUrl.value = user.facebookUrl ?? '';
    twitterUrl.value = user.twitterUrl ?? '';
    linkedinUrl.value = user.linkedinUrl ?? '';
    youtubeUrl.value = user.youtubeUrl ?? '';
  }

  // Update form controllers with current data
  void _updateControllersFromModel(UserModel user) {
    displayNameController.text = user.displayName ?? '';
    userNameController.text = user.userName ?? '';
    firstNameController.text = user.firstName ?? '';
    lastNameController.text = user.lastName ?? '';
    nameController.text = user.fullName;
    emailController.text = user.email;
    phoneController.text = user.phone ?? '';
    websiteController.text = user.website ?? '';
    addressController.text = user.address ?? '';
    aboutController.text = user.about ?? '';
    businessNameController.text = user.businessName ?? '';
    businessLinkController.text = user.businessLink ?? '';
    businessAddressController.text = user.businessAddress ?? '';
    facebookController.text = user.facebookUrl ?? '';
    twitterController.text = user.twitterUrl ?? '';
    linkedinController.text = user.linkedinUrl ?? '';
    youtubeController.text = user.youtubeUrl ?? '';
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
        // Use your uploadMedia function here
        final String imageUrl = await uploadMedia([File(image.path)]);

        // // For now, simulate upload
        // await Future.delayed(Duration(seconds: 2));
        // final String imageUrl = 'https://example.com/uploaded-image.jpg';

        // Update user avatar
        await updateUserField('avatar', imageUrl);
        userAvatar.value = imageUrl;

        Get.snackbar(
          'Success',
          'Profile picture updated successfully',
          backgroundColor: Color(0xFFF3B340),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error changing profile picture: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile picture',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  // Update single user field
  Future<void> updateUserField(String field, dynamic value) async {
    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) throw Exception('No authenticated user');

      await _firestore.collection(usersCollection).doc(firebaseUser.uid).update(
        {field: value, 'updatedAt': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      print('Error updating user field $field: $e');
      throw e;
    }
  }

  // Save all profile changes
  Future<void> saveProfileChanges() async {
    try {
      isSaving.value = true;

      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) throw Exception('No authenticated user');

      // Validate required fields
      if (emailController.text.trim().isEmpty) {
        throw Exception('Email is required');
      }

      // Validate password confirmation if new password is provided
      if (newPasswordController.text.isNotEmpty &&
          newPasswordController.text != confirmPasswordController.text) {
        throw Exception('Passwords do not match');
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'displayName': displayNameController.text.trim(),
        'userName': userNameController.text.trim(),
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'website': websiteController.text.trim(),
        'address': addressController.text.trim(),
        'about': aboutController.text.trim(),
        'businessName': businessNameController.text.trim(),
        'businessLink': businessLinkController.text.trim(),
        'businessAddress': businessAddressController.text.trim(),
        'professionalStatus': selectedProfessionalStatus.value,
        'industry': selectedIndustry.value,
        'facebookUrl': facebookController.text.trim(),
        'twitterUrl': twitterController.text.trim(),
        'linkedinUrl': linkedinController.text.trim(),
        'youtubeUrl': youtubeController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Update Firestore
      await _firestore
          .collection(usersCollection)
          .doc(firebaseUser.uid)
          .update(updateData);

      // Update Firebase Auth profile if display name changed
      if (displayNameController.text.trim() != firebaseUser.displayName) {
        await firebaseUser.updateDisplayName(displayNameController.text.trim());
      }

      // Update password if provided
      if (newPasswordController.text.isNotEmpty) {
        await firebaseUser.updatePassword(newPasswordController.text);
        newPasswordController.clear();
        confirmPasswordController.clear();
        currentPasswordController.clear();
      }

      // Reload user profile
      await loadUserProfile();

      isEditing.value = false;
      Get.back(); // Go back to profile view

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        backgroundColor: Color(0xFFF3B340),
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error saving profile: $e');
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // Change password
  Future<void> changePassword() async {
    try {
      isUpdatingPassword.value = true;

      if (currentPasswordController.text.isEmpty ||
          newPasswordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        throw Exception('All password fields are required');
      }

      if (newPasswordController.text != confirmPasswordController.text) {
        throw Exception('New passwords do not match');
      }

      if (newPasswordController.text.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final User? user = _auth.currentUser;
      if (user?.email == null) throw Exception('No authenticated user');

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPasswordController.text);

      // Clear password fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      Get.back(); // Close dialog

      Get.snackbar(
        'Success',
        'Password updated successfully',
        backgroundColor: Color(0xFFF3B340),
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error changing password: $e');
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUpdatingPassword.value = false;
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

  // Password visibility toggles
  void toggleCurrentPasswordVisibility() =>
      showCurrentPassword.value = !showCurrentPassword.value;
  void toggleNewPasswordVisibility() =>
      showNewPassword.value = !showNewPassword.value;
  void toggleConfirmPasswordVisibility() =>
      showConfirmPassword.value = !showConfirmPassword.value;

  // Logout
  void logout() {
    _showLogoutDialog(Get.context!);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: EdgeInsets.all(30),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout, color: Color(0xFF3182CE), size: 24),
              ),
              SizedBox(height: 20),
              Text(
                'Are You Sure You Want To Logout',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Logging out will end your current session. You\'ll need to sign in again to access your account.',
                style: TextStyle(fontSize: 16, color: Color(0xFF718096)),
                textAlign: TextAlign.start,
              ),
              SizedBox(height: 25),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await logoutUser();
                        Get.delete<ChatRoomsController>(force: true);
                        Get.offAll(() => SignInView());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFBB040),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF7FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
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
        );
      },
    );
  }

  Future<void> logoutUser() async {
    try {
      // Update user status to offline
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection(usersCollection).doc(user.uid).update({
          'isOnline': false,
          'lastSeen': DateTime.now().toIso8601String(),
        });
      }

      await FirebaseAuth.instance.signOut();

      // Clear all observables
      currentUser.value = null;
      _clearAllData();

      print("User logged out successfully");
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  // Clear all data
  void _clearAllData() {
    // Clear observables
    userName.value = '';
    userEmail.value = '';
    userPhone.value = '';
    userAvatar.value = '';
    displayName.value = '';
    firstName.value = '';
    lastName.value = '';
    website.value = '';
    address.value = '';
    about.value = '';
    businessName.value = '';
    businessLink.value = '';
    businessAddress.value = '';
    professionalStatus.value = '';
    industry.value = '';
    selectedProfessionalStatus.value = '';
    selectedIndustry.value = '';
    facebookUrl.value = '';
    twitterUrl.value = '';
    linkedinUrl.value = '';
    youtubeUrl.value = '';

    // Clear controllers
    displayNameController.clear();
    userNameController.clear();
    firstNameController.clear();
    lastNameController.clear();
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    websiteController.clear();
    addressController.clear();
    aboutController.clear();
    businessNameController.clear();
    businessLinkController.clear();
    businessAddressController.clear();
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    facebookController.clear();
    twitterController.clear();
    linkedinController.clear();
    youtubeController.clear();
  }
}
