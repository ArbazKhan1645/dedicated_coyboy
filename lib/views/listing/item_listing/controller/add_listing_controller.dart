// add_listing_controller.dart

import 'package:dedicated_cowboy/app/models/modules_models/item_model.dart';
import 'package:dedicated_cowboy/app/services/listings_service.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/subcriptions_view.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/subscription_service.dart';
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/listing_item_preview_screen.dart';
import 'package:dedicated_cowboy/views/my_listings/my_listings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ImageUploadStatus {
  final File file;
  final bool isUploading;
  final bool isUploaded;
  final String? uploadedUrl;
  final String? error;

  ImageUploadStatus({
    required this.file,
    this.isUploading = false,
    this.isUploaded = false,
    this.uploadedUrl,
    this.error,
  });

  ImageUploadStatus copyWith({
    File? file,
    bool? isUploading,
    bool? isUploaded,
    String? uploadedUrl,
    String? error,
  }) {
    return ImageUploadStatus(
      file: file ?? this.file,
      isUploading: isUploading ?? this.isUploading,
      isUploaded: isUploaded ?? this.isUploaded,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      error: error ?? this.error,
    );
  }
}

class ListItemController extends GetxController {
  final RxBool isEditMode = false.obs;
  final RxString existingItemId = RxString('');
  ItemListing? existingItem;
  void _checkEditMode() {
    try {
      final arguments = Get.arguments;
      if (arguments != null && arguments is ItemListing) {
        isEditMode.value = true;
        existingItem = arguments;
        existingItemId.value = existingItem?.id ?? '';
        _loadExistingItemData();
      }
    } catch (e) {
      _handleError('Failed to check edit mode', e);
    }
  }

  void _loadExistingItemData() {
    try {
      if (existingItem == null) return;

      // Populate form fields with existing data
      itemNameController.text = existingItem!.itemName ?? '';
      descriptionController.text = existingItem!.description ?? '';
      locationController.text =
          existingItem!.cityState.toString().isNotEmpty
              ? '${existingItem!.latitude},${existingItem!.longitude},${existingItem!.cityState}'
              : '${existingItem!.latitude},${existingItem!.longitude}';
      linkWebsiteController.text = existingItem!.linkWebsite ?? '';
      sizeController.text = existingItem!.sizeDimensions ?? '';
      brandController.text = existingItem!.brand ?? '';
      priceController.text = existingItem!.price.toString();
      shippingController.text = existingItem!.shippingInfo ?? '';
      emailController.text = existingItem!.email ?? '';
      paypalController.text = existingItem!.paypalAccount ?? '';
      otherPaymentController.text = existingItem!.otherPaymentOptions ?? '';
      facebookController.text = existingItem!.facebookPage ?? '';
      phoneController.text = existingItem!.phoneNumber ?? '';
      cashappAccountController.text = existingItem!.cashappAccount ?? '';
      venmoAccountController.text = existingItem!.venmoAccount ?? '';

      // Set selected values
      selectedCategories.value = List<String>.from(
        existingItem!.category ?? [],
      );
      selectedCondition.value = existingItem!.condition ?? '';
      selectedContactMethod.value = existingItem!.preferredContactMethod ?? '';
      selectedPaymentMethod.value = List<String>.from(
        existingItem!.paymentMethod ?? [],
      );

      // Load existing images
      if ((existingItem!.photoUrls ?? []).isNotEmpty) {
        for (var url in existingItem!.photoUrls!) {
          imageUploadStatuses.add(
            ImageUploadStatus(
              file: File(''), // Empty file since it's already uploaded
              isUploading: false,
              isUploaded: true,
              uploadedUrl: url,
            ),
          );
        }
      }

      // Load existing videos
      if (existingItem!.videoUrls != null &&
          existingItem!.videoUrls!.isNotEmpty) {
        for (var url in existingItem!.videoUrls!) {
          videoUploadStatuses.add(
            ImageUploadStatus(
              file: File(''),
              isUploading: false,
              isUploaded: true,
              uploadedUrl: url,
            ),
          );
        }
      }

      // Load existing attachments
      if (existingItem!.attachmentUrls != null &&
          existingItem!.attachmentUrls!.isNotEmpty) {
        for (var url in existingItem!.attachmentUrls!) {
          attachmentUploadStatuses.add(
            ImageUploadStatus(
              file: File(''),
              isUploading: false,
              isUploaded: true,
              uploadedUrl: url,
            ),
          );
        }
      }

      update();
    } catch (e) {
      _handleError('Failed to load existing item data', e);
    }
  }

  final RxList<ImageUploadStatus> videoUploadStatuses =
      <ImageUploadStatus>[].obs;
  final RxList<ImageUploadStatus> attachmentUploadStatuses =
      <ImageUploadStatus>[].obs;

