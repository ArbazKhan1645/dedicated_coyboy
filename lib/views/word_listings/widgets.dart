import 'package:dedicated_cowboy/app/models/api_user_model.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/services/chat_room_service/chat_room_service.dart';
import 'package:dedicated_cowboy/views/chats/chats_view.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/controller/add_listing_controller.dart';
import 'package:dedicated_cowboy/views/word_listings/model.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

class UnifiedDetailScreen extends StatefulWidget {
  final UnifiedListing listing;

  const UnifiedDetailScreen({super.key, required this.listing});

  @override
  _UnifiedDetailScreenState createState() => _UnifiedDetailScreenState();
}

class _UnifiedDetailScreenState extends State<UnifiedDetailScreen> {
  Future<void> _removeFavorite(UnifiedListing listing) async {
    try {
      final currentUser = Get.find<AuthService>().currentUser;
      if (currentUser != null) {
        currentUser.favouriteListings?.remove(listing.id);
        ApiUserModel currentUserupdated = currentUser.removeFromFavourites(
          listing.id ?? 0,
        );
        Get.find<AuthService>().updateUserProfileDetails(
          updateData: {
            "meta": {
              "atbdp_favourites": currentUserupdated.favouriteListingIds,
            },
          },
        );

        Get.snackbar(
          'Removed',
          '${listing.title} removed from favorites',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        setState(() {});
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove from favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _addListing(UnifiedListing listing) async {
    try {
      final currentUser = Get.find<AuthService>().currentUser;
      if (currentUser != null) {
        currentUser.favouriteListings?.add(listing.id ?? -1);
        ApiUserModel currentUserupdated = currentUser.addToFavourites(
          listing.id ?? 0,
        );
        Get.find<AuthService>().updateUserProfileDetails(
          updateData: {
            "meta": {
              "atbdp_favourites": currentUserupdated.favouriteListingIds,
            },
          },
        );

        Get.snackbar(
          'Added',
          '${listing.title} Added to favorites',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        setState(() {});
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to Add to favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _toggleFavorite(bool val) async {
    if (val == false) {
      _addListing(widget.listing);
    } else {
      _removeFavorite(widget.listing);
    }
  }

  Future<bool> _checkFavoriteStatus(UnifiedListing listing) async {
    var isFav = Get.find<AuthService>().currentUser?.isListingFavourite(
      listing.id ?? -1,
    );

    if (isFav != null) {
      return isFav;
    }
    return false;
  }

  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final authService = Get.find<AuthService>();

  String _getListingTypeCategory() {
    switch (widget.listing.listingType.toLowerCase()) {
      case 'item':
        return 'Item';
      case 'business':
        return 'Business';
      case 'event':
        return 'Event';
      default:
        return 'Listing';
    }
  }

  bool _isPopular() {
    final postViews =
        int.tryParse(metaData['_atbdp_post_views_count']?.first ?? '0') ?? 0;
    final pageViews = int.tryParse(metaData['wl_pageviews']?.first ?? '0') ?? 0;
    final totalViews = postViews + pageViews;

    return postViews >= 10; // Threshold for popular items
  }

  void _shareItem() {
    final String shareText = _buildShareText();
    Share.share(shareText);
  }

  String _buildShareText() {
    final title = widget.listing.slug ?? 'Check out this listing';
    final price = _getPrice();
    final url =
        widget.listing.link ??
        'https://dedicatedcowboy.com/directory/${widget.listing.slug}/';

    return '$title${price.isNotEmpty ? ' - $price' : ''}\n\n$url';
  }

  // Dynamic meta data getter
  Map<String, dynamic> get metaData => widget.listing.meta ?? {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              '${_getListingTypeCategory()}/',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              widget.listing.slug ?? '',
              style: TextStyle(
                color: Color(0xFFF2B342),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [SizedBox(width: 20)],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Media Gallery Section
            _buildEnhancedMediaGallery(),
            Row(
              children: [
                FutureBuilder(
                  future: _checkFavoriteStatus(widget.listing),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container();
                    }
                    if (snapshot.hasError) {
                      return Container();
                    }
                    bool isfav = snapshot.data ?? false;
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: GestureDetector(
                        onTap: () {
                          _toggleFavorite(isfav);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),

                          child: Icon(
                            isfav ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isfav ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share, size: 16, color: Colors.grey[600]),
                  onPressed: () => _shareItem(),
                ),
              ],
            ),

            // Listing Info
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.listing.title ??
                        'Unnamed ${widget.listing.listingType}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Category and Art tag
                  _buildCategorySection(),
                  if (_isPopular()) SizedBox(height: 8),
                  if (_isPopular())
                    Container(
                      // margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFF2B342),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFF2B342)),
                      ),
                      child: Text(
                        'Popular',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  SizedBox(height: 8),

                  // Price
                  _buildPriceSection(),
                  SizedBox(height: 16),

                  // Description
                  if (widget.listing.cleanContent.isNotEmpty) ...[
                    Text(
                      widget.listing.cleanContent,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Location Section
                  if (_getAddress().isNotEmpty) _buildLocationSection(),
                  SizedBox(height: 16),

                  // Shipping Info Section
                  _buildShippingInfoSection(),
                  SizedBox(height: 16),

                  // Dynamic Meta Information Section
                  _buildMetaInfoSection(),
                  SizedBox(height: 16),

                  // Contact Information Section
                  _buildContactInfoSection(),
                  SizedBox(height: 20),

                  // Payment Options Section
                  _buildPaymentOptionsSection(),
                  SizedBox(height: 32),

                  // Contact Button
                  if (widget.listing.author != null &&
                      widget.listing.author.toString() !=
                          authService.currentUser?.id)
                    CustomElevatedButton(
                      text: _getContactButtonText(),
                      backgroundColor: Color(0xFFF2B342),
                      textColor: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      borderRadius: 28,
                      onTap: () => _handleContactTap(),
                    ),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMediaGallery() {
    final images = widget.listing?.images ?? [];

    final hasMultipleImages = images.length > 1;

    return Container(
      height: 300,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Images PageView
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.isNotEmpty ? images.length : 1,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final imageUrl =
                    images.isNotEmpty
                        ? images[index].url
                        : 'assets/images/placeholder.png';

                return GestureDetector(
                  onTap: () {
                    Get.to(() => ImageViewer(imageUrl: imageUrl.toString()));
                  },
                  child: Image.network(
                    imageUrl.toString(),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Navigation buttons (only show when multiple images)
          if (hasMultipleImages) ...[
            // Previous button
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                    onPressed:
                        _currentImageIndex > 0
                            ? () {
                              _pageController.previousPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                            : null,
                  ),
                ),
              ),
            ),

            // Next button
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                    onPressed:
                        _currentImageIndex < images.length - 1
                            ? () {
                              _pageController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                            : null,
                  ),
                ),
              ),
            ),

            // Image indicator dots
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    images.asMap().entries.map((entry) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _currentImageIndex == entry.key
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Row(
      children: [
        Icon(Icons.local_offer, color: Color(0xFFF2B342), size: 16),
        SizedBox(width: 4),
        Text(
          getCategoryNameById(widget.listing.categories?[0] ?? 0).toString(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final price = _getPrice();
    if (price.isEmpty) return SizedBox.shrink();

    return Text(
      price,
      style: TextStyle(
        fontSize: 26,
        fontFamily: 'poppins',
        fontWeight: FontWeight.bold,
        color: Color(0xFFF2B342),
      ),
    );
  }

  Widget _buildShippingInfoSection() {
    final shippingInfo = _getShippingInfo();
    if (shippingInfo.isEmpty) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipping Info / Pickup:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            shippingInfo,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfoSection() {
    final metaItems = _getDisplayableMetaItems();
    if (metaItems.isEmpty) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12),
          ...metaItems.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['label']}: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['value'].toString(),
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final address = _getAddress();
    if (address.isEmpty) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location/City & State:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFFF2B342), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildContactInfoSection() {
    final email = _getEmail();
    final phone = _getPhone();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            email.isNotEmpty
                ? email
                : 'Contact through the app for more details',
            style: TextStyle(
              fontSize: 14,
              color: email.isNotEmpty ? Colors.black87 : Colors.grey[600],
            ),
          ),
          if (phone.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Phone number:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(phone, style: TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOptionsSection() {
    final paymentOptions = _getPaymentOptions();
    final venmoAccount = _getVenmoAccount();
    final cashAppAccount = _getCashAppAccount();
    final otherPayments = _getOtherPaymentOptions();
    final preferredContact = _getPreferredContact();

    final hasAnyPaymentInfo =
        paymentOptions.isNotEmpty ||
        venmoAccount.isNotEmpty ||
        cashAppAccount.isNotEmpty ||
        otherPayments.isNotEmpty ||
        preferredContact.isNotEmpty;

    if (!hasAnyPaymentInfo) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Options:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12),
          if (paymentOptions.isNotEmpty) ...[
            Text(
              paymentOptions,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 8),
          ],
          if (venmoAccount.isNotEmpty) ...[
            Text(
              'Venmo account number: $venmoAccount',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 8),
          ],
          if (cashAppAccount.isNotEmpty) ...[
            Text(
              'CashApp account number: $cashAppAccount',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 8),
          ],
          if (otherPayments.isNotEmpty) ...[
            Text(
              'Other Payment Options: $otherPayments',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 8),
          ],
          if (preferredContact.isNotEmpty) ...[
            Text(
              'Preferred Method of Contact:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              preferredContact,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods to extract data from meta
  String _getPrice() {
    final price = metaData['_price']?.first ?? widget.listing.price ?? '';
    return price.isNotEmpty ? '\$$price' : '';
  }

  String _getAddress() {
    return metaData['_address']?.first ?? widget.listing.address ?? '';
  }

  String _getEmail() {
    return metaData['_email']?.first ?? widget.listing.email ?? '';
  }

  String _getPhone() {
    return metaData['_phone']?.first ??
        metaData['_custom-text-3']?.first ??
        widget.listing.phone ??
        '';
  }

  String _getShippingInfo() {
    return metaData['_custom-textarea']?.first ?? '';
  }

  String _getPaymentOptions() {
    List<String> paymentOptions = [];
    // Check for venmo-specific fields in meta data
    String venmoField = metaData['_custom-textarea']?.first ?? '';

    // If no specific field, you might need to parse from a general payment field
    // or return empty if not available
    if (venmoField.isNotEmpty) {
      paymentOptions.add('Venmo');
    }

    // Check for cashapp-specific fields in meta data
    String cashAppField = metaData['_custom-text-7']?.first ?? '';
    if (cashAppField.isNotEmpty) {
      paymentOptions.add('CashApp');
    }

    return paymentOptions.join(', ');
  }

  String _getVenmoAccount() {
    // Check for venmo-specific fields in meta data
    final venmoField = metaData['_custom-textarea']?.first ?? '';

    // If no specific field, you might need to parse from a general payment field
    // or return empty if not available
    return venmoField;
  }

  String _getCashAppAccount() {
    // Check for cashapp-specific fields in meta data
    final cashAppField = metaData['_custom-text-7']?.first ?? '';

    return cashAppField;
  }

  String _getOtherPaymentOptions() {
    // Check for other payment methods field
    final otherPayments =
        metaData['_custom-text']?.first ??
        metaData['_other_payments']?.first ??
        metaData['_custom-other-payments']?.first ??
        '';

    return otherPayments;
  }

  String _getPreferredContact() {
    final contactData = metaData['_custom-checkbox-3']?.first ?? '';
    if (contactData.isNotEmpty) {
      // Parse serialized array data - this extracts contact methods like Text, Call, Email
      List<String> methods = [];
      if (contactData.contains('Text')) methods.add('Text');
      if (contactData.contains('Call')) methods.add('Call');
      if (contactData.contains('Email')) methods.add('Email');
      return methods.join(', ');
    }
    return '';
  }

  List<Map<String, String>> _getDisplayableMetaItems() {
    List<Map<String, String>> items = [];

    // Size information
    final size = metaData['_custom-text-2']?.first ?? '';
    if (size.isNotEmpty) {
      items.add({'label': 'Size', 'value': size});
    }

    // Add other relevant meta fields as needed
    // You can extend this based on your specific meta fields

    return items;
  }

  String _getContactButtonText() {
    switch (widget.listing.listingType.toLowerCase()) {
      case 'item':
        return 'Inquire Now';
      case 'business':
        return 'Contact Business';
      case 'event':
        return 'Contact Organizer';
      default:
        return 'Contact';
    }
  }

  Future<void> _handleContactTap() async {
    final chatService = ChatService.instance;

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final authService = Get.find<AuthService>();

      final user = authService.currentUser;

      final currentUserId = user?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final currentUser = Get.find<AuthService>().currentUser;
      if (currentUser == null) {
        throw Exception('Please Sign in again');
      }

      final otherUserId = widget.listing.author?.toString();
      if (otherUserId == null || otherUserId.isEmpty) {
        throw Exception('Owner information is missing');
      }

      final otherUser = await chatService.getUserProfile(otherUserId);
      if (otherUser == null) {
        throw Exception('Owner information not found');
      }

      final chatRoomId = await chatService.createOrGetChatRoom(
        otherUser: otherUser,
        currentUser: currentUser,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        productId: widget.listing.id?.toString(),
        productTitle: widget.listing.title,
        productImage: null,
      );

      Get.back();

      Get.to(
        () => const ChatMessageScreen(),
        arguments: {
          'chatRoomId': chatRoomId,
          'currentUserId': currentUserId,
          'otherUserId': otherUserId,
        },
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }
}

// Updated ImageViewer (remains the same)
class ImageViewer extends StatelessWidget {
  final String imageUrl;

  const ImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: PhotoView(
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
          ),
        ),
      ),
    );
  }
}

class UnifiedProductCard extends StatefulWidget {
  final UnifiedListing listing;
  final List<String> categorySelected;
  final VoidCallback? onFavoriteTap;

  const UnifiedProductCard({
    super.key,
    required this.listing,
    required this.categorySelected,
    this.onFavoriteTap,
  });

  @override
  _UnifiedProductCardState createState() => _UnifiedProductCardState();
}

class _UnifiedProductCardState extends State<UnifiedProductCard> {
  bool _isFavorite = false;
  bool _isLoading = false;
  late final String _imageUrl;
  late final Widget _cachedImage;

  Future<void> _removeFavorite(UnifiedListing listing) async {
    try {
      final currentUser = Get.find<AuthService>().currentUser;
      if (currentUser != null) {
        currentUser.favouriteListings?.remove(listing.id);
        ApiUserModel currentUserupdated = currentUser.removeFromFavourites(
          listing.id ?? 0,
        );
        Get.find<AuthService>().updateUserProfileDetails(
          updateData: {
            "meta": {
              "atbdp_favourites": currentUserupdated.favouriteListingIds,
            },
          },
        );

        Get.snackbar(
          'Removed',
          '${listing.title} removed from favorites',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        setState(() {});
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove from favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _addListing(UnifiedListing listing) async {
    try {
      final currentUser = Get.find<AuthService>().currentUser;
      if (currentUser != null) {
        currentUser.favouriteListings?.add(listing.id ?? -1);
        ApiUserModel currentUserupdated = currentUser.addToFavourites(
          listing.id ?? 0,
        );
        Get.find<AuthService>().updateUserProfileDetails(
          updateData: {
            "meta": {
              "atbdp_favourites": currentUserupdated.favouriteListingIds,
            },
          },
        );

        Get.snackbar(
          'Added',
          '${listing.title} Added to favorites',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFF2B342),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        setState(() {});
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to Add to favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<bool> _checkFavoriteStatus(UnifiedListing listing) async {
    var isFav = Get.find<AuthService>().currentUser?.isListingFavourite(
      listing.id ?? -1,
    );

    if (isFav != null) {
      return isFav;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _imageUrl = _getListingImageUrl(widget.listing) ?? '';
    _cachedImage = _buildCachedImage(); // Build image once and cache it
  }

  // Cache the image widget to prevent rebuilding
  Widget _buildCachedImage() {
    if (_imageUrl.isNotEmpty) {
      return Image.network(
        _imageUrl,
        width: double.infinity,
        height: double.infinity,

        // Enable caching and prevent rebuilding
        cacheWidth: 400, // Optimize memory usage
        cacheHeight: 340,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/images/Rectangle 3463809 (4).png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      // Cache asset images too
      cacheWidth: 400,
      cacheHeight: 300,
    );
  }

  Future<void> _toggleFavorite(bool val) async {
    if (val == false) {
      _addListing(widget.listing);
    } else {
      _removeFavorite(widget.listing);
    }
  }

  String? _getListingImageUrl(UnifiedListing listing) {
    return listing.featuredImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _cachedImage, // Use the cached image widget
                ),

                // Favorite button
                FutureBuilder(
                  future: _checkFavoriteStatus(listing),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container();
                    }
                    if (snapshot.hasError) {
                      return Container();
                    }
                    bool isfav = snapshot.data ?? false;
                    return Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          _toggleFavorite(isfav);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey[600]!,
                                      ),
                                    ),
                                  )
                                  : Icon(
                                    isfav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 16,
                                    color:
                                        isfav ? Colors.black : Colors.grey[600],
                                  ),
                        ),
                      ),
                    );
                  },
                ),

                // Listing type badge
                // Positioned(
                //   top: 8,
                //   left: 8,
                //   child: Container(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 8,
                //       vertical: 4,
                //     ),
                //     decoration: BoxDecoration(
                //       color: _getListingTypeColor(listing.listingType),
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     child: Text(
                //       listing.listingType.toUpperCase(),
                //       style: const TextStyle(
                //         color: Colors.white,
                //         fontSize: 10,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   ),
                // ),

                // Featured badge
                if (listing.featured == '1')
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2B342),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 10),
                          SizedBox(width: 2),
                          Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFEDEDED),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title ?? 'Unnamed ${listing.listingType}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show price only for Items
                      if (listing.isItem && listing.priceAsDouble != null)
                        Text(
                          '\$${listing.priceAsDouble!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF2B342),
                          ),
                        ),
                      Text(
                        listing.meta != null &&
                                listing.meta!['_custom-text-2'] != null &&
                                (listing.meta!['_custom-text-2'] as List)
                                    .isNotEmpty
                            ? (listing.meta!['_custom-text-2'] as List).first
                                .toString()
                            : '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      // else if (listing.isItem)
                      //   const Text(
                      //     'Price not set',
                      //     style: TextStyle(
                      //       fontSize: 12,
                      //       color: Colors.grey,
                      //       fontStyle: FontStyle.italic,
                      //     ),
                      //   )
                      // // Show location for all types
                      // else if (listing.address != null &&
                      //     listing.address!.isNotEmpty)
                      //   Text(
                      //     listing.address!,
                      //     style: TextStyle(
                      //       fontSize: 12,
                      //       color: Colors.grey[600],
                      //       fontStyle: FontStyle.italic,
                      //     ),
                      //     maxLines: 2,
                      //     overflow: TextOverflow.ellipsis,
                      //   )
                      // else
                      //   Text(
                      //     'View details',
                      //     style: TextStyle(
                      //       fontSize: 12,
                      //       color: Colors.grey[600],
                      //       fontStyle: FontStyle.italic,
                      //     ),
                      //   ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getListingTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'item':
        return const Color(0xFFF2B342);
      case 'business':
        return Colors.blue;
      case 'event':
        return Colors.tealAccent;
      default:
        return Colors.grey;
    }
  }
}
