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
            color: Colors.black,
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
            // Image Gallery Section
            _buildImageGallery(controller),

            const SizedBox(height: 20),

            // Business Name
            _buildInfoText(
              'Business Name :',
              controller.businessNameController.text,
            ),

            const SizedBox(height: 16),

            // Description
            _buildInfoText(
              'Description :',
              controller.descriptionController.text,
            ),

            const SizedBox(height: 16),

            // Business Category
            _buildInfoText(
              'Business Category :',
              controller.selectedBusinessCategory.value,
            ),

            const SizedBox(height: 16),

            // Subcategory - Only show if not empty
            if (controller.selectedSubcategory.value.isNotEmpty)
              _buildInfoText(
                'Subcategory :',
                controller.selectedSubcategory.value,
              ),

            const SizedBox(height: 16),

            // Website - Only show if not empty
            if (controller.websiteController.text.isNotEmpty)
              _buildInfoText(
                'Website/Online Store :',
                controller.websiteController.text,
              ),

            const SizedBox(height: 16),

            // Address Section
            _buildAddressSection(controller),

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

  Widget _buildImageGallery(ListBusinessController controller) {
    return Obx(() {
      if (controller.imageUploadStatuses.isNotEmpty) {
        return Container(
          height: 300,
          child:
              controller.imageUploadStatuses.length == 1
                  ? _buildSingleImage(controller.imageUploadStatuses.first.file)
                  : _buildImageGrid(
                    controller.imageUploadStatuses.map((e) => e.file).toList(),
                  ),
        );
      } else {
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
                Icon(Icons.business, size: 50, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No business images uploaded',
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

  Widget _buildAddressSection(ListBusinessController controller) {
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
            'Address, Location / City & State',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.locationController.text.isNotEmpty
                ? controller.locationController.text
                : 'No address provided',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color:
                  controller.locationController.text.isNotEmpty
                      ? Colors.black87
                      : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Map placeholder
            Container(
              color: Colors.blue.shade100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 50,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Business Location',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Location marker
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.location_on, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
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

          // Email - Always show since it's required
          _buildContactRow(
            'Email :',
            controller.emailController.text.isNotEmpty
                ? controller.emailController.text
                : 'No email provided',
            controller.emailController.text.isNotEmpty,
          ),

          // Website - Only show if provided
          if (controller.websiteController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildContactRow(
              'Website :',
              controller.websiteController.text,
              true,
            ),
          ],

          // Text Number - Show if provided, otherwise show placeholder
          const SizedBox(height: 8),
          _buildContactRow(
            'Phone number for text :',
            controller.textController.text.isNotEmpty
                ? controller.textController.text
                : 'No text number provided',
            controller.textController.text.isNotEmpty,
          ),

          // Call Number - Show if provided, otherwise show placeholder
          const SizedBox(height: 8),
          _buildContactRow(
            'Phone number for call :',
            controller.callController.text.isNotEmpty
                ? controller.callController.text
                : 'No call number provided',
            controller.callController.text.isNotEmpty,
          ),

          // Facebook/Instagram - Show if provided, otherwise show placeholder
          const SizedBox(height: 8),
          _buildContactRow(
            'Social Media :',
            controller.facebookInstagramController.text.isNotEmpty
                ? controller.facebookInstagramController.text
                : 'No social media provided',
            controller.facebookInstagramController.text.isNotEmpty,
          ),

          // Operating Hours - This would need to be added to controller if you want it dynamic
          const SizedBox(height: 8),
          _buildContactRow(
            'Operating Hours :',
            'Mon-Fri: 9AM-6PM, Sat: 10AM-4PM', // Keep static for now
            false, // This indicates it's placeholder data
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value, bool hasRealData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            backgroundColor: appColors.pYellow,
            textColor: Colors.white,
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
              text: 'Publish Business Listing',
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
