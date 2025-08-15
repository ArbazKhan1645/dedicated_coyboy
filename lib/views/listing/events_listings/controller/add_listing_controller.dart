// add_listing_controller.dart
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:dedicated_cowboy/app/models/modules_models/event_model.dart';
import 'package:dedicated_cowboy/app/services/listings_service.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/controller/add_listing_controller.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/listing_item_preview_screen.dart';
import 'package:dedicated_cowboy/views/my_listings/my_listings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:connectivity_plus/connectivity_plus.dart';

class ListEventController extends GetxController {
  final FirebaseServices _firebaseServices = FirebaseServices();

  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  Future<void> pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)), // Start date > today
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _selectedStartDate = picked;
      startDateController.text = DateFormat('d MMMM yyyy').format(picked);

      // Reset end date if invalid
      if (_selectedEndDate != null && _selectedEndDate!.isBefore(picked)) {
        _selectedEndDate = null;
        endDateController.clear();
      }
    }
  }

  Future<void> pickEndDate(BuildContext context) async {
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date first')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate!.add(const Duration(days: 1)),
      firstDate: _selectedStartDate!.add(
        const Duration(days: 1),
      ), // End > Start
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _selectedEndDate = picked;
      endDateController.text = DateFormat('d MMMM yyyy').format(picked);
    }
  }

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

  // Observable variables
  final RxString selectedCategory = RxString('');
  final RxString selectedSubcategory = RxString('');
  final RxString selectedCondition = RxString('');
  final RxString selectedContactMethod = RxString('');
  final RxString selectedPaymentMethod = RxString('');
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
  final List<String> categories = [
    'Home and Ranch Decor',
    'Art',
    'Decor',
    'Furniture',
    'Tack and Livestock',
    'Horses',
  ];

  final List<String> subcategories = [];
  final List<String> conditions = ['New', 'Used', 'Vintage'];
  final List<String> contactMethods = ['Text', 'Call', 'Messenger', 'Email'];
  final List<String> paymentMethods = [
    'Paypal',
    'Cash',
    'VENMO',
    'Credit Card',
  ];

  // Getters for better access
  String? get categoryValue =>
      selectedCategory.value.isEmpty ? null : selectedCategory.value;
  String? get subcategoryValue =>
      selectedSubcategory.value.isEmpty ? null : selectedSubcategory.value;
  String? get conditionValue =>
      selectedCondition.value.isEmpty ? null : selectedCondition.value;
  String? get contactMethodValue =>
      selectedContactMethod.value.isEmpty ? null : selectedContactMethod.value;
  String? get paymentMethodValue =>
      selectedPaymentMethod.value.isEmpty ? null : selectedPaymentMethod.value;

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
    _initializeData();
    _setupConnectivityListener();
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
    if (result == ConnectivityResult.none) {
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
  void selectCategory(String? category) {
    try {
      selectedCategory.value = category ?? '';
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
      selectedPaymentMethod.value = method ?? '';
      update();
    } catch (e) {
      _handleError('Failed to select payment method', e);
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
      return result != ConnectivityResult.none;
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
                'Select Images',
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
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF4A825)),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 30,
                              color: Color(0xFFF4A825),
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
                          color: const Color(0xFFEAF4FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2C3E50)),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.photo_library,
                              size: 30,
                              color: Color(0xFF2C3E50),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Gallery',
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
                ],
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
      return "Enhanced: $original - High-quality event with excellent features, perfect condition, and great value for money.";
    } catch (e) {
      return original; // Fallback to original if enhancement fails
    }
  }

  // Comprehensive form validation
  bool validateForm() {
    try {
      if (itemNameController.text.trim().isEmpty) {
        _showValidationError('Please enter event name');
        return false;
      }

      if (itemNameController.text.trim().length < 3) {
        _showValidationError('event name must be at least 3 characters');
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

      if (selectedCategory.value.isEmpty) {
        _showValidationError('Please select a category');
        return false;
      }

      if (locationController.text.trim().isEmpty) {
        _showValidationError('Please enter location');
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

  // Publish listing with comprehensive error handling
  Future<void> publishListing() async {
    try {
      if (isPublishing.value) return;

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

      // Create item listing

      final newItem = EventListing(
        address: cityState,
        eventEndDate: _selectedEndDate,
        eventStartDate: _selectedStartDate,
        latitude: latitude,
        longitude: longitude,
        userId: FirebaseAuth.instance.currentUser!.uid,
        eventName: itemNameController.text.trim(),
        description: descriptionController.text.trim(),
        eventCategory: selectedCategory.value,
        attachmentUrls: imageUrls,
        phoneCall: contactController.text.trim(),
        isFeatured: false,
        photoUrls: imageUrls,
        isActive: false,

        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        eventWebsiteRegistrationLink: linkWebsiteController.text.trim(),

        email: emailController.text.trim(),
      );

      final itemId = await _firebaseServices
          .createEvent(newItem)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Publishing timeout'),
          );

      _showSuccessSnackbar('Success!', 'Listing published successfully!');

      // Clear form and navigate
      _clearForm();
      Get.until((route) => route.isFirst);
      Get.to(() => ListingFavoritesScreen());
    } on TimeoutException {
      _showErrorSnackbar('Timeout', 'Publishing timed out. Please try again.');
    } on FirebaseException catch (e) {
      _showErrorSnackbar(
        'Database Error',
        'Failed to save listing: ${e.message ?? 'Unknown error'}',
      );
    } catch (e) {
      _handleError('Failed to publish listing', e);
    } finally {
      isPublishing.value = false;
      isLoading.value = false;
    }
  }

  // Clear form data
  void _clearForm() {
    try {
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
      selectedCategory.value = '';
      selectedSubcategory.value = '';
      selectedCondition.value = '';
      selectedContactMethod.value = '';
      selectedPaymentMethod.value = '';
      imageUploadStatuses.clear();
    } catch (e) {
      print('Error clearing form: $e');
    }
  }

  // Load existing item data with validation
  void loadItemData(Map<String, dynamic> itemData) {
    try {
      itemNameController.text = itemData['itemName']?.toString() ?? '';
      descriptionController.text = itemData['description']?.toString() ?? '';
      selectedCategory.value = itemData['category']?.toString() ?? '';
      selectedSubcategory.value = itemData['subcategory']?.toString() ?? '';
      locationController.text = itemData['location']?.toString() ?? '';
      linkWebsiteController.text = itemData['linkWebsite']?.toString() ?? '';
      sizeController.text = itemData['size']?.toString() ?? '';
      selectedCondition.value = itemData['condition']?.toString() ?? '';
      brandController.text = itemData['brand']?.toString() ?? '';
      priceController.text = itemData['price']?.toString() ?? '';
      shippingController.text = itemData['shipping']?.toString() ?? '';
      emailController.text = itemData['email']?.toString() ?? '';
      selectedContactMethod.value = itemData['contactMethod']?.toString() ?? '';
      selectedPaymentMethod.value = itemData['paymentMethod']?.toString() ?? '';
      paypalController.text = itemData['paypal']?.toString() ?? '';
      otherPaymentController.text = itemData['otherPayment']?.toString() ?? '';
      phoneController.text = itemData['phone']?.toString() ?? '';
      facebookController.text = itemData['facebook']?.toString() ?? '';
    } catch (e) {
      _handleError('Failed to load event data', e);
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
      backgroundColor: const Color(0xFFF39C12),
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
      backgroundColor: Color(0xFFF3B340),
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
      backgroundColor: const Color(0xFFF39C12),
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
      backgroundColor: const Color(0xFF3498DB),
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
