// Updated list_item_form.dart
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/views/listing/events_listings/controller/add_listing_controller.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/list_item_form.dart';
import 'package:dedicated_cowboy/views/map/map_select.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:dedicated_cowboy/widgets/textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ListEventForm extends StatelessWidget {
  const ListEventForm({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final ListEventController controller =
        Get.isRegistered<ListEventController>()
            ? Get.find<ListEventController>()
            : Get.put(ListEventController());

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
                        'List An Event',
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
                labelText: 'Event Name',
                hintText: 'eg.. Cowboy Christams Bash',
                controller: controller.itemNameController,
              ),

              const SizedBox(height: 20),

              // Description Field
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Description',
                hintText:
                    "what's this event all about? include details, headliners, etc",
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
              CustomMultiSelectField(
                title: 'Select Event Category',
                hint: 'Category',
                items: controller.categories,
                selectedItems: controller.selectedCategories,
                onSelectionChanged: (selected) {
                  controller.selectCategory(selected);
                },
              ),
              const SizedBox(height: 20),

              // Select Subcategory Dropdown
              // Obx(
              //   () => _buildDropdownField(
              //     controller: controller,
              //     label: 'Select Subcategory',
              //     value: controller.subcategoryValue,
              //     items: controller.subcategories,
              //     onChanged: controller.selectSubcategory,
              //   ),
              // ),
              const SizedBox(height: 20),

              // Location Field
              LocationMapWidget(
                controller: controller.locationController,
                googleApiKey: 'AIzaSyDIz7irjECc_418w_XfkdzcFuCZaxMNzYg',
                height: 400,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Event Website / Registration Link:',
                hintText: 'add a link to buy tickets or RSVP',
                controller: controller.linkWebsiteController,
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 20),

              // Link/Website Field
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Facebook Event or Social Link:',
                hintText: 'paste your events facebook link if it has one',
                controller: controller.facebookController,
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 20),
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Event Start Date',
                hintText: 'dd/MM/yyyy',
                controller: controller.startDateController,
                readOnly: true,
                required: true,
                onTap: () => controller.pickStartDate(context),

                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 20),
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Event End Date',
                hintText: 'dd/MM/yyyy',
                readOnly: true,
                required: true,
                onTap: () => controller.pickEndDate(context),
                controller: controller.endDateController,

                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 20),

              // Upload Photos/Video/Attachments
              _buildUploadSection(controller),

              const SizedBox(height: 20),
              CustomTextField(
                fontSize: 12.sp,
                labelText: 'Contact information',
                hintText: 'e.g john smith , (325) 555-5555',
                controller: controller.contactController,

                keyboardType: TextInputType.url,
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

  // Updated _buildUploadSection method for the ListItemForm
  Widget _buildUploadSection(ListEventController controller) {
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