  final FirebaseServices _firebaseServices = FirebaseServices();

  // Text Controllers
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController linkWebsiteController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController shippingController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController paypalController = TextEditingController();
  final TextEditingController otherPaymentController = TextEditingController();
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cashappAccountController =
      TextEditingController();
  final TextEditingController venmoAccountController = TextEditingController();

  // Observable variables
  // Reactive list of strings
  final RxList<String> selectedCategories = <String>[].obs;
  final RxString selectedSubcategory = RxString('');
  final RxString selectedCondition = RxString('');
  final RxString selectedContactMethod = RxString('');
  final RxList<String> selectedPaymentMethod = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isAIRewriting = false.obs;
  final RxBool isPublishing = false.obs;
  final RxList<ImageUploadStatus> imageUploadStatuses =
      <ImageUploadStatus>[].obs;

  // Connectivity and timeout management
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final int _uploadTimeoutSeconds = 30;
  final int _maxRetries = 3;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Static data lists
  List<String> categories = [];

  final List<String> subcategories = [];
  final List<String> conditions = ['New', 'Used', 'Vintage'];
  final List<String> contactMethods = ['Text', 'Call', 'Messenger', 'Email'];
  final List<String> paymentMethods = [
    'Paypal',
    'CashApp',
    'VENMO',
    'Credit Card',
  ];

  fetchCategories() {
    var list1 = categoriesStatic['Home & Ranch Decor'] as List<String>;
    var list2 = categoriesStatic['Tack & Live Stock'] as List<String>;
    var list3 = categoriesStatic['Western Style'] as List<String>;
    categories = [...list1, ...list2, ...list3];
  }

  // Getters for better access
  List<String>? get categoryValue =>
      selectedCategories.isEmpty ? null : selectedCategories;
  String? get subcategoryValue =>
      selectedSubcategory.value.isEmpty ? null : selectedSubcategory.value;
  String? get conditionValue =>
      selectedCondition.value.isEmpty ? null : selectedCondition.value;
  String? get contactMethodValue =>
      selectedContactMethod.value.isEmpty ? null : selectedContactMethod.value;

  // Check if all images are uploaded
  bool get areAllImagesUploaded => imageUploadStatuses.every(
    (status) => status.isUploaded && status.uploadedUrl != null,
  );

  // Check if any image is currently uploading
  bool get hasUploadingImages =>
      imageUploadStatuses.any((status) => status.isUploading);

  @override
  void onInit() {
    super.onInit();

    fetchCategories();

    _initializeData();
    _setupConnectivityListener();
    _checkEditMode();
  }

  @override
  void onClose() {
    _disposeResources();
    super.onClose();
  }

  // Initialize data and connectivity
  void _initializeData() {
    try {
      // Pre-fill form data if needed
      _checkInitialConnectivity();
    } catch (e) {
      _handleError('Failed to initialize data', e);
    }
  }

