// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedicated_cowboy/views/profile/controllers/profile_controller.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

// Import your ProfileController
// import 'package:your_app/controllers/profile_controller.dart';

class UserProfileEditScreen extends StatefulWidget {
  const UserProfileEditScreen({super.key});

  @override
  _UserProfileEditScreenState createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  static const double _collapsedAppBarHeight = 60.0;
  static const double _expandedAppBarHeight = 280.0;

  // Get the ProfileController instance
  final ProfileController controller = Get.find<ProfileController>();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Controllers are already populated from the ProfileController
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildProfileForm()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: _expandedAppBarHeight,
      collapsedHeight: _collapsedAppBarHeight,
      pinned: true,
      backgroundColor: const Color(0xff364C63),
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
      ),
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Background image
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xff364C63),
              child: Image.asset(
                'assets/images/5001147_19742 1.png',
                fit: BoxFit.cover,
              ),
            ),
            // Dark overlay
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.black45),
            ),
            // Profile content
            _buildProfileHeader(),
          ],
        ),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40), // Account for app bar
          Obx(
            () => GestureDetector(
              onTap: controller.changeProfilePicture,
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          controller.isUploadingImage.value
                              ? Container(
                                color: Colors.white,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF2B342),
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : controller.userAvatar.value.isNotEmpty
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
                                    (context, url, error) =>
                                        _buildAvatarFallback(),
                              )
                              : _buildAvatarFallback(),
                    ),
                  ),
                  // Camera icon overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(0xFFF2B342),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              controller.currentUser.value?.fullName ?? 'User Name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Obx(
            () => Text(
              controller.userEmail.value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
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
        child: Obx(
          () => Text(
            controller.currentUser.value?.initials ?? 'U',
            style: TextStyle(
              color: Color(0xFFF2B342),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Section
          _buildSectionTitle('Personal Information'),
          _buildFormField(
            label: 'Display Name',
            controller: controller.displayNameController,
            hintText: 'Enter your display name',
          ),
          _buildFormField(
            label: 'User Name',
            controller: controller.userNameController,
            hintText: 'Enter your username',
          ),
          _buildFormField(
            label: 'First Name',
            controller: controller.firstNameController,
            hintText: 'Enter your first name',
          ),
          _buildFormField(
            label: 'Last Name',
            controller: controller.lastNameController,
            hintText: 'Enter your last name',
          ),
          // _buildFormField(
          //   label: 'Email (Required)',
          //   controller: controller.emailController,
          //   hintText: 'user@example.com',
          //   keyboardType: TextInputType.emailAddress,
          // ),
          _buildFormField(
            label: 'Phone',
            controller: controller.phoneController,
            hintText: 'Enter your phone number',
            keyboardType: TextInputType.phone,
          ),
          _buildFormField(
            label: 'Website',
            controller: controller.websiteController,
            hintText: 'https://yourwebsite.com',
            keyboardType: TextInputType.url,
          ),
          _buildFormField(
            label: 'Address',
            controller: controller.addressController,
            hintText: 'Enter your address',
            maxLines: 3,
          ),

          // Professional Information
          const SizedBox(height: 16),
          _buildSectionTitle('Professional Information'),
          _buildDropdownField(
            label: 'Professional Status',
            value: controller.selectedProfessionalStatus.value,
            items: controller.professionalStatuses,
            onChanged:
                (value) =>
                    controller.selectedProfessionalStatus.value = value ?? '',
          ),
          _buildDropdownField(
            label: 'Industry',
            value: controller.selectedIndustry.value,
            items: controller.industries,
            onChanged:
                (value) => controller.selectedIndustry.value = value ?? '',
          ),

          // Business Information
          const SizedBox(height: 16),
          _buildSectionTitle('Business Information'),
          _buildFormField(
            label: 'Business Name',
            controller: controller.businessNameController,
            hintText: 'Enter your business name',
          ),
          _buildFormField(
            label: 'Business Website',
            controller: controller.businessLinkController,
            hintText: 'https://yourbusiness.com',
            keyboardType: TextInputType.url,
          ),
          _buildFormField(
            label: 'Business Address',
            controller: controller.businessAddressController,
            hintText: 'Enter your business address',
            maxLines: 3,
          ),

          // Password Section
          const SizedBox(height: 16),
          _buildSectionTitle('Change Password (Optional)'),
          _buildPasswordField(
            label: 'New Password',
            controller: controller.newPasswordController,
            hintText: 'Enter new password',
            obscureText: _obscureNewPassword,
            onToggle:
                () =>
                    setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
          _buildPasswordField(
            label: 'Confirm New Password',
            controller: controller.confirmPasswordController,
            hintText: 'Confirm new password',
            obscureText: _obscureConfirmPassword,
            onToggle:
                () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
          ),

          _buildFormField(
            label: 'About',
            controller: controller.aboutController,
            hintText: 'Tell us about yourself',
            maxLines: 4,
          ),

          const SizedBox(height: 32),
          _buildSocialProfiles(),
          const SizedBox(height: 40),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF2B342), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isNotEmpty ? value : null,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF2B342), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF2B342), width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSocialProfiles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Social Profiles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildSocialField(
          icon: Icons.facebook,
          label: 'Facebook',
          controller: controller.facebookController,
          color: const Color(0xff1877F2),
        ),
        _buildSocialField(
          icon: Icons.alternate_email,
          label: 'Twitter',
          controller: controller.twitterController,
          color: const Color(0xff1DA1F2),
        ),
        _buildSocialField(
          icon: Icons.work,
          label: 'LinkedIn',
          controller: controller.linkedinController,
          color: const Color(0xff0A66C2),
        ),
        _buildSocialField(
          icon: Icons.video_library,
          label: 'YouTube',
          controller: controller.youtubeController,
          color: const Color(0xffFF0000),
        ),
      ],
    );
  }

  Widget _buildSocialField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Add your $label URL',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(
      () => CustomElevatedButton(
        text: 'Save Changes',
        backgroundColor: Color(0xFFF2B342),
        textColor: Colors.white,
        fontSize: 18.sp,
        fontWeight: FontWeight.w900,
        borderRadius: 20.r,
        isLoading: controller.isSaving.value,
        onTap: controller.saveProfileChanges,
      ),
    );
  }
}
