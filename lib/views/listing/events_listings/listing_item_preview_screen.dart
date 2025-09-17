import 'dart:io';
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/views/listing/events_listings/controller/add_listing_controller.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ListingEventPreviewScreen extends StatelessWidget {
  const ListingEventPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ListEventController controller =
        Get.isRegistered<ListEventController>()
            ? Get.find<ListEventController>()
            : Get.put(ListEventController());

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
          'Preview Your Event',
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

            // Event Name
            _buildInfoText('Event Name:', controller.itemNameController.text),

            const SizedBox(height: 16),

            // Description
            _buildInfoText(
              'Description:',
              controller.descriptionController.text,
            ),

            const SizedBox(height: 16),

            // Event Categories
            _buildCategoriesSection(controller),

            const SizedBox(height: 16),

            // Subcategory (if available)
            _buildInfoText(
              'Subcategory:',
              controller.selectedSubcategory.value,
            ),

            const SizedBox(height: 20),

            // Event Dates Section
            _buildEventDatesSection(controller),

            const SizedBox(height: 20),

            // Location Section
            _buildLocationSection(controller),

            const SizedBox(height: 20),

            // Event Links Section
            _buildEventLinksSection(controller),

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

  Widget _buildMediaGallery(ListEventController controller) {
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

  Widget _buildCategoriesSection(ListEventController controller) {
    return Obx(() {
      if (controller.selectedCategories.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Categories:',
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
                        Icon(Icons.event, color: appColors.pYellow, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          category.name,
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

  Widget _buildEventDatesSection(ListEventController controller) {
    final hasStartDate = controller.startDateController.text.isNotEmpty;
    final hasEndDate = controller.endDateController.text.isNotEmpty;

    if (!hasStartDate && !hasEndDate) return const SizedBox.shrink();

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
            'Event Schedule',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Start Date
          if (hasStartDate) ...[
            Row(
              children: [
                Icon(Icons.event_available, color: appColors.pYellow, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Starts:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.startDateController.text,
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

          // End Date
          if (hasEndDate) ...[
            if (hasStartDate) const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event_busy, color: Colors.red.shade400, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Ends:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.endDateController.text,
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
        ],
      ),
    );
  }

  Widget _buildLocationSection(ListEventController controller) {
    if (controller.locationController.text.isEmpty) {
      return const SizedBox.shrink();
    }

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
            'Event Location',
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

  Widget _buildEventLinksSection(ListEventController controller) {
    final hasWebsiteLink = controller.linkWebsiteController.text.isNotEmpty;
    final hasFacebookLink = controller.facebookController.text.isNotEmpty;

    if (!hasWebsiteLink && !hasFacebookLink) return const SizedBox.shrink();

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
            'Event Links',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Website/Registration Link
          if (hasWebsiteLink) ...[
            Row(
              children: [
                Icon(Icons.web, color: appColors.pYellow, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Website/Registration:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.linkWebsiteController.text,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.blue.shade600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Facebook/Social Link
          if (hasFacebookLink) ...[
            if (hasWebsiteLink) const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.facebook, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Facebook Event:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.facebookController.text,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.blue.shade600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfoSection(ListEventController controller) {
    if (controller.contactController.text.isEmpty) {
      return const SizedBox.shrink();
    }

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
          Row(
            children: [
              Icon(Icons.contact_support, color: appColors.pYellow, size: 18),
              const SizedBox(width: 12),
              Text(
                'Contact:',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.contactController.text,
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

  Widget _buildActionButtons(ListEventController controller) {
    return Column(
      children: [
        // Edit Listing Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: CustomElevatedButton(
            text: 'Edit Listing',

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
                      : ' Publish Listing',
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
