// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/services/listings_service.dart';
import 'package:dedicated_cowboy/app/services/favorite_service/fav_service.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/subcriptions_view.dart';
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/views/listing/bussiness_listing/list_an_bussines.dart';
import 'package:dedicated_cowboy/views/listing/bussiness_listing/list_bussiness_form.dart';
import 'package:dedicated_cowboy/views/listing/events_listings/list_item_form.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/list_item_form.dart';
import 'package:dedicated_cowboy/views/products_listings/products_listings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dedicated_cowboy/app/models/modules_models/business_model.dart';
import 'package:dedicated_cowboy/app/models/modules_models/event_model.dart';
import 'package:dedicated_cowboy/app/models/modules_models/item_model.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';

class ListingFavoritesScreen extends StatefulWidget {
  const ListingFavoritesScreen({super.key});

  @override
  _ListingFavoritesScreenState createState() => _ListingFavoritesScreenState();
}

class _ListingFavoritesScreenState extends State<ListingFavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter options
  String _selectedCategory = 'All';
  String _selectedLocation = 'All';
  String _selectedPrice = 'All';
  Position? _userLocation;
  bool _isLoadingLocation = false;

  // Firebase services
  final FirebaseServices _firebaseServices = FirebaseServices();
  final FavoritesService _favoritesService = FavoritesService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Data streams for My Listings
  Stream<List<ItemListing>>? _itemsStream;
  Stream<List<BusinessListing>>? _businessesStream;
  Stream<List<EventListing>>? _eventsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _initializeStreams();
  }

  void _initializeStreams() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _itemsStream = _firebaseServices.getUserItems(currentUser.uid);
      _businessesStream = _firebaseServices.getUserBusinesses(currentUser.uid);
      _eventsStream = _firebaseServices.getUserEvents(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Getting your location...'),
                ],
              ),
            ),
          ),
    );

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Navigator.pop(context); // Close loading dialog
        Get.snackbar(
          'Location Error',
          'Location services are disabled.',
     snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        );
        setState(() {
          _selectedLocation = 'All';
          _isLoadingLocation = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Navigator.pop(context); // Close loading dialog
          Get.snackbar(
            'Location Error',
            'Location permissions are denied',
    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
          );
          setState(() {
            _selectedLocation = 'All';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Navigator.pop(context); // Close loading dialog
        Get.snackbar(
          'Location Error',
          'Location permissions are permanently denied, we cannot request permissions.',
         snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        );
        setState(() {
          _selectedLocation = 'All';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = position;
        _isLoadingLocation = false;
      });

      Navigator.pop(context); // Close loading dialog
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      Get.snackbar(
        'Location Error',
        'Failed to get location: $e',
   snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      setState(() {
        _selectedLocation = 'All';
        _isLoadingLocation = false;
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1609.34; // Convert meters to miles
  }

  bool _isWithinSelectedRadius(double? lat, double? lon) {
    if (_selectedLocation == 'All' ||
        _userLocation == null ||
        lat == null ||
        lon == null) {
      return true;
    }

    double maxDistance = 0;
    switch (_selectedLocation) {
      case '10 miles':
        maxDistance = 10;
        break;
      case '50 miles':
        maxDistance = 50;
        break;
      case '300 miles':
        maxDistance = 300;
        break;
      case '500 miles':
        maxDistance = 500;
        break;
      default:
        return true;
    }

    double distance = _calculateDistance(
      _userLocation!.latitude,
      _userLocation!.longitude,
      lat,
      lon,
    );

    return distance <= maxDistance;
  }

  Widget _buildFilterPopupMenu({
    required String currentValue,
    required List<String> options,
    required Function(String) onSelected,
    required String title,
  }) {
    return PopupMenuButton<String>(
      color: Color(0xFFF2B342),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (title == 'Location' && value != 'All') {
          await _getUserLocation();
          if (_userLocation != null) {
            onSelected(value);
          }
        } else {
          onSelected(value);
        }
      },
      itemBuilder: (BuildContext context) {
        return options.map((String option) {
          return PopupMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: TextStyle(
                color:
                    option == currentValue ? Color(0xFF364C63) : Colors.white,
                fontWeight:
                    option == currentValue
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFD1D1D6), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.black)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8E8E8), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 80, height: 12, color: Colors.white),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      SizedBox(height: 4),
                      Container(width: 60, height: 16, color: Colors.white),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 60,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _passesFilters(CombinedListing listing) {
    // Search filter
    if (_searchQuery.isNotEmpty &&
        !listing.title.toLowerCase().contains(_searchQuery) &&
        !(listing.description?.toLowerCase().contains(_searchQuery) ?? false)) {
      return false;
    }

    // Category filter
    if (_selectedCategory != 'All') {
      List<String>? listingCategories;

      if (listing.originalData is ItemListing) {
        listingCategories = (listing.originalData as ItemListing).category;
      } else if (listing.originalData is BusinessListing) {
        listingCategories =
            (listing.originalData as BusinessListing).businessCategory;
      } else if (listing.originalData is EventListing) {
        listingCategories =
            (listing.originalData as EventListing).eventCategory;
      }

      if (listingCategories == null ||
          !listingCategories.any(
            (cat) => cat.toLowerCase() == _selectedCategory.toLowerCase(),
          )) {
        return false;
      }
    }

    // Location filter
    if (_selectedLocation != 'All' && _userLocation != null) {
      double? lat, lon;

      if (listing.originalData is ItemListing) {
        lat = (listing.originalData as ItemListing).latitude;
        lon = (listing.originalData as ItemListing).longitude;
      } else if (listing.originalData is BusinessListing) {
        lat = (listing.originalData as BusinessListing).latitude;
        lon = (listing.originalData as BusinessListing).longitude;
      } else if (listing.originalData is EventListing) {
        lat = (listing.originalData as EventListing).latitude;
        lon = (listing.originalData as EventListing).longitude;
      }

      if (!_isWithinSelectedRadius(lat, lon)) {
        return false;
      }
    }

    return true;
  }

  Widget _buildListingItem(CombinedListing listing) {
    if (!_passesFilters(listing)) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8E8E8), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      listing.paymentStatus == 'pending'
                          ? 'payment pending'
                          : listing.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            listing.paymentStatus == 'pending'
                                ? Colors.black
                                : listing.status == 'Published'
                                ? Color(0xFFF2B342)
                                : Color(0xFF8E8E93),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor(listing.type),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        listing.type.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  listing.title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (listing.price != null)
                  Text(
                    '£${listing.price!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFF2B342),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: appColors.darkBlue,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (listing.originalData is ItemListing) {
                            Get.to(
                              () => ListItemForm(),
                              arguments: listing.originalData as ItemListing,
                            );
                          } else if (listing.originalData is BusinessListing) {
                            Get.to(
                              () => ListBusinessForm(),
                              arguments:
                                  listing.originalData as BusinessListing,
                            );
                          } else if (listing.originalData is EventListing) {
                            Get.to(
                              () => ListEventForm(),
                              arguments: listing.originalData as EventListing,
                            );
                          }
                        },
                        child: Text(
                          'Edit',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () => _deleteListing(listing),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),

                    if (listing.paymentStatus == 'pending')
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFF2B342),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(
                              () => SubscriptionManagementScreen(
                                userId:
                                    FirebaseAuth.instance.currentUser?.uid ??
                                    '',
                              ),
                            );
                          },
                          child: Text(
                            'Pay',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              image:
                  listing.imageUrls.isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(listing.imageUrls.first),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                listing.imageUrls.isEmpty
                    ? Icon(Icons.image, color: Colors.grey[600])
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteItem item) {
    // Apply search filter
    if (_searchQuery.isNotEmpty &&
        !item.listingName.toLowerCase().contains(_searchQuery) &&
        !(item.category?.any((c) => c.toLowerCase().contains(_searchQuery)) ??
            false)) {
      return SizedBox.shrink();
    }

    // Apply category filter
    if (_selectedCategory != 'All' &&
        item.category != null &&
        !item.category!.any(
          (c) => c.toLowerCase() == _selectedCategory.toLowerCase(),
        )) {
      return SizedBox.shrink();
    }

    // Apply price filter for items
    if (_selectedPrice != 'All' &&
        item.listingType == 'Item' &&
        item.price != null) {
      bool matchesPrice = false;
      switch (_selectedPrice) {
        case '\$0-\$50':
          matchesPrice = item.price! <= 50;
          break;
        case '\$50-\$100':
          matchesPrice = item.price! > 50 && item.price! <= 100;
          break;
        case '\$100-\$200':
          matchesPrice = item.price! > 100 && item.price! <= 200;
          break;
        case '\$200+':
          matchesPrice = item.price! > 200;
          break;
      }
      if (!matchesPrice) return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _navigateToDetailScreen(item);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child:
                    item.listingImage != null && item.listingImage!.isNotEmpty
                        ? Image.network(
                          item.listingImage!,
                          width: 80.w,
                          height: 80.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80.w,
                              height: 80.h,
                              color: Colors.grey[200],
                              child: Icon(
                                _getIconForListingType(item.listingType),
                                color: Colors.grey[400],
                                size: 32.w,
                              ),
                            );
                          },
                        )
                        : Container(
                          width: 80.w,
                          height: 80.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            _getIconForListingType(item.listingType),
                            color: Colors.grey[400],
                            size: 32.w,
                          ),
                        ),
              ),
              SizedBox(width: 12.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Listing type badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getListingTypeColor(item.listingType),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        item.listingType,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Name
                    Text(
                      item.listingName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),

                    // Category
                    if (item.category != null)
                      Text(
                        (item.category ?? []).join(', '),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),

                    // Price for items
                    if (item.listingType == 'Item' && item.price != null)
                      Text(
                        '\$${item.price!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF2B342),
                        ),
                      ),

                    // Added date
                    if (item.addedAt != null)
                      Text(
                        'Added ${_formatDate(item.addedAt!)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),

              // Remove button
              IconButton(
                onPressed: () => _removeFavorite(item),
                icon: Icon(Icons.favorite, color: Colors.black, size: 24.w),
                tooltip: 'Remove from favorites',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'item':
        return Colors.blue;
      case 'business':
        return Colors.orange;
      case 'event':
        return Color(0xFFF2B342);
      default:
        return Colors.grey;
    }
  }

  Color _getListingTypeColor(String type) {
    switch (type) {
      case 'Item':
        return Color(0xFFF2B342);
      case 'Business':
        return Colors.blue;
      case 'Event':
        return Color(0xFFF2B342);
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForListingType(String type) {
    switch (type) {
      case 'Item':
        return Icons.shopping_bag;
      case 'Business':
        return Icons.business;
      case 'Event':
        return Icons.event;
      default:
        return Icons.favorite;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _editListing(CombinedListing listing) {
    print('Edit ${listing.type}: ${listing.title}');
    // TODO: Implement navigation to edit screens
  }

  void _deleteListing(CombinedListing listing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete ${listing.type}'),
          content: Text('Are you sure you want to delete "${listing.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performDelete(listing);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDelete(CombinedListing listing) async {
    try {
      switch (listing.type) {
        case 'item':
          await _firebaseServices.deleteItem(listing.id);
          break;
        case 'business':
          await _firebaseServices.deleteBusiness(listing.id);
          break;
        case 'event':
          await _firebaseServices.deleteEvent(listing.id);
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${listing.type} deleted successfully'),
          backgroundColor: Color(0xFFF2B342),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete ${listing.type}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFavorite(FavoriteItem item) async {
    final success = await _favoritesService.removeFromFavorites(item.listingId);
    if (success) {
      Get.snackbar(
        'Removed',
        '${item.listingName} removed from favorites',
   snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _clearAllFavorites() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text(
          'Are you sure you want to remove all favorites? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _favoritesService.clearAllFavorites();
      if (success) {
        Get.snackbar(
          'Cleared',
          'All favorites have been removed',
   snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void _navigateToDetailScreen(FavoriteItem item) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Loading...'),
                ],
              ),
            ),
          ),
    );

    try {
      dynamic product;
      Widget? page;

      switch (item.listingType) {
        case 'Item':
          print('Navigate to Item detail: ${item.listingId}');
          // Fetch from firestore
          DocumentSnapshot doc =
              await FirebaseFirestore.instance
                  .collection('items')
                  .doc(item.listingId)
                  .get();

          if (doc.exists) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            product = ItemListing.fromFirestore(data, doc.id);
          }
          break;

        case 'Business':
          print('Navigate to Business detail: ${item.listingId}');
          // Fetch from firestore
          DocumentSnapshot doc =
              await FirebaseFirestore.instance
                  .collection('businesses')
                  .doc(item.listingId)
                  .get();

          if (doc.exists) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            product = BusinessListing.fromFirestore(data, doc.id);
          }
          break;

        case 'Event':
          print('Navigate to Event detail: ${item.listingId}');
          // Fetch from firestore
          DocumentSnapshot doc =
              await FirebaseFirestore.instance
                  .collection('events')
                  .doc(item.listingId)
                  .get();

          if (doc.exists) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            product = EventListing.fromFirestore(data, doc.id);
          }
          break;
      }

      // Hide loading dialog
      Navigator.pop(context);

      // Navigate based on product type
      if (product != null) {
        if (product is ItemListing) {
          page = ItemProductDetailScreen(product: product);
        } else if (product is BusinessListing) {
          page = BusinessDetailScreen(business: product);
        } else if (product is EventListing) {
          page = EventDetailScreen(event: product);
        }

        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page!),
          );
        }
      } else {
        // Show error if product not found
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Item not found')));
      }
    } catch (e) {
      // Hide loading dialog on error
      Navigator.pop(context);
      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading item')));
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _tabController.index == 0
                ? Icons.inbox_outlined
                : Icons.favorite_border,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            _tabController.index == 0
                ? 'Start creating your first listing!'
                : 'Start exploring and add items to your favorites!',
            style: TextStyle(color: Colors.grey),
          ),
          if (_tabController.index == 1) ...[
            SizedBox(height: 24),
            CustomElevatedButton(
              text: 'Browse Listings',
              backgroundColor: Color(0xFFF2B342),
              textColor: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              borderRadius: 24,
              onTap: () {
                Get.back();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyListingsTab() {
    return StreamBuilder<List<ItemListing>>(
      stream: _itemsStream,
      builder: (context, itemSnapshot) {
        return StreamBuilder<List<BusinessListing>>(
          stream: _businessesStream,
          builder: (context, businessSnapshot) {
            return StreamBuilder<List<EventListing>>(
              stream: _eventsStream,
              builder: (context, eventSnapshot) {
                if (itemSnapshot.connectionState == ConnectionState.waiting ||
                    businessSnapshot.connectionState ==
                        ConnectionState.waiting ||
                    eventSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }

                if (itemSnapshot.hasError ||
                    businessSnapshot.hasError ||
                    eventSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading listings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please try again later',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final List<CombinedListing> allListings = [];

                if (itemSnapshot.hasData) {
                  allListings.addAll(
                    itemSnapshot.data!.map(
                      (item) => CombinedListing.fromItem(item),
                    ),
                  );
                }

                if (businessSnapshot.hasData) {
                  allListings.addAll(
                    businessSnapshot.data!.map(
                      (business) => CombinedListing.fromBusiness(business),
                    ),
                  );
                }

                if (eventSnapshot.hasData) {
                  allListings.addAll(
                    eventSnapshot.data!.map(
                      (event) => CombinedListing.fromEvent(event),
                    ),
                  );
                }

                allListings.sort((a, b) {
                  if (a.createdAt == null && b.createdAt == null) return 0;
                  if (a.createdAt == null) return 1;
                  if (b.createdAt == null) return -1;
                  return b.createdAt!.compareTo(a.createdAt!);
                });

                // Apply filters efficiently
                final filteredListings =
                    allListings.where(_passesFilters).toList();

                if (filteredListings.isEmpty) {
                  return _buildEmptyState(
                    _searchQuery.isNotEmpty ||
                            _selectedCategory != 'All' ||
                            _selectedLocation != 'All'
                        ? 'No results found'
                        : 'No listings found',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _initializeStreams();
                    });
                  },
                  child: ListView.builder(
                    itemCount: filteredListings.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Widget page;
                          if (filteredListings[index].type == 'item') {
                            page = ItemProductDetailScreen(
                              product:
                                  filteredListings[index].originalData
                                      as ItemListing,
                            );
                          } else if (filteredListings[index].type ==
                              'business') {
                            page = BusinessDetailScreen(
                              business:
                                  filteredListings[index].originalData
                                      as BusinessListing,
                            );
                          } else {
                            page = EventDetailScreen(
                              event:
                                  filteredListings[index].originalData
                                      as EventListing,
                            );
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => page),
                          );
                        },
                        child: _buildListingItem(filteredListings[index]),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return StreamBuilder<List<FavoriteItem>>(
      stream: _favoritesService.getUserFavorites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading favorites',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final favorites = snapshot.data ?? [];
        final filteredFavorites =
            favorites.where((item) {
              // Apply search filter
              if (_searchQuery.isNotEmpty &&
                  !item.listingName.toLowerCase().contains(_searchQuery) &&
                  !(item.category?.any(
                        (c) => c.toLowerCase().contains(_searchQuery),
                      ) ??
                      false)) {
                return false;
              }

              // Apply category filter
              if (_selectedCategory != 'All' &&
                  item.category != null &&
                  !item.category!.any(
                    (c) => c.toLowerCase() == _selectedCategory.toLowerCase(),
                  )) {
                return false;
              }

              // Apply price filter for items
              if (_selectedPrice != 'All' &&
                  item.listingType == 'Item' &&
                  item.price != null) {
                bool matchesPrice = false;
                switch (_selectedPrice) {
                  case '\$0-\$50':
                    matchesPrice = item.price! <= 50;
                    break;
                  case '\$50-\$100':
                    matchesPrice = item.price! > 50 && item.price! <= 100;
                    break;
                  case '\$100-\$200':
                    matchesPrice = item.price! > 100 && item.price! <= 200;
                    break;
                  case '\$200+':
                    matchesPrice = item.price! > 200;
                    break;
                }
                if (!matchesPrice) return false;
              }

              return true;
            }).toList();

        if (filteredFavorites.isEmpty) {
          String message =
              _searchQuery.isNotEmpty ||
                      _selectedCategory != 'All' ||
                      _selectedPrice != 'All'
                  ? 'No favorites found matching filters'
                  : 'No favorites yet';
          return _buildEmptyState(message);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filteredFavorites.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {},
                child: _buildFavoriteCard(filteredFavorites[index]),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and search
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                children: [
                  // Back button and search bar
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Icon(
                                  Icons.search,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF8E8E93),
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Tabs
                  Container(
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.black,
                      unselectedLabelColor: Color(0xFF8E8E93),
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                      indicatorColor: Colors.black,
                      indicatorWeight: 3,
                      tabs: [Tab(text: 'My Listings'), Tab(text: 'Favorites')],
                    ),
                  ),
                ],
              ),
            ),
            // Filters
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPopupMenu(
                      currentValue: _selectedCategory,
                      options: [
                        'All',
                        'All Other',
                        'Boutiques',
                        'Ranch Services',
                        'Western Retail Shops',
                        'Art',
                        'Decor',
                        'Furniture',
                        'Horses',
                        'Livestock',
                        'Miscellaneous',
                        'Tack',
                        'All Other Events',
                        'Barrel Races',
                        'Rodeos',
                        'Team Roping',
                        'Accessories',
                        'Kids',
                        'Mens',
                        'Womens',
                      ],
                      onSelected: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      title: 'Category',
                    ),
                    SizedBox(width: 12),
                    _buildFilterPopupMenu(
                      currentValue: _selectedLocation,
                      options: [
                        'All',
                        '10 miles',
                        '50 miles',
                        '300 miles',
                        '500 miles',
                      ],
                      onSelected: (value) {
                        setState(() {
                          _selectedLocation = value;
                        });
                      },
                      title: 'Location',
                    ),
                    SizedBox(width: 12),
                    _buildFilterPopupMenu(
                      currentValue: _selectedPrice,
                      options: [
                        'All',
                        '\$0-\$50',
                        '\$50-\$100',
                        '\$100-\$200',
                        '\$200+',
                      ],
                      onSelected: (value) {
                        setState(() {
                          _selectedPrice = value;
                        });
                      },
                      title: 'Price',
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildMyListingsTab(), _buildFavoritesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CombinedListing {
  final String id;
  final String title;
  final String? description;
  final double? price;
  final String status;
  final List<String> imageUrls;
  final String type; // 'item', 'business', 'event'
  final dynamic originalData;
  final DateTime? createdAt;
  final String? paymentStatus;

  CombinedListing({
    required this.id,
    required this.title,
    this.description,
    this.price,
    required this.status,
    required this.imageUrls,
    required this.type,
    required this.originalData,
    this.paymentStatus,
    this.createdAt,
  });

  static CombinedListing fromItem(ItemListing item) {
    return CombinedListing(
      id: item.id ?? '',
      title: item.itemName ?? 'Untitled Item',
      description: item.description,
      price: item.price?.toDouble(),
      status: item.isActive == true ? 'Published' : 'Draft',
      imageUrls: item.photoUrls ?? [],
      type: 'item',
      originalData: item,
      paymentStatus: item.paymentStatus,
      createdAt: item.createdAt,
    );
  }

  static CombinedListing fromBusiness(BusinessListing business) {
    return CombinedListing(
      id: business.id ?? '',
      title: business.businessName ?? 'Untitled Business',
      description: business.description,
      price: null,
      status: business.isActive == true ? 'Published' : 'Draft',
      imageUrls: business.photoUrls ?? [],
      type: 'business',
      paymentStatus: 'pending',
      originalData: business,
      createdAt: business.createdAt,
    );
  }

  static CombinedListing fromEvent(EventListing event) {
    return CombinedListing(
      id: event.id ?? '',
      title: event.eventName ?? 'Untitled Event',
      description: event.description,
      price: 0,
      status: event.isActive == true ? 'Published' : 'Draft',
      imageUrls: event.photoUrls ?? [],
      type: 'event',
      originalData: event,
      paymentStatus: 'pending',
      createdAt: event.createdAt,
    );
  }
}
