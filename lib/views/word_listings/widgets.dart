// Unified Detail Screen that handles all listing types
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/services/chat_room_service/chat_room_service.dart';
import 'package:dedicated_cowboy/views/chats/chats_view.dart';
import 'package:dedicated_cowboy/views/word_listings/model.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

class UnifiedDetailScreen extends StatefulWidget {
  final UnifiedListing listing;

  const UnifiedDetailScreen({super.key, required this.listing});

  @override
  _UnifiedDetailScreenState createState() => _UnifiedDetailScreenState();
}

class _UnifiedDetailScreenState extends State<UnifiedDetailScreen> {
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
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              widget.listing.slug ?? '',
              style: TextStyle(
                color: Color(0xFFF2B342),
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // ReportButton(
          //   listingId: widget.listing.id?.toString() ?? '',
          //   listingType: widget.listing.listingType,
          //   listingName: widget.listing.title ?? 'Unnamed ${widget.listing.listingType}',
          //   listingImage: null, // Will need to implement image extraction
          // ),
          SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Gallery Section
            _buildMediaGallery(),

            // Listing Info
            Padding(
              padding: EdgeInsets.all(16),
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

                  // Price (for items)
                  if (widget.listing.isItem &&
                      widget.listing.priceAsDouble != null) ...[
                    Text(
                      '\$${widget.listing.priceAsDouble!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF2B342),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Status indicators
                  _buildStatusSection(),

                  SizedBox(height: 20),

                  // Location Section
                  if (widget.listing.address != null &&
                      widget.listing.address!.isNotEmpty)
                    _buildLocationSection(),

                  SizedBox(height: 20),

                  // Contact Information Section
                  _buildContactInfoSection(),

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

  Widget _buildMediaGallery() {
    final images = widget.listing?.images ?? [];

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
              itemCount: images.isNotEmpty ? images.length : 1,
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
                  ),
                );
              },
            ),
          ),

          // Page Indicator
          // if (images.length > 1)
          //   Positioned(
          //     bottom: 12,
          //     left: 0,
          //     right: 0,
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: List.generate(images.length, (index) {
          //         return Obx(() => Container(
          //               margin: const EdgeInsets.symmetric(horizontal: 3),
          //               width: currentPage.value == index ? 10 : 6,
          //               height: currentPage.value == index ? 10 : 6,
          //               decoration: BoxDecoration(
          //                 color: currentPage.value == index
          //                     ? Colors.white
          //                     : Colors.white54,
          //                 shape: BoxShape.circle,
          //               ),
          //             ));
          //       }),
          //     ),
          //   ),

          // Listing type badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getListingTypeColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.listing?.listingType?.toUpperCase() ?? "",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    List<Widget> statusWidgets = [];

    // Featured status
    if (widget.listing.featured == '1') {
      statusWidgets.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFFF2B342).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFF2B342)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Color(0xFFF2B342), size: 14),
              SizedBox(width: 4),
              Text(
                'Featured',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFF2B342),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Listing type
    statusWidgets.add(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getListingTypeColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getListingTypeColor()),
        ),
        child: Text(
          widget.listing.listingType,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _getListingTypeColor(),
          ),
        ),
      ),
    );

    if (statusWidgets.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Wrap(spacing: 8.0, runSpacing: 8.0, children: statusWidgets),
      ],
    );
  }

  Widget _buildLocationSection() {
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
            'Location',
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
                  widget.listing.address!,
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
    final hasEmail =
        widget.listing.email != null && widget.listing.email!.isNotEmpty;
    final hasPhone =
        widget.listing.phone != null && widget.listing.phone!.isNotEmpty;

    if (!hasEmail && !hasPhone) {
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
              'Contact Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Contact through the app for more details',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

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
            'Contact Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),
          if (hasEmail) ...[
            _buildContactRow(
              Icons.email_outlined,
              'Email:',
              widget.listing.email!,
            ),
            if (hasPhone) SizedBox(height: 12),
          ],
          if (hasPhone) ...[
            _buildContactRow(
              Icons.phone_outlined,
              'Phone:',
              widget.listing.phone!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Color(0xFFF2B342), size: 18),
        SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color _getListingTypeColor() {
    switch (widget.listing.listingType.toLowerCase()) {
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

      final currentUser = await chatService.getUserProfile(currentUserId);
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
        productImage: null, // Will need to implement image extraction
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

  @override
  void initState() {
    super.initState();
    _imageUrl = _getListingImageUrl(widget.listing) ?? '';
    _cachedImage = _buildCachedImage(); // Build image once and cache it
    _checkFavoriteStatus();
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

  Future<void> _checkFavoriteStatus() async {
    if (widget.listing.id != null) {
      // Uncomment when service is ready
      // final isFav = await _favoritesService.isFavorite(
      //   widget.listing.id!.toString(),
      // );
      if (mounted) {
        setState(() {
          _isFavorite = true;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    final listing = widget.listing;
    if (listing.id == null || listing.author == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Your favorite toggle logic here...
      // Commented out service calls
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
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
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                                color:
                                    _isFavorite
                                        ? Colors.black
                                        : Colors.grey[600],
                              ),
                    ),
                  ),
                ),

                // Listing type badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getListingTypeColor(listing.listingType),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      listing.listingType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

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
                  const SizedBox(height: 4),
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
                        )
                      else if (listing.isItem)
                        const Text(
                          'Price not set',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      // Show location for all types
                      else if (listing.address != null &&
                          listing.address!.isNotEmpty)
                        Text(
                          listing.address!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          'View details',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
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
