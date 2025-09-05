import 'dart:io';
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/views/listing/bussiness_listing/controller/list_bussiness_controller.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class BusinessPreviewScreen extends StatelessWidget {
  const BusinessPreviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ListBusinessController controller =
        Get.find<ListBusinessController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Preview Your Business Listing',
          style: Appthemes.textMedium.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: appColors.darkBlueText,
            decoration: TextDecoration.underline,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Gallery Section (Images, Videos, Attachments)
            _buildMediaGallery(controller),

            const SizedBox(height: 20),

            // Business Name
            _buildInfoText(
              'Business Name:',
              controller.businessNameController.text,
            ),

            const SizedBox(height: 16),

            // Description
            _buildInfoText(
              'Description:',
              controller.descriptionController.text,
            ),

            const SizedBox(height: 16),

            // Business Categories
            _buildCategoriesSection(controller),

            const SizedBox(height: 16),

            // Subcategory (if available)
            _buildInfoText(
              'Subcategory:',
              controller.selectedSubcategory.value,
            ),

            const SizedBox(height: 16),

            // Website/Online Store
            _buildInfoText(
              'Website/Online Store:',
              controller.websiteController.text,
            ),

            const SizedBox(height: 20),

            // Location Section
            _buildLocationSection(controller),

            const SizedBox(height: 20),

            // Contact Information Section
            _buildContactInfoSection(controller),

            const SizedBox(height: 30),

            // Action Buttons
            _buildActionButtons(controller),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGallery(ListBusinessController controller) {
    return Obx(() {
      final hasImages = controller.imageUploadStatuses.isNotEmpty;
      final hasVideos = controller.videoUploadStatuses.isNotEmpty;
      final hasAttachments = controller.attachmentUploadStatuses.isNotEmpty;

      if (!hasImages && !hasVideos && !hasAttachments) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 50, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No media uploaded',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images Section
          if (hasImages) ...[
            Text(
              'Images (${controller.imageUploadStatuses.length})',
              style: Appthemes.textMedium.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child:
                  controller.imageUploadStatuses.length == 1
                      ? controller.imageUploadStatuses.first.uploadedUrl != null
                          ? _buildSingleNetworkImage(
                            controller.imageUploadStatuses.first.uploadedUrl!,
                          )
                          : _buildSingleImage(
                            controller.imageUploadStatuses.first.file,
                          )
                      : controller.isEditMode.value
                      ? _buildImageGridNetwork(
                        controller.imageUploadStatuses
                            .map((status) => status.uploadedUrl ?? '')
                            .toList(),
                      )
                      : _buildImageGrid(
                        controller.imageUploadStatuses
                            .map((status) => status.file)
                            .toList(),
                      ),
            ),
            const SizedBox(height: 16),
          ],

          // Videos Section
          if (hasVideos) ...[
            Text(
              'Videos (${controller.videoUploadStatuses.length})',
              style: Appthemes.textMedium.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.videoUploadStatuses.length,
              itemBuilder: (context, index) {
                final videoFile = controller.videoUploadStatuses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C3E50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          videoFile.file.path.split('/').last,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Attachments Section
          if (hasAttachments) ...[
            Text(
              'Attachments (${controller.attachmentUploadStatuses.length})',
              style: Appthemes.textMedium.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.attachmentUploadStatuses.length,
              itemBuilder: (context, index) {
                final attachmentFile =
                    controller.attachmentUploadStatuses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFF2B342),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          attachmentFile.file.path.split('/').last,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      );
    });
  }

  Widget _buildSingleImage(File image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildSingleNetworkImage(String image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildImageGridNetwork(List<String> images) {
    if (images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.network(
                images[0],
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.network(
                images[1],
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.network(
                images[0],
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      images[1],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          images[2],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      if (images.length > 3)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+${images.length - 3}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildImageGrid(List<File> images) {
    if (images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.file(
                images[0],
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.file(
                images[1],
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.file(
                images[0],
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                    ),
                    child: Image.file(
                      images[1],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                        child: Image.file(
                          images[2],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      if (images.length > 3)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+${images.length - 3}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildInfoText(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          TextSpan(
            text: ' $value',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(ListBusinessController controller) {
    return Obx(() {
      if (controller.selectedCategories.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Categories:',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children:
                controller.selectedCategories.map((category) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: appColors.pYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: appColors.pYellow, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.business,
                          color: appColors.pYellow,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: appColors.pYellow,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      );
    });
  }

  Widget _buildLocationSection(ListBusinessController controller) {
    if (controller.locationController.text.isEmpty)
      return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Location',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: appColors.pYellow, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.locationController.text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection(ListBusinessController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              // Email (Required)
              _buildContactRow(
                Icons.email_outlined,
                'Email:',
                controller.emailController.text.isNotEmpty
                    ? controller.emailController.text
                    : 'No email provided',
                controller.emailController.text.isNotEmpty,
              ),

              // Website/Online Store
              if (controller.websiteController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildContactRow(
                  Icons.web,
                  'Website:',
                  controller.websiteController.text,
                  true,
                ),
              ],

              // Text Number
              if (controller.textController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildContactRow(
                  Icons.message_outlined,
                  'Text Messages:',
                  controller.textController.text,
                  true,
                ),
              ],

              // Call Number
              if (controller.callController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildContactRow(
                  Icons.phone_outlined,
                  'Phone Calls:',
                  controller.callController.text,
                  true,
                ),
              ],

              // Facebook/Instagram
              if (controller.facebookInstagramController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildContactRow(
                  Icons.link,
                  'Social Media:',
                  controller.facebookInstagramController.text,
                  true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value,
    bool hasRealData,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: appColors.pYellow, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: hasRealData ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ListBusinessController controller) {
    return Column(
      children: [
        // Edit Listing Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: CustomElevatedButton(
            text: 'Edit Business Listing',
            backgroundColor: Colors.white,
            textColor: appColors.pYellow,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            borderRadius: 28.r,
            onTap: () => Get.back(),
          ),
        ),

        const SizedBox(height: 16),

        // Publish Listing Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Obx(
            () => CustomElevatedButton(
              text:
                  controller.isEditMode.value
                      ? 'Update Listing'
                      : 'Publish Business Listing',
              backgroundColor: appColors.pYellow,
              textColor: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              borderRadius: 28.r,
              isLoading: controller.isLoading.value,
              onTap: () {
                controller.publishListing();
              },
            ),
          ),
        ),
      ],
    );
  }
}
