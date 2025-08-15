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
    final ListItemController controller = Get.find<ListItemController>();

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
            // Image Gallery Section
            _buildImageGallery(controller),

            const SizedBox(height: 20),

            // Item Name
            _buildInfoText('Item Name :', controller.itemNameController.text),

            const SizedBox(height: 16),

            // Description
            _buildInfoText(
              'Description :',
              controller.descriptionController.text,
            ),

            const SizedBox(height: 16),

            // Category
            _buildInfoText('Category :', controller.selectedCategory.value),

            const SizedBox(height: 16),

            // Subcategory
            _buildInfoText(
              'Subcategory :',
              controller.selectedSubcategory.value,
            ),

            const SizedBox(height: 16),

            // Condition
            _buildInfoText('Condition :', controller.selectedCondition.value),

            const SizedBox(height: 16),

            // Brand
            _buildInfoText('Brand :', controller.brandController.text),

            const SizedBox(height: 16),

            // Price
            _buildInfoText('Price :', '\$${controller.priceController.text}'),

            const SizedBox(height: 16),

            // Link/Website
            if (controller.linkWebsiteController.text.isNotEmpty)
              _buildInfoText(
                'Link/Website :',
                controller.linkWebsiteController.text,
              ),

            const SizedBox(height: 16),

            // Size Options
            _buildSizeSection(controller),

            const SizedBox(height: 20),

            // Location Section
            _buildLocationSection(controller),

            const SizedBox(height: 20),

            // Payment Methods Section
            _buildPaymentMethodsSection(controller),

            const SizedBox(height: 20),

            // Other Payment Methods Section
            if (controller.otherPaymentController.text.isNotEmpty)
              _buildOtherPaymentSection(controller),

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

  Widget _buildImageGallery(ListItemController controller) {
    return Obx(() {
      if (controller.imageUploadStatuses.isNotEmpty) {
        return SizedBox(
          height: 300,
          child:
              controller.imageUploadStatuses.length == 1
                  ? _buildSingleImage(controller.imageUploadStatuses.first.file)
                  : _buildImageGrid(controller.imageUploadStatuses.map((status) => status.file).toList()),
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
                Icon(Icons.image, size: 50, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No images uploaded',
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

  Widget _buildSizeSection(ListItemController controller) {
    if (controller.sizeController.text.isEmpty) return const SizedBox.shrink();

    // Parse the size value from controller - assuming it contains selected sizes
    String sizeText = controller.sizeController.text;
    List<String> availableSizes = ['S', 'M', 'L', 'XL'];
    List<String> selectedSizes =
        sizeText.split(',').map((s) => s.trim()).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Size :',
          style: Appthemes.textMedium.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children:
              availableSizes.map((size) {
                bool isSelected =
                    selectedSizes.contains(size) ||
                    (selectedSizes.length == 1 && selectedSizes.first == size);
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? appColors.pYellow : Colors.white,
                    border: Border.all(
                      color:
                          isSelected ? appColors.pYellow : Colors.grey.shade300,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    size,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationSection(ListItemController controller) {
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
          Text(
            controller.locationController.text.isNotEmpty
                ? controller.locationController.text
                : 'No location specified',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection(ListItemController controller) {
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
            'Select Payment method',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentRadioOption(
                        'Paypal',
                        controller.selectedPaymentMethod.value == 'Paypal',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildPaymentRadioOption(
                        'Credit Card',
                        controller.selectedPaymentMethod.value == 'Credit Card',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentRadioOption(
                        'Cash',
                        controller.selectedPaymentMethod.value == 'Cash',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildPaymentRadioOption(
                        'VENMO',
                        controller.selectedPaymentMethod.value == 'VENMO',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRadioOption(String label, bool isSelected) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? appColors.pYellow : Colors.transparent,
            border: Border.all(
              color: isSelected ? appColors.pYellow : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child:
              isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildOtherPaymentSection(ListItemController controller) {
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
            'Other Payment method',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                controller.otherPaymentController.text.isNotEmpty
                    ? controller.otherPaymentController.text
                    : 'No other payment method specified',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
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
            'Preferred Method of Contact',
            style: Appthemes.textMedium.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Column(
              children: [
                // Email - Always show if available
                if (controller.emailController.text.isNotEmpty)
                  _buildContactRow('Email :', controller.emailController.text),

                // PayPal email if different from main email
                if (controller.paypalController.text.isNotEmpty &&
                    controller.paypalController.text !=
                        controller.emailController.text) ...[
                  const SizedBox(height: 8),
                  _buildContactRow(
                    'PayPal :',
                    controller.paypalController.text,
                  ),
                ],

                // Show selected contact method
                if (controller.selectedContactMethod.value.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildContactRow(
                    'Preferred Contact :',
                    controller.selectedContactMethod.value,
                  ),
                ],

                // Shipping info
                if (controller.shippingController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildContactRow(
                    'Shipping info / Pickup :',
                    controller.shippingController.text,
                  ),
                ],

                // If no contact info is available, show a message
                if (controller.emailController.text.isEmpty &&
                    controller.paypalController.text.isEmpty &&
                    controller.selectedContactMethod.value.isEmpty &&
                    controller.shippingController.text.isEmpty)
                  _buildContactRow(
                    'Contact :',
                    'No contact information provided',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              text: 'Publish Listing',
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
