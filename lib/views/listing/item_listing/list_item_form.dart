// Updated list_item_form.dart
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/controller/add_listing_controller.dart';
import 'package:dedicated_cowboy/views/map/map_select.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:dedicated_cowboy/widgets/textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ListItemForm extends StatelessWidget {
  const ListItemForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final ListItemController controller = Get.find<ListItemController>();

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
                hintText: 'Regulation Grill Brushes',
                controller: controller.itemNameController,
              ),

              const SizedBox(height: 20),

              // Description Field
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Description',
                hintText: 'Ebay Item Online features Knotty, etc...',
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

              // Select Category Dropdown
              Obx(
                () => _buildDropdownField(
                  controller: controller,
                  label: 'Select Category',
                  isRequired: true,
                  value: controller.categoryValue,
                  items: controller.categories,
                  onChanged: controller.selectCategory,
                ),
              ),

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
                hintText: 'e.g www.377arena.com',
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
                hintText: 'e.g what brand is your seat-wrangler, Double C',
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
                hintText: 'Email Address',
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
                hintText: 'Phone Number',
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
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
                hintText: 'Facebook page',
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
                if (controller.selectedPaymentMethod.value == 'Paypal') {
                  return Column(
                    children: [
                      CustomTextField(
                        fontSize: 12.sp,
                        labelText: 'Paypal',
                        hintText: 'Add your Paypal account number here',
                        controller: controller.paypalController,
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),

              // Other Payment Options Field
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Other Payment Options',
                hintText: 'Add Zelle up to separate other options',
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
                      controller.selectedPaymentMethod.value ==
                          controller.paymentMethods[0],
                      () => controller.selectPaymentMethod(
                        controller.paymentMethods[0],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildRadioOption(
                      controller.paymentMethods[2], // VENMO
                      controller.selectedPaymentMethod.value ==
                          controller.paymentMethods[2],
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
                      controller.selectedPaymentMethod.value ==
                          controller.paymentMethods[1],
                      () => controller.selectPaymentMethod(
                        controller.paymentMethods[1],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildRadioOption(
                      controller.paymentMethods[3], // Credit Card
                      controller.selectedPaymentMethod.value ==
                          controller.paymentMethods[3],
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
        Text(
          'Upload Photos/Video/Attachments',
          style: Appthemes.textSmall.copyWith(
            fontFamily: 'popins-bold',
            color: const Color(0xFF424242),
          ),
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
                Icon(Icons.attach_file, color: Colors.grey.shade500, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Add PNG,JPG,MP4,DOC',
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

        // Display uploaded images with preview
        Obx(() {
          if (controller.imageUploadStatuses.isNotEmpty) {
            return Container(
              margin: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  // Image count indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${controller.imageUploadStatuses.length} image(s) selected',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFF3B340),
                      ),
                    ),
                  ),

                  // Grid of images
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
                          // Image preview
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.file(
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
                            ),
                          ),

                          // Remove button
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
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}
