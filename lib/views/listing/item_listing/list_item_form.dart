// Updated list_item_form.dart
import 'dart:convert';

import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/controller/add_listing_controller.dart';
import 'package:dedicated_cowboy/views/map/map_select.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:dedicated_cowboy/widgets/textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ListItemForm extends StatelessWidget {
  const ListItemForm({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final ListItemController controller =
        Get.isRegistered<ListItemController>()
            ? Get.find<ListItemController>()
            : Get.put(ListItemController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and search
              Container(
                color: const Color(0xFFF5F5F5),
                child: Row(
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: controller.goBack,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Search Bar
                    Expanded(
                      child: Text(
                        'List An Item',
                        style: Appthemes.textMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: appColors.darkBlueText,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),

              // Item Name Field
              CustomTextField(
                fontSize: 12.sp,
                required: true,
                labelText: 'Item Name',
                hintText: 'turquoise Cuff Bracelet, Fringe Leather Jacket',
                controller: controller.itemNameController,
              ),

              const SizedBox(height: 20),

              // Description Field
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Description',
                hintText: 'Share item detail, features, history etc',
                controller: controller.descriptionController,
                maxLines: 5,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
              ),

              const SizedBox(height: 16),

              // AI Rewrite Section
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Image.asset(
                      'assets/images/question 1.png',
                      width: 30.w,
                      height: 30.h,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Want help writing a better description?\nLet AI rewrite it for you instantly',
                      style: Appthemes.textSmall.copyWith(
                        color: Colors.black87,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Rewrite with AI Button
              SizedBox(
                width: 200.w,
                height: 50.h,
                child: Obx(
                  () => CustomElevatedButton(
                    text: 'Rewrite With AI',
                    backgroundColor: appColors.pYellow,
                    textColor: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    borderRadius: 25.r,
                    isLoading: controller.isAIRewriting.value,
                    onTap: controller.rewriteWithAI,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              FutureBuilder<List<Category>>(
                future: CategoryService.fetchCategories(parentIds: [284, 290]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: const Center(child: LinearProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.red.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          'Error loading categories',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Text('No categories available'),
                      ),
                    );
                  }

                  return CustomMultiSelectField(
                    title: 'Select Category',
                    hint: 'Category',
                    categories: snapshot.data!,
                    selectedCategories: controller.selectedCategories,
                    onSelectionChanged: (selected) {
                      controller.selectCategory(selected);
                    },
                  );
                },
              ),

              // Select Category Dropdown
              const SizedBox(height: 20),

              // // Select Subcategory Dropdown
              // Obx(
              //   () => _buildDropdownField(
              //     controller: controller,
              //     label: 'Select Subcategory',
              //     value: controller.subcategoryValue,
              //     items: controller.subcategories,
              //     onChanged: controller.selectSubcategory,
              //   ),
              // ),
              const SizedBox(height: 10),
              LocationMapWidget(
                controller: controller.locationController,
                googleApiKey:
                    'AIzaSyDIz7irjECc_418w_XfkdzcFuCZaxMNzYg', // Replace with your API key
                height: 400,
              ),

              // // Location Field
              // CustomTextField(
              //   fontSize: 12.sp,
              //   labelText: 'Location / City & State',
              //   hintText: 'City / State',
              //   controller: controller.locationController,
              // ),

              // const SizedBox(height: 20),
              // Image.asset(
              //   'assets/images/WhatsApp Image 2025-06-28 at 14.43.20_262f6e2a 1.png',
              // ),
              const SizedBox(height: 20),

              // Link/Website Field
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Link/Website',
                hintText: 'e.g https://www.377Larena.com',
                controller: controller.linkWebsiteController,
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 20),

              // Upload Photos/Video/Attachments
              _buildUploadSection(controller),

              const SizedBox(height: 20),

              // Size / Dimensions Field
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Size / Dimensions',
                hintText: 'e.g medium / 18"-24" frame / size 8',
                controller: controller.sizeController,
              ),

              const SizedBox(height: 20),

              // Condition Dropdown
              Obx(
                () => _buildDropdownField(
                  controller: controller,
                  label: 'Condition',
                  value: controller.conditionValue,
                  items: controller.conditions,
                  onChanged: controller.selectCondition,
                ),
              ),

              const SizedBox(height: 20),

              // Brand Field
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Brand',
                hintText: 'Wrangler Double D',
                controller: controller.brandController,
              ),

              const SizedBox(height: 20),

              // Price Field
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Price',
                hintText: 'e.g \$5.00',
                controller: controller.priceController,
                keyboardType: TextInputType.number,
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ),

              const SizedBox(height: 20),

              // Shipping info / Pickup Field
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Shipping info / Pickup',
                hintText: 'e.g local pickup in Abilene / will ship for \$10',
                controller: controller.shippingController,
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // Email Field (Required)
              CustomTextField(
                fontSize: 12.sp,
                required: true,
                labelText: 'Email',
                hintText: 'Enter Correct Email',
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ),
              const SizedBox(height: 20),

              // Email Field (Required)
              CustomTextField(
                fontSize: 12.sp,
                required: false,
                labelText: 'Phone Number',
                hintText: '123-456-7890',
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  PhoneNumberFormatter(),
                ], // ✅ Add the formatter here
                prefixIcon: Icon(
                  Icons.call,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ),
              const SizedBox(height: 20),

              // Email Field (Required)
              CustomTextField(
                fontSize: 12.sp,
                required: false,
                labelText: 'Facebook',
                hintText: 'Facebook Profile Link',
                controller: controller.facebookController,
                keyboardType: TextInputType.text,
                prefixIcon: Icon(
                  Icons.face,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ),

              const SizedBox(height: 20),

              // Preferred method of contact
              _buildContactMethodSection(controller),

              const SizedBox(height: 20),

              // Select Payment method
              _buildPaymentMethodSection(controller),

              const SizedBox(height: 20),

              // Paypal Field (conditional)
              Obx(() {
                {
                  return Column(
                    children: [
                      if (controller.selectedPaymentMethod.contains('Paypal'))
                        CustomTextField(
                          fontSize: 12.sp,
                          labelText: 'Paypal',
                          hintText: 'Add your Paypal account number here',
                          controller: controller.paypalController,
                        ),
                      if (controller.selectedPaymentMethod.contains('Paypal'))
                        const SizedBox(height: 20),
                      if (controller.selectedPaymentMethod.contains('VENMO'))
                        CustomTextField(
                          fontSize: 12.sp,
                          labelText: 'VENMO',
                          hintText: 'Add your VENMO account number here',
                          controller: controller.venmoAccountController,
                        ),
                      if (controller.selectedPaymentMethod.contains('VENMO'))
                        const SizedBox(height: 20),
                      if (controller.selectedPaymentMethod.contains('CashApp'))
                        CustomTextField(
                          fontSize: 12.sp,
                          labelText: 'CashApp',
                          hintText: 'Add your CashApp account number here',
                          controller: controller.cashappAccountController,
                        ),
                      if (controller.selectedPaymentMethod.contains('CashApp'))
                        const SizedBox(height: 20),
                    ],
                  );
                }
              }),

              // Other Payment Options Field
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Other Payment Options',
                hintText: 'Add comma to separate other options',
                controller: controller.otherPaymentController,
                maxLines: 2,
              ),

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Obx(
                  () => CustomElevatedButton(
                    text: 'Preview Your Listing',
                    backgroundColor: appColors.pYellow,
                    textColor: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    borderRadius: 20.r,
                    isLoading: controller.isLoading.value,
                    onTap: controller.submitForm,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(ListItemController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment method',
          style: Appthemes.textSmall.copyWith(
            fontFamily: 'popins-bold',
            color: const Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildRadioOption(
                      controller.paymentMethods[0], // Paypal
                      controller.selectedPaymentMethod.contains(
                        controller.paymentMethods[0],
                      ),

                      () => controller.selectPaymentMethod(
                        controller.paymentMethods[0],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildRadioOption(
                      controller.paymentMethods[2], // VENMO
                      controller.selectedPaymentMethod.contains(
                        controller.paymentMethods[2],
                      ),
                      () => controller.selectPaymentMethod(
                        controller.paymentMethods[2],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRadioOption(
                      controller.paymentMethods[1], // Cash
                      controller.selectedPaymentMethod.contains(
                        controller.paymentMethods[1],
                      ),
                      () => controller.selectPaymentMethod(
                        controller.paymentMethods[1],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildRadioOption(
                      controller.paymentMethods[3], // Credit Card
                      controller.selectedPaymentMethod.contains(
                        controller.paymentMethods[3],
                      ),
                      () => controller.selectPaymentMethod(
                        controller.paymentMethods[3],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required ListItemController controller,
    required String label,
    bool isRequired = false,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: Appthemes.textSmall.copyWith(
                  fontFamily: 'popins-bold',
                  color: const Color(0xFF424242),
                ),
              ),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: Appthemes.textSmall.copyWith(
                    fontFamily: 'popins-bold',
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            dropdownColor: appColors.white,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            hint: Text(
              value ??
                  (items.isNotEmpty
                      ? items.first
                      : 'Select ${label.toLowerCase()}'),
              style: Appthemes.textSmall.copyWith(
                color: Color(0xFF9E9E9E),
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF9E9E9E),
            ),
            items:
                items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: Appthemes.textSmall.copyWith(
                        fontSize: 13.sp,
                        color: const Color(0xFF212121),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
            onChanged: onChanged,
            validator:
                isRequired
                    ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a $label';
                      }
                      return null;
                    }
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildContactMethodSection(ListItemController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred method of contact',
          style: Appthemes.textSmall.copyWith(
            fontFamily: 'popins-bold',
            color: const Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildRadioOption(
                      controller.contactMethods[0], // Text
                      controller.selectedContactMethod.value ==
                          controller.contactMethods[0],
                      () => controller.selectContactMethod(
                        controller.contactMethods[0],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildRadioOption(
                      controller.contactMethods[2], // Messenger
                      controller.selectedContactMethod.value ==
                          controller.contactMethods[2],
                      () => controller.selectContactMethod(
                        controller.contactMethods[2],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildRadioOption(
                      controller.contactMethods[1], // Call
                      controller.selectedContactMethod.value ==
                          controller.contactMethods[1],
                      () => controller.selectContactMethod(
                        controller.contactMethods[1],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildRadioOption(
                      controller.contactMethods[3], // Email
                      controller.selectedContactMethod.value ==
                          controller.contactMethods[3],
                      () => controller.selectContactMethod(
                        controller.contactMethods[3],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
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
          Flexible(
            child: Text(
              label,
              style: Appthemes.textSmall.copyWith(
                color: const Color(0xFF424242),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated _buildUploadSection method for the ListItemForm
  Widget _buildUploadSection(ListItemController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Upload Photos/Video/Attachments',
              style: Appthemes.textSmall.copyWith(
                fontFamily: 'popins-bold',
                color: const Color(0xFF424242),
              ),
            ),
            Text(
              ' *',
              style: Appthemes.textSmall.copyWith(
                color: Colors.red,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: controller.uploadFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add Images, Videos, Documents',
                  style: Appthemes.textSmall.copyWith(
                    color: const Color(0xFF9E9E9E),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Display uploaded content
        Obx(() {
          final hasImages = controller.imageUploadStatuses.isNotEmpty;
          final hasVideos = controller.videoUploadStatuses.isNotEmpty;
          final hasAttachments = controller.attachmentUploadStatuses.isNotEmpty;

          if (!hasImages && !hasVideos && !hasAttachments) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Images Section
                if (hasImages) ...[
                  Text(
                    'Images (${controller.imageUploadStatuses.length})',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                    itemCount: controller.imageUploadStatuses.length,
                    itemBuilder: (context, index) {
                      final imageFile = controller.imageUploadStatuses[index];
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    imageFile.isUploaded
                                        ? Color(0xFFF2B342)
                                        : imageFile.isUploading
                                        ? Colors.orange
                                        : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Stack(
                                children: [
                                  Image.file(
                                    imageFile.file,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey.shade400,
                                          size: 30,
                                        ),
                                      );
                                    },
                                  ),
                                  if (imageFile.isUploading)
                                    Container(
                                      color: Colors.black.withOpacity(0.5),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  if (imageFile.error != null)
                                    Container(
                                      color: Colors.red.withOpacity(0.5),
                                      child: const Center(
                                        child: Icon(
                                          Icons.error,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => controller.removeImage(imageFile),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Videos Section
                if (hasVideos) ...[
                  Text(
                    'Videos (${controller.videoUploadStatuses.length})',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E50),
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
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                videoFile.isUploaded
                                    ? Color(0xFFF2B342)
                                    : videoFile.isUploading
                                    ? Colors.orange
                                    : Colors.red,
                            width: 1,
                          ),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    videoFile.file.path.split('/').last,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    videoFile.isUploaded
                                        ? 'Uploaded'
                                        : videoFile.isUploading
                                        ? 'Uploading...'
                                        : 'Failed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          videoFile.isUploaded
                                              ? Color(0xFFF2B342)
                                              : videoFile.isUploading
                                              ? Colors.orange
                                              : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (videoFile.isUploading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              IconButton(
                                onPressed:
                                    () => controller.removeVideo(videoFile),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
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
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E50),
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
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                attachmentFile.isUploaded
                                    ? Color(0xFFF2B342)
                                    : attachmentFile.isUploading
                                    ? Colors.orange
                                    : Colors.red,
                            width: 1,
                          ),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    attachmentFile.file.path.split('/').last,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    attachmentFile.isUploaded
                                        ? 'Uploaded'
                                        : attachmentFile.isUploading
                                        ? 'Uploading...'
                                        : 'Failed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          attachmentFile.isUploaded
                                              ? Color(0xFFF2B342)
                                              : attachmentFile.isUploading
                                              ? Colors.orange
                                              : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (attachmentFile.isUploading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              IconButton(
                                onPressed:
                                    () => controller.removeAttachment(
                                      attachmentFile,
                                    ),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

// Category Model
class Category {
  final int id;
  final String name;
  final int parent;

  Category({required this.id, required this.name, required this.parent});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      parent: json['parent'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'parent': parent};
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, parent: $parent}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Updated CustomMultiSelectField to work with Category objects
class CustomMultiSelectField extends StatefulWidget {
  final List<Category> categories;
  final List<Category> selectedCategories;
  final Function(List<Category>) onSelectionChanged;
  final String title;
  final String hint;

  const CustomMultiSelectField({
    Key? key,
    required this.categories,
    required this.selectedCategories,
    required this.onSelectionChanged,
    this.title = "Business Category",
    this.hint = "Select categories",
  }) : super(key: key);

  @override
  State<CustomMultiSelectField> createState() => _CustomMultiSelectFieldState();
}

class _CustomMultiSelectFieldState extends State<CustomMultiSelectField> {
  bool _isExpanded = false;
  List<Category> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);
  }

  @override
  void didUpdateWidget(CustomMultiSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategories != oldWidget.selectedCategories) {
      _selectedCategories = List.from(widget.selectedCategories);
    }
  }

  void _toggleSelection(Category category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
    widget.onSelectionChanged(_selectedCategories);
  }

  void _removeCategory(Category category) {
    setState(() {
      _selectedCategories.remove(category);
    });
    widget.onSelectionChanged(_selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with asterisk
        RichText(
          text: TextSpan(
            text: widget.title,
            style: Appthemes.textSmall.copyWith(
              fontFamily: 'popins-bold',
              color: Color(0xFF424242),
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Main container
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Selected categories chips section
              if (_selectedCategories.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _selectedCategories.map((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _removeCategory(category),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),

              // Dropdown trigger
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border:
                        _selectedCategories.isNotEmpty
                            ? Border(
                              top: BorderSide(color: const Color(0xFFE0E0E0)),
                            )
                            : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategories.isEmpty
                            ? widget.hint
                            : "Select more categories",
                        style: Appthemes.textMedium.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 12.sp,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),

              // Dropdown list
              if (_isExpanded)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.categories.length,
                    itemBuilder: (context, index) {
                      final category = widget.categories[index];
                      final isSelected = _selectedCategories.contains(category);

                      return ListTile(
                        dense: true,
                        title: Text(
                          category.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.blue,
                                  size: 20,
                                )
                                : null,
                        onTap: () => _toggleSelection(category),
                        tileColor:
                            isSelected
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.transparent,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class CategoryService {
  static const String baseUrl =
      'https://dedicatedcowboy.com/wp-json/wp/v2/at_biz_dir-category?per_page=100';

  static Future<List<Category>> fetchCategories({List<int>? parentIds}) async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        List<Category> allCategories = parseCategoriesFromJson(jsonData);

        // If parentIds are provided, filter by those parent IDs
        if (parentIds != null && parentIds.isNotEmpty) {
          return allCategories
              .where((category) => parentIds.contains(category.parent))
              .toList();
        }

        return allCategories;
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }
}

List<Category> parseCategoriesFromJson(List<dynamic> jsonList) {
  return jsonList.map((json) => Category.fromJson(json)).toList();
}