  // Setup connectivity listener
  void _setupConnectivityListener() {
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> result) {
          _handleConnectivityChange(result);
        },
        onError: (error) {
          _handleError('Connectivity monitoring error', error);
        },
      );
    } catch (e) {
      _handleError('Failed to setup connectivity listener', e);
    }
  }

  // Check initial connectivity
  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _handleConnectivityChange(result);
    } catch (e) {
      _handleError('Failed to check initial connectivity', e);
    }
  }

  // Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none)) {
      _showWarningSnackbar(
        'No internet connection',
        'Please check your network settings',
      );
    }
  }

  // Dispose resources
  void _disposeResources() {
    try {
      // Dispose controllers
      itemNameController.dispose();
      descriptionController.dispose();
      locationController.dispose();
      searchController.dispose();
      linkWebsiteController.dispose();
      sizeController.dispose();
      brandController.dispose();
      priceController.dispose();
      shippingController.dispose();
      emailController.dispose();
      paypalController.dispose();
      otherPaymentController.dispose();
      facebookController.dispose();
      phoneController.dispose();

      // Cancel connectivity subscription
      _connectivitySubscription?.cancel();
    } catch (e) {
      print('Error disposing resources: $e');
    }
  }

  // Selection methods with error handling
  void selectCategory(List<String>? category) {
    try {
      if (category == null) return;

      selectedCategories.value = category.toSet().toList();

      selectedSubcategory.value = '';
      update();
    } catch (e) {
      _handleError('Failed to select category', e);
    }
  }

  void selectSubcategory(String? subcategory) {
    try {
      selectedSubcategory.value = subcategory ?? '';
      update();
    } catch (e) {
      _handleError('Failed to select subcategory', e);
    }
  }

  void selectCondition(String? condition) {
    try {
      selectedCondition.value = condition ?? '';
      update();
    } catch (e) {
      _handleError('Failed to select condition', e);
    }
  }

  void selectContactMethod(String? method) {
    try {
      selectedContactMethod.value = method ?? '';
      update();
    } catch (e) {
      _handleError('Failed to select contact method', e);
    }
  }

  void selectPaymentMethod(String? method) {
    try {
      if (selectedPaymentMethod.contains(method)) {
        selectedPaymentMethod.remove(method);
      } else {
        selectedPaymentMethod.add(method ?? '');
      }

      update();
    } catch (e) {
      _handleError('Failed to select payment method', e);
    }
  }

  removePaymentMethod(String method) {
    try {
      selectedPaymentMethod.remove(method);
      update();
    } catch (e) {
      _handleError('Failed to remove payment method', e);
    }
  }

  // Search functionality
  void onSearchChanged(String value) {
    try {
      print('Search query: $value');
      // Add search logic here if needed
    } catch (e) {
      _handleError('Search error', e);
    }
  }

  // Check internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      _handleError('Failed to check internet connection', e);
      return false;
    }
  }

  // File upload functionality with bottom sheet
  Future<void> uploadFiles() async {
    try {
      if (!await _hasInternetConnection()) {
        _showErrorSnackbar(
          'No Internet Connection',
          'Please check your network and try again',
        );
        return;
      }

      await Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Media Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 20),

              // Images Section
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        _showImageSourceOptions();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: appColors.darkBlue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: appColors.darkBlue),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.image,
                              size: 30,
                              color: appColors.darkBlue,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Images',
                              style: TextStyle(
                                color: appColors.darkBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Videos
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        _pickVideos();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: appColors.darkBlue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: appColors.darkBlue),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.videocam,
                              size: 30,
                              color: appColors.darkBlue,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Videos',
                              style: TextStyle(
                                color: appColors.darkBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Attachments
              GestureDetector(
                onTap: () {
                  Get.back();
                  _pickAttachments();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: appColors.darkBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: appColors.darkBlue),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 30,
                        color: Color.fromARGB(255, 1, 60, 148),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Documents/Attachments',
                        style: TextStyle(
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
      );
    } catch (e) {
      _handleError('Failed to show upload options', e);
    }
  }

  // Show image source options (camera/gallery)
  Future<void> _showImageSourceOptions() async {
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                      _pickFromCamera();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: appColors.darkBlue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: appColors.darkBlue),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 30,
                            color: appColors.darkBlue,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Camera',
                            style: TextStyle(
                              color: Color(0xFF2C3E50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                      _pickFromGallery();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: appColors.darkBlue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2C3E50)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library,
                            size: 30,
                            color: appColors.darkBlue,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Gallery',
                            style: TextStyle(
                              color: appColors.darkBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  // Pick videos from gallery
  Future<void> _pickVideos() async {
    if (videoUploadStatuses.length == 1) {
      _showErrorSnackbar('Limit Reached', 'Only 1 video allowed to upload');
      return;
    }
    try {
      if (!await _hasInternetConnection()) {
        _showErrorSnackbar(
          'No Internet Connection',
          'Please connect to internet to upload video',
        );
        return;
      }

      final XFile? video = await _picker
          .pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(
              minutes: 10,
            ), // optional: restrict duration
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException('Video selection timeout'),
          );

      if (video != null) {
        final extension = video.path.toLowerCase();
        if (extension.endsWith('.mp4') ||
            extension.endsWith('.mov') ||
            extension.endsWith('.avi') ||
            extension.endsWith('.mkv')) {
          _showSuccessSnackbar('Video Selected', 'Uploading selected video...');

          final file = File(video.path);
          if (await file.exists()) {
            await _processAndUploadVideo(file);
          }
        } else {
          _showWarningSnackbar('Invalid File', 'Please select a valid video');
        }
      } else {
        _showWarningSnackbar('No Video', 'No video file was selected');
      }
    } catch (e) {
      _handleError('Failed to select video', e);
    }
  }

  // Pick attachments/documents
  Future<void> _pickAttachments() async {
    try {
      if (attachmentUploadStatuses.length == 2) {
        _showErrorSnackbar(
          'Limit Reached',
          'Only 2 attachment allowed to upload',
        );
        return;
      }
      if (!await _hasInternetConnection()) {
        _showErrorSnackbar(
          'No Internet Connection',
          'Please connect to internet to upload attachments',
        );
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null) {
        _showSuccessSnackbar(
          'Attachments Selected',
          '${result.files.length} attachment(s) selected. Uploading...',
        );

        for (PlatformFile attachment in result.files) {
          final file = File(attachment.path!);
          if (await file.exists()) {
            await _processAndUploadAttachment(file);
          }
        }
      }
    } catch (e) {
      _handleError('Failed to select attachments', e);
    }
  }

  Future<void> _processAndUploadVideo(File file) async {
    try {
      final uploadStatus = ImageUploadStatus(file: file, isUploading: true);
      videoUploadStatuses.add(uploadStatus);

      final index = videoUploadStatuses.length - 1;
      final uploadedUrl = await _uploadImageWithRetry(file);

      videoUploadStatuses[index] = uploadStatus.copyWith(
        isUploading: false,
        isUploaded: true,
        uploadedUrl: uploadedUrl,
      );

      _showSuccessSnackbar('Upload Success', 'Video uploaded successfully');
    } catch (e) {
      final index = videoUploadStatuses.indexWhere(
        (status) => status.file.path == file.path,
      );
      if (index != -1) {
        videoUploadStatuses[index] = videoUploadStatuses[index].copyWith(
          isUploading: false,
          isUploaded: false,
          error: e.toString(),
        );
      }
      _handleError('Video upload failed', e);
    }
  }

  // Process and upload attachment
  Future<void> _processAndUploadAttachment(File file) async {
    try {
      final uploadStatus = ImageUploadStatus(file: file, isUploading: true);
      attachmentUploadStatuses.add(uploadStatus);

      final index = attachmentUploadStatuses.length - 1;
      final uploadedUrl = await _uploadImageWithRetry(file);

      attachmentUploadStatuses[index] = uploadStatus.copyWith(
        isUploading: false,
        isUploaded: true,
        uploadedUrl: uploadedUrl,
      );

      _showSuccessSnackbar(
        'Upload Success',
        'Attachment uploaded successfully',
      );
    } catch (e) {
      final index = attachmentUploadStatuses.indexWhere(
        (status) => status.file.path == file.path,
      );
      if (index != -1) {
        attachmentUploadStatuses[index] = attachmentUploadStatuses[index]
            .copyWith(
              isUploading: false,
              isUploaded: false,
              error: e.toString(),
            );
      }
      _handleError('Attachment upload failed', e);
    }
  }

  // Remove video
  void removeVideo(ImageUploadStatus videoStatus) {
    try {
      videoUploadStatuses.remove(videoStatus);
      _showSuccessSnackbar('Video Removed', 'Video removed successfully');
    } catch (e) {
      _handleError('Failed to remove video', e);
    }
  }

  // Remove attachment
  void removeAttachment(ImageUploadStatus attachmentStatus) {
    try {
      attachmentUploadStatuses.remove(attachmentStatus);
      _showSuccessSnackbar(
        'Attachment Removed',
        'Attachment removed successfully',
      );
    } catch (e) {
      _handleError('Failed to remove attachment', e);
    }
  }

  // Pick single image from camera
  Future<void> _pickFromCamera() async {
    try {
      if (!await _hasInternetConnection()) {
        _showErrorSnackbar(
          'No Internet Connection',
          'Please connect to internet to upload images',
        );
        return;
      }

      final XFile? image = await _picker
          .pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
            maxWidth: 1920,
            maxHeight: 1080,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Camera timeout'),
          );

      if (image != null) {
        final file = File(image.path);
        if (await file.exists()) {
          await _processAndUploadImage(file);
        } else {
          _showErrorSnackbar('File Error', 'Selected image file not found');
        }
      }
    } on TimeoutException {
      _showErrorSnackbar('Timeout', 'Camera operation timed out');
    } catch (e) {
      _handleError('Failed to capture image', e);
    }
  }

  // Pick multiple images from gallery
  Future<void> _pickFromGallery() async {
    try {
      if (!await _hasInternetConnection()) {
        _showErrorSnackbar(
          'No Internet Connection',
          'Please connect to internet to upload images',
        );
        return;
      }

      final List<XFile> images = await _picker
          .pickMultiImage(imageQuality: 80, maxWidth: 1920, maxHeight: 1080)
          .timeout(
            const Duration(seconds: 60),
            onTimeout:
                () => throw TimeoutException('Gallery selection timeout'),
          );

      if (images.isNotEmpty) {
        _showSuccessSnackbar(
          'Images Selected',
          '${images.length} image(s) selected. Uploading...',
        );

        for (XFile image in images) {
          final file = File(image.path);
          if (await file.exists()) {
            await _processAndUploadImage(file);
          } else {
            _showWarningSnackbar(
              'File Not Found',
              'One or more selected images could not be found',
            );
          }
        }
      }
    } on TimeoutException {
      _showErrorSnackbar('Timeout', 'Gallery selection timed out');
    } catch (e) {
      _handleError('Failed to select images', e);
    }
  }

  // Process and upload image with progress tracking
  Future<void> _processAndUploadImage(File file) async {
    try {
      // Add image with uploading status
      final uploadStatus = ImageUploadStatus(file: file, isUploading: true);
      imageUploadStatuses.add(uploadStatus);

      // Show progress for this specific image
      final index = imageUploadStatuses.length - 1;

      // Upload image to API
      final uploadedUrl = await _uploadImageWithRetry(file);

      // Update status with uploaded URL
      imageUploadStatuses[index] = uploadStatus.copyWith(
        isUploading: false,
        isUploaded: true,
        uploadedUrl: uploadedUrl,
      );

      _showSuccessSnackbar('Upload Success', 'Image uploaded successfully');
    } catch (e) {
      // Update status with error
      final index = imageUploadStatuses.indexWhere(
        (status) => status.file.path == file.path,
      );
      if (index != -1) {
        imageUploadStatuses[index] = imageUploadStatuses[index].copyWith(
          isUploading: false,
          isUploaded: false,
          error: e.toString(),
        );
      }

      _handleError('Image upload failed', e);
    }
  }

  // Upload image with retry mechanism
  Future<String> _uploadImageWithRetry(File file, {int retryCount = 0}) async {
    try {
      return await uploadMedia([file]).timeout(
        Duration(seconds: _uploadTimeoutSeconds),
        onTimeout: () => throw TimeoutException('Upload timeout'),
      );
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return await _uploadImageWithRetry(file, retryCount: retryCount + 1);
      } else {
        throw Exception('Upload failed after $_maxRetries attempts: Timeout');
      }
    } on SocketException {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return await _uploadImageWithRetry(file, retryCount: retryCount + 1);
      } else {
        throw Exception(
          'Upload failed after $_maxRetries attempts: Network error',
        );
      }
    } catch (e) {
      if (retryCount < _maxRetries &&
          (e.toString().contains('Failed to upload media') ||
              e.toString().contains('Connection'))) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return await _uploadImageWithRetry(file, retryCount: retryCount + 1);
      } else {
        rethrow;
      }
    }
  }

  // API Upload Media function
  Future<String> uploadMedia(
    List<File> files, {
    String? directory,
    int? width,
    int? height,
  }) async {
    try {
      if (!await _hasInternetConnection()) {
        throw Exception('No internet connection available');
      }

      var uri = Uri.parse('https://api.tjara.com/api/media/insert');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'X-Request-From': 'Application',
        'Accept': 'application/json',
      });

      // Add media files with validation
      for (var file in files) {
        if (!await file.exists()) {
          throw Exception('File does not exist: ${file.path}');
        }

        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('File is empty: ${file.path}');
        }

        // Check file size (max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          throw Exception(
            'File too large (max 10MB): ${path.basename(file.path)}',
          );
        }

        var stream = http.ByteStream(file.openRead());
        var multipartFile = http.MultipartFile(
          'media[]',
          stream,
          fileSize,
          filename: path.basename(file.path),
        );

        request.files.add(multipartFile);
      }

      // Add optional parameters
      if (directory != null) request.fields['directory'] = directory;
      if (width != null) request.fields['width'] = width.toString();
      if (height != null) request.fields['height'] = height.toString();

      // Send request
      var response = await request.send();

      // Handle redirects
      if (response.statusCode == 302 || response.statusCode == 301) {
        var redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          return await uploadMedia(
            files,
            directory: directory,
            width: width,
            height: height,
          );
        }
      }

      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseBody);

        if (jsonData['media'] != null &&
            jsonData['media'].isNotEmpty &&
            jsonData['media'][0]['url'] != null) {
          return jsonData['media'][0]['url'];
        } else {
          throw Exception('Invalid response format: Missing media URL');
        }
      } else {
        throw Exception(
          'Upload failed. Status: ${response.statusCode}, Body: $responseBody',
        );
      }
    } on FormatException catch (e) {
      throw Exception('Invalid JSON response: ${e.message}');
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Upload timeout');
    } catch (e) {
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  // Remove uploaded image
  void removeImage(ImageUploadStatus imageStatus) {
    try {
      imageUploadStatuses.remove(imageStatus);
      _showSuccessSnackbar('Image Removed', 'Image removed successfully');
    } catch (e) {
      _handleError('Failed to remove image', e);
    }
  }

  // AI Rewrite functionality
  Future<void> rewriteWithAI() async {
    if (descriptionController.text.trim().isEmpty) {
      _showErrorSnackbar('Input Required', 'Please enter a description first');
      return;
    }

    try {
      isAIRewriting.value = true;

      if (!await _hasInternetConnection()) {
        throw Exception('No internet connection for AI rewrite');
      }

      // Simulate AI processing with timeout
      await Future.delayed(const Duration(seconds: 2)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('AI rewrite timeout'),
      );

      String originalDescription = descriptionController.text;
      String enhancedDescription = _enhanceDescription(originalDescription);

      descriptionController.text = enhancedDescription;

      _showSuccessSnackbar(
        'AI Rewrite Complete',
        'Description enhanced successfully!',
      );
    } on TimeoutException {
      _showErrorSnackbar('Timeout', 'AI rewrite timed out. Please try again.');
    } catch (e) {
      _handleError('AI rewrite failed', e);
    } finally {
      isAIRewriting.value = false;
    }
  }

  // Enhanced description with better formatting
  String _enhanceDescription(String original) {
    try {
      return "Enhanced: $original - High-quality item with excellent features, perfect condition, and great value for money.";
    } catch (e) {
      return original; // Fallback to original if enhancement fails
    }
  }

  // Comprehensive form validation
  bool validateForm() {
    try {
      if (itemNameController.text.trim().isEmpty) {
        _showValidationError('Please enter item name');
        return false;
      }

      if (itemNameController.text.trim().length < 3) {
        _showValidationError('Item name must be at least 3 characters');
        return false;
      }

      if (descriptionController.text.trim().isEmpty) {
        _showValidationError('Please enter description');
        return false;
      }

      if (descriptionController.text.trim().length < 10) {
        _showValidationError('Description must be at least 10 characters');
        return false;
      }

      if (selectedCategories.isEmpty) {
        _showValidationError('Please select a category');
        return false;
      }

      if (locationController.text.trim().isEmpty) {
        _showValidationError('Please enter location');
        return false;
      }

      if (priceController.text.trim().isEmpty) {
        _showValidationError('Please enter price');
        return false;
      }

      final price = double.tryParse(priceController.text.trim());
      if (price == null || price <= 0) {
        _showValidationError('Please enter a valid price greater than 0');
        return false;
      }

      if (emailController.text.trim().isEmpty) {
        _showValidationError('Please enter email address');
        return false;
      }

      if (!GetUtils.isEmail(emailController.text.trim())) {
        _showValidationError('Please enter a valid email address');
        return false;
      }

      if (imageUploadStatuses.isEmpty) {
        _showValidationError('Please add at least one image');
        return false;
      }

      if (!areAllImagesUploaded) {
        _showValidationError('Please wait for all images to finish uploading');
        return false;
      }

      return true;
    } catch (e) {
      _handleError('Form validation error', e);
      return false;
    }
  }

  // Submit form (navigate to preview)
  Future<void> submitForm() async {
    try {
      if (hasUploadingImages) {
        _showWarningSnackbar(
          'Upload in Progress',
          'Please wait for all images to finish uploading',
        );
        return;
      }

      if (!validateForm()) return;

      Get.to(() => const ListingItemPreviewScreen());
    } catch (e) {
      _handleError('Failed to submit form', e);
    }
  }

  final SubscriptionService _subscriptionService = SubscriptionService();

  Future<bool> checkListingPermission(String userId) async {
    return await _subscriptionService.canUserList(userId);
  }

  // Publish listing with comprehensive error handling
  Future<void> publishListing() async {
    try {
      bool pendingPayment = false;
      var checksub = await checkListingPermission(
        FirebaseAuth.instance.currentUser!.uid,
      );

      pendingPayment = checksub;
      isPublishing.value = true;
      isLoading.value = true;

      if (!await _hasInternetConnection()) {
        throw Exception('No internet connection. Please check your network.');
      }

      if (hasUploadingImages) {
        throw Exception('Images are still uploading. Please wait.');
      }

      if (!areAllImagesUploaded) {
        throw Exception('Some images failed to upload. Please try again.');
      }

      // Get uploaded image URLs
      List<String> imageUrls =
          imageUploadStatuses
              .where(
                (status) => status.isUploaded && status.uploadedUrl != null,
              )
              .map((status) => status.uploadedUrl!)
              .toList();

      if (imageUrls.isEmpty) {
        throw Exception('No images available. Please upload images.');
      }

      // Parse location data
      String text = locationController.text.trim();
      double latitude = 0.0;
      double longitude = 0.0;
      String cityState = '';

      if (text.isNotEmpty) {
        List<String> parts = text.split(',');
        if (parts.length >= 2) {
          latitude = double.tryParse(parts[0].trim()) ?? 0.0;
          longitude = double.tryParse(parts[1].trim()) ?? 0.0;
        }
        if (parts.length > 2) {
          cityState = parts.sublist(2).join(',').trim();
        }
      }

      // Create/update item listing
      final itemData = ItemListing(
        id:
            isEditMode.value
                ? existingItemId.value
                : null, // Keep existing ID for updates
        latitude: latitude,
        longitude: longitude,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        itemName: itemNameController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategories,
        price: double.tryParse(priceController.text.trim()) ?? 0.0,
        photoUrls: imageUrls,
        condition: selectedCondition.value,
        sizeDimensions: sizeController.text.trim(),
        isActive:
            isEditMode.value
                ? existingItem!.isActive
                : false, // Keep existing status
        createdAt: isEditMode.value ? existingItem!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        linkWebsite: linkWebsiteController.text.trim(),
        brand: brandController.text.trim(),
        shippingInfo: shippingController.text.trim(),
        email: emailController.text.trim(),
        preferredContactMethod: selectedContactMethod.value,
        paymentMethod: selectedPaymentMethod,
        otherPaymentOptions: otherPaymentController.text.trim(),
        cityState: cityState,
        venmoAccount: venmoAccountController.text.trim(),
        cashappAccount: cashappAccountController.text.trim(),
        paypalAccount: paypalController.text.trim(),
        paymentStatus:
            isEditMode.value
                ? existingItem!.paymentStatus
                : (pendingPayment ? 'paid' : 'pending'),
        videoUrls:
            videoUploadStatuses
                .where(
                  (status) => status.isUploaded && status.uploadedUrl != null,
                )
                .map((status) => status.uploadedUrl!)
                .toList(),
        attachmentUrls:
            attachmentUploadStatuses
                .where(
                  (status) => status.isUploaded && status.uploadedUrl != null,
                )
                .map((status) => status.uploadedUrl!)
                .toList(),
      );

      String itemId;

      if (isEditMode.value) {
        // Update existing item
        await _firebaseServices
            .updateItem(existingItemId.value, itemData)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('Update timeout'),
            );

        _showSuccessSnackbar('Success!', 'Listing updated successfully!');
      } else {
        // Create new item
        itemId = await _firebaseServices
            .createItem(itemData)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('Publishing timeout'),
            );

        _showSuccessSnackbar('Success!', 'Listing published successfully!');
      }

      // Clear form and navigate
      _clearForm();
      Get.until((route) => route.isFirst);

      if (isEditMode.value || pendingPayment) {
        Get.to(() => ListingFavoritesScreen());
      } else {
        Get.to(
          () => SubscriptionManagementScreen(
            userId: FirebaseAuth.instance.currentUser!.uid,
          ),
        )?.then((c) {
          Get.to(() => ListingFavoritesScreen());
        });
      }
    } on TimeoutException {
      _showErrorSnackbar('Timeout', 'Operation timed out. Please try again.');
    } on FirebaseException catch (e) {
      _showErrorSnackbar(
        'Database Error',
        'Failed to ${isEditMode.value ? 'update' : 'save'} listing: ${e.message ?? 'Unknown error'}',
      );
    } catch (e) {
      _handleError(
        'Failed to ${isEditMode.value ? 'update' : 'publish'} listing',
        e,
      );
    } finally {
      isPublishing.value = false;
      isLoading.value = false;
    }
  }

  // Clear form data
  void _clearForm() {
    try {
      if (!isEditMode.value) {
        // Only clear everything if we're not in edit mode
        phoneController.clear();
        facebookController.clear();
        itemNameController.clear();
        descriptionController.clear();
        locationController.clear();
        linkWebsiteController.clear();
        sizeController.clear();
        brandController.clear();
        priceController.clear();
        shippingController.clear();
        emailController.clear();
        paypalController.clear();
        otherPaymentController.clear();
        selectedCategories.value = [];
        selectedSubcategory.value = '';
        selectedCondition.value = '';
        selectedContactMethod.value = '';
        selectedPaymentMethod.value = [];
      }

      // Always clear media uploads
      imageUploadStatuses.clear();
      videoUploadStatuses.clear();
      attachmentUploadStatuses.clear();

      // Reset edit mode if we were in it
      if (isEditMode.value) {
        isEditMode.value = false;
        existingItemId.value = '';
        existingItem = null;
      }
    } catch (e) {
      print('Error clearing form: $e');
    }
  }

  // Error handling methods
  void _handleError(String message, dynamic error) {
    print('Error: $message - $error');
    _showErrorSnackbar('Error', '$message. Please try again.');
  }

  void _showValidationError(String message) {
    Get.snackbar(
      'Validation Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE74C3C),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      icon: const Icon(Icons.warning, color: Colors.white),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE74C3C),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _showWarningSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE74C3C),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      icon: const Icon(Icons.warning, color: Colors.white),
    );
  }

  void _showInfoSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      icon: const Icon(Icons.info, color: Colors.white),
    );
  }

  // Navigation methods
  void goBack() {
    try {
      if (hasUploadingImages) {
        Get.dialog(
          AlertDialog(
            title: const Text('Upload in Progress'),
            content: const Text(
              'Images are still uploading. Are you sure you want to go back? This will cancel the uploads.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  imageUploadStatuses.clear(); // Clear uploads
                  Get.back(); // Go back to previous screen
                },
                child: const Text('Leave'),
              ),
            ],
          ),
        );
      } else {
        Get.back();
      }
    } catch (e) {
      _handleError('Navigation error', e);
    }
  }

  bool get areAllMediaUploaded =>
      imageUploadStatuses.every(
        (status) => status.isUploaded && status.uploadedUrl != null,
      ) &&
      videoUploadStatuses.every(
        (status) => status.isUploaded && status.uploadedUrl != null,
      ) &&
      attachmentUploadStatuses.every(
        (status) => status.isUploaded && status.uploadedUrl != null,
      );

  bool get hasUploadingMedia =>
      imageUploadStatuses.any((status) => status.isUploading) ||
      videoUploadStatuses.any((status) => status.isUploading) ||
      attachmentUploadStatuses.any((status) => status.isUploading);

  // Utility methods
  String getImageUploadProgress() {
    if (imageUploadStatuses.isEmpty) return '';

    final uploadedCount =
        imageUploadStatuses.where((status) => status.isUploaded).length;
    final totalCount = imageUploadStatuses.length;

    return '$uploadedCount/$totalCount images uploaded';
  }

  bool canPublish() {
    return areAllImagesUploaded &&
        !hasUploadingImages &&
        !isPublishing.value &&
        !isLoading.value;
  }

  // Retry failed uploads
  Future<void> retryFailedUploads() async {
    try {
      final failedUploads =
          imageUploadStatuses
              .where(
                (status) =>
                    !status.isUploaded &&
                    !status.isUploading &&
                    status.error != null,
              )
              .toList();

      if (failedUploads.isEmpty) {
        _showInfoSnackbar(
          'No Failed Uploads',
          'All images are uploaded successfully',
        );
        return;
      }

      _showInfoSnackbar(
        'Retrying',
        'Retrying ${failedUploads.length} failed upload(s)...',
      );

      for (final failedStatus in failedUploads) {
        final index = imageUploadStatuses.indexOf(failedStatus);
        if (index != -1) {
          // Reset status to uploading
          imageUploadStatuses[index] = failedStatus.copyWith(
            isUploading: true,
            error: null,
          );

          try {
            // Retry upload
            final uploadedUrl = await _uploadImageWithRetry(failedStatus.file);

            // Update with success
            imageUploadStatuses[index] = failedStatus.copyWith(
              isUploading: false,
              isUploaded: true,
              uploadedUrl: uploadedUrl,
              error: null,
            );
          } catch (e) {
            // Update with new error
            imageUploadStatuses[index] = failedStatus.copyWith(
              isUploading: false,
              error: e.toString(),
            );
          }
        }
      }

      final successCount =
          imageUploadStatuses.where((status) => status.isUploaded).length;
      _showSuccessSnackbar(
        'Retry Complete',
        '$successCount/${imageUploadStatuses.length} images uploaded successfully',
      );
    } catch (e) {
      _handleError('Failed to retry uploads', e);
    }
  }

  // Get upload status summary
  Map<String, int> getUploadStatusSummary() {
    return {
      'total': imageUploadStatuses.length,
      'uploaded':
          imageUploadStatuses.where((status) => status.isUploaded).length,
      'uploading':
          imageUploadStatuses.where((status) => status.isUploading).length,
      'failed':
          imageUploadStatuses
              .where(
                (status) =>
                    !status.isUploaded &&
                    !status.isUploading &&
                    status.error != null,
              )
              .length,
    };
  }
}

final Map<String, List<String>> categoriesStatic = {
  "Business & Services": [
    'Business & Services',
    "Western Retail Shops",
    "Boutiques",
    "Ranch Services",
    "All Other",
  ],
  "Home & Ranch Decor": ['Home & Ranch Decor', "Furniture", "Art", "Decor"],
  "Tack & Live Stock": [
    "Tack & Live Stock",
    "Tack",
    "Horses",
    "Livestock",
    "Miscellaneous",
  ],
  "Western Life & Events": [
    'Western Life & Events',
    "Rodeos",
    "Barrel Races",
    "Team Roping",
    "All Other Events",
  ],
  "Western Style": ["Womens", "Mens", "Kids", "Accessories"],
};
