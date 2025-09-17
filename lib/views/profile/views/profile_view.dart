// ignore_for_file: deprecated_member_use

import 'package:dedicated_cowboy/app/models/api_user_model.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/subcriptions_view.dart';
import 'package:dedicated_cowboy/views/notifications/notifications.dart';
import 'package:dedicated_cowboy/views/predrences/prefrences.dart';
import 'package:dedicated_cowboy/views/privacy/about.dart';
import 'package:dedicated_cowboy/views/privacy/privacy.dart';
import 'package:dedicated_cowboy/views/privacy/terms.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen();
  }
}

class ProfileScreen extends StatelessWidget {
  final ProfileController controller = Get.put(ProfileController());

  var controllerservice = Get.put(AuthService());

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: controller.loadUserProfile,
        color: Color(0xFFF2B342),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(),
              // const SizedBox(height: 24),
              // _buildUserInfoCards(),
              const SizedBox(height: 16),
              _buildMenuItems(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'MY Account',
        style: TextStyle(
          fontFamily: 'popins',
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      actions: [
        IconButton(
          onPressed: controller.loadUserProfile,
          icon: Obx(
            () =>
                controller.isLoadingProfile.value
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black87,
                      ),
                    )
                    : Icon(Icons.refresh, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Avatar
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: ClipOval(
                  child:
                      controller.userAvatar.value.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: controller.userAvatar.value,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  color: Colors.white,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFF2B342),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => _buildAvatarFallback(),
                          )
                          : _buildAvatarFallback(),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controllerservice.currentUser?.displayName ?? 'No name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'popins',
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controllerservice.currentUser?.email ?? 'No name',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'popins',
                    color: Colors.black.withOpacity(0.9),
                  ),
                ),
                if (controller.userPhone.value.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    controller.userPhone.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'popins',
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: controller.toggleEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF2B342),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'EDIT PROFILE',
                    style: TextStyle(
                      fontFamily: 'popins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: Color(0xFFF2B342).withOpacity(0.2),
      child: Center(
        child: Text(
          controller.currentUser.value?.firstName ?? 'U',
          style: TextStyle(
            fontFamily: 'popins',
            color: Color(0xFFF2B342),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(
          icon: 'assets/images/Mark As Favorite.png',
          title: 'My Listings & Favorites',
          subtitle: 'View and manage your listings and favorites',
          onTap: controller.showChangePasswordDialog,
        ),
        _buildMenuItem(
          icon: 'assets/images/Notification.png',
          title: 'Notifications',
          subtitle: 'Manage your notification preferences',
          onTap: controller.sendPasswordResetEmail,
        ),
        _buildMenuItem(
          icon: 'assets/images/contact_page.png',
          title: 'Contact Us',
          subtitle: 'Reach out for support or feedback',
          onTap: () {
            Get.to(() => ContactUsScreen());
          },
        ),
        _buildMenuItem(
          icon: 'assets/images/Subscription.png',
          title: 'Subscriptions',
          subtitle: 'Manage your active subscriptions',
          onTap: () {
            Get.to(
              () => FinalSubscriptionManagementScreen(
                userId: controllerservice.currentUser?.id ?? '',
              ),
            );
          },
        ),
        _buildMenuItem(
          icon: 'assets/images/contact_page.png',
          title: 'Our Story',
          subtitle: 'Learn more about who we are and what we do',
          onTap: () {
            Get.to(() => AboutUsScreen());
          },
        ),
        _buildMenuItem(
          icon: 'assets/images/contact_page.png',
          title: 'Privacy Policy',
          subtitle: 'Understand how we protect and use your data',
          onTap: () {
            Get.to(() => PrivacyPolicyScreen());
          },
        ),
        _buildMenuItem(
          icon: 'assets/images/contact_page.png',
          title: 'Terms and Conditions',
          subtitle: 'Read the rules and guidelines for using our services',
          onTap: () {
            Get.to(() => TermsConditionsScreen());
          },
        ),

        _buildMenuItem(
          icon: 'assets/images/Administrative Tools.png',
          title: 'Preferences',
          subtitle: 'Set your app and content preferences',
          onTap: () {
            Get.to(() => PreferenceScreen());
          },
        ),
        _buildMenuItem(
          icon: 'assets/images/logout.png',
          title: 'LOGOUT',
          subtitle: 'Sign out of your account',
          onTap: controller.logout,
          isDestructive: false,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDestructive ? Colors.red.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDestructive ? Colors.red.shade200 : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.asset(
                    icon,
                    color: isDestructive ? Colors.red.shade600 : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'popins',
                          fontWeight: FontWeight.w400,
                          color:
                              isDestructive
                                  ? Colors.red.shade700
                                  : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'popins',
                          color:
                              isDestructive
                                  ? Colors.red.shade500
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
