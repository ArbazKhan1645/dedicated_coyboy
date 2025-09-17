import 'dart:io';
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/controller/add_listing_controller.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ListingItemPreviewScreen extends StatelessWidget {
  const ListingItemPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ListItemController controller =
        Get.isRegistered<ListItemController>()
            ? Get.find<ListItemController>()
            : Get.put(ListItemController());
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
          'Preview Your Listing',
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

            // Item Name
            _buildInfoText('Item Name:', controller.itemNameController.text),

            const SizedBox(height: 16),

            // Description
            _buildInfoText(
              'Description:',
              controller.descriptionController.text,
            ),

            const SizedBox(height: 16),

            // Categories
            _buildCategoriesSection(controller),

            const SizedBox(height: 16),

            // Subcategory
            _buildInfoText(
              'Subcategory:',
              controller.selectedSubcategory.value,
            ),

            const SizedBox(height: 16),

            // Brand
            _buildInfoText('Brand:', controller.brandController.text),

            const SizedBox(height: 16),

            // Price
            _buildInfoText('Price:', '\$${controller.priceController.text}'),

            const SizedBox(height: 16),

            // Size / Dimensions
            _buildInfoText(
              'Size / Dimensions:',
              controller.sizeController.text,
            ),

            const SizedBox(height: 16),

            // Condition
            _buildInfoText('Condition:', controller.selectedCondition.value),

            const SizedBox(height: 16),

            // Link/Website
            _buildInfoText(
              'Link/Website:',
              controller.linkWebsiteController.text,
            ),

            const SizedBox(height: 20),

            // Location Section
            _buildLocationSection(controller),

            const SizedBox(height: 20),

            // Shipping Info Section
            _buildShippingSection(controller),

            const SizedBox(height: 20),

            // Contact Information Section
            _buildContactInfoSection(controller),

            const SizedBox(height: 20),

            // Payment Methods Section
            _buildPaymentMethodsSection(controller),

            const SizedBox(height: 20),

            // Other Payment Methods Section
            _buildOtherPaymentSection(controller),

            const SizedBox(height: 30),

            // Action Buttons
            _buildActionButtons(controller),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGallery(ListItemController controller) {
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

  Widget _buildCategoriesSection(ListItemController controller) {
    return Obx(() {
      if (controller.selectedCategories.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories:',
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
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: appColors.pYellow,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      );
    });
  }

  Widget _buildLocationSection(ListItemController controller) {
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
            'Location / City & State',
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

  Widget _buildShippingSection(ListItemController controller) {
    if (controller.shippingController.text.isEmpty)
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
            'Shipping Info / Pickup',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.local_shipping, color: appColors.pYellow, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.shippingController.text,
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

  Widget _buildContactInfoSection(ListItemController controller) {
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
              // Email
              if (controller.emailController.text.isNotEmpty)
                _buildContactRow(
                  Icons.email_outlined,
                  'Email:',
                  controller.emailController.text,
                ),

              // Phone Number
              if (controller.phoneController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildContactRow(
                  Icons.phone,
                  'Phone:',
                  controller.phoneController.text,
                ),
              ],

              // Facebook
              if (controller.facebookController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildContactRow(
                  Icons.face,
                  'Facebook:',
                  controller.facebookController.text,
                ),
              ],

              // Preferred Contact Method
              Obx(() {
                if (controller.selectedContactMethod.value.isNotEmpty) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildContactRow(
                        Icons.contact_support,
                        'Preferred Contact:',
                        controller.selectedContactMethod.value,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: appColors.pYellow, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: Appthemes.textSmall.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Appthemes.textSmall.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsSection(ListItemController controller) {
    return Obx(() {
      if (controller.selectedPaymentMethod.isEmpty) {
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
              'Payment Methods',
              style: Appthemes.textMedium.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12.0,
              runSpacing: 8.0,
              children:
                  controller.selectedPaymentMethod.map((method) {
                    IconData icon;
                    switch (method.toLowerCase()) {
                      case 'paypal':
                        icon = Icons.payment;
                        break;
                      case 'cash':
                        icon = Icons.attach_money;
                        break;
                      case 'venmo':
                        icon = Icons.account_balance_wallet;
                        break;
                      case 'cashapp':
                        icon = Icons.account_balance_wallet;
                        break;
                      case 'credit card':
                        icon = Icons.credit_card;
                        break;
                      default:
                        icon = Icons.payment;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: appColors.pYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: appColors.pYellow, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: appColors.pYellow, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            method,
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

            // Show payment account details if available
            const SizedBox(height: 12),

            // PayPal Account
            if (controller.selectedPaymentMethod.contains('Paypal') &&
                controller.paypalController.text.isNotEmpty) ...[
              _buildPaymentAccountRow(
                'PayPal Account:',
                controller.paypalController.text,
              ),
              const SizedBox(height: 8),
            ],

            // Venmo Account
            if (controller.selectedPaymentMethod.contains('VENMO') &&
                controller.venmoAccountController.text.isNotEmpty) ...[
              _buildPaymentAccountRow(
                'Venmo Account:',
                controller.venmoAccountController.text,
              ),
              const SizedBox(height: 8),
            ],

            // CashApp Account
            if (controller.selectedPaymentMethod.contains('CashApp') &&
                controller.cashappAccountController.text.isNotEmpty) ...[
              _buildPaymentAccountRow(
                'CashApp Account:',
                controller.cashappAccountController.text,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildPaymentAccountRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherPaymentSection(ListItemController controller) {
    if (controller.otherPaymentController.text.isEmpty)
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
            'Other Payment Options',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.more_horiz, color: appColors.pYellow, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.otherPaymentController.text,
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

  Widget _buildActionButtons(ListItemController controller) {
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
