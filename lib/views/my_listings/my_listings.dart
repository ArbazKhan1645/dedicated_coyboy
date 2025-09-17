// ignore_for_file: use_build_context_synchronously

import 'package:dedicated_cowboy/app/models/api_user_model.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/views/word_listings/model.dart';
import 'package:dedicated_cowboy/views/word_listings/service.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// New Listing Model
class Listing {
  final int id;
  final String title;
  final String content;
  final String status;
  final String dateCreated;
  final String dateModified;
  final String authorId;
  final String address;
  final String? latitude;
  final String? longitude;
  final String price;
  final String phone;
  final String email;
  final String customText;
  final String expiryDate;
  final Map<String, dynamic>? featuredImage;
  final List<Map<String, dynamic>>? galleryImages;
  final List<Map<String, dynamic>>? categories;
  final List<Map<String, dynamic>>? listingTypes;
  final List<Map<String, dynamic>>? locations;

  Listing({
    required this.id,
    required this.title,
    required this.content,
    required this.status,
    required this.dateCreated,
    required this.dateModified,
    required this.authorId,
    required this.address,
    this.latitude,
    this.longitude,
    required this.price,
    required this.phone,
    required this.email,
    required this.customText,
    required this.expiryDate,
    this.featuredImage,
    this.galleryImages,
    this.categories,
    this.listingTypes,
    this.locations,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      status: json['status'] ?? '',
      dateCreated: json['date_created'] ?? '',
      dateModified: json['date_modified'] ?? '',
      authorId: json['author_id']?.toString() ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      price: json['price']?.toString() ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      customText: json['custom_text'] ?? '',
      expiryDate: json['expiry_date'] ?? '',
      featuredImage: json['featured_image'],
      galleryImages: json['gallery_images']?.cast<Map<String, dynamic>>(),
      categories: json['categories']?.cast<Map<String, dynamic>>(),
      listingTypes: json['listing_types']?.cast<Map<String, dynamic>>(),
      locations: json['locations']?.cast<Map<String, dynamic>>(),
    );
  }

  // Helper getters for compatibility
  String get cleanContent => content.replaceAll(RegExp(r'<[^>]*>'), '');

  String get listingType {
    if (listingTypes != null && listingTypes!.isNotEmpty) {
      return listingTypes!.first['name']?.toString().toLowerCase() ?? 'item';
    }
    return 'item';
  }

  bool get isItem => listingType == 'item';
  bool get isBusiness => listingType == 'business';
  bool get isEvent => listingType == 'event';

  double? get priceAsDouble {
    if (price.isEmpty) return null;
    return double.tryParse(price);
  }

  String? get featuredImageUrl {
    return featuredImage?['full'];
  }

  List<String>? get categoryNames {
    return categories?.map((cat) => cat['name']?.toString() ?? '').toList();
  }

  DateTime? get createdAt {
    return DateTime.tryParse(dateCreated);
  }
}

// API Service for direct calls
class ListingApiService {
  static const String baseUrl = 'https://dedicatedcowboy.com/wp-json/cowboy/v1';

  Future<List<Listing>> getUserListings(int authorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/listings?author=$authorId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => Listing.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching user listings: $e');
      return [];
    }
  }

  Future<Listing?> getListingById(int listingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/listings/$listingId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Listing.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching listing $listingId: $e');
      return null;
    }
  }
}

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

  // API service for user listings only
  final ListingApiService _listingService = ListingApiService();

  // Old service for favorites
  final WordPressListingService _favoriteListingService =
      WordPressListingService();
  final AuthService _authService = AuthService();

  // Data lists
  List<Listing> _userListings = [];
  List<UnifiedListing> _favoriteListings = [];
  List<Listing> _filteredUserListings = [];
  List<UnifiedListing> _filteredFavoriteListings = [];

  bool _isLoadingUserListings = true;
  bool _isLoadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadData();
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
      _applyFilters();
    });
  }

  Future<void> _loadData() async {
    // Refresh user info first to get updated favorite IDs
    await _refreshUserInfo();

    await Future.wait([_loadUserListings(), _loadFavoriteListings()]);
  }

  Future<void> _refreshUserInfo() async {
    try {
      // Refresh user data from your auth service to get updated favorites
      await _authService.refreshUser(); // You'll need to implement this method
    } catch (e) {
      print('Error refreshing user info: $e');
    }
  }

  Future<void> _loadUserListings() async {
    setState(() {
      _isLoadingUserListings = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser?.id != null) {
        final listings = await _listingService.getUserListings(
          int.tryParse(currentUser?.id ?? '') ?? 0,
        );

        setState(() {
          _userListings = listings;
          _isLoadingUserListings = false;
        });
        _applyFilters();
      } else {
        setState(() {
          _userListings = [];
          _isLoadingUserListings = false;
        });
        _applyFilters();
      }
    } catch (e) {
      print('Error loading user listings: $e');
      setState(() {
        _userListings = [];
        _isLoadingUserListings = false;
      });
      _applyFilters();
    }
  }

  Future<void> _loadFavoriteListings() async {
    setState(() {
      _isLoadingFavorites = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser?.favouriteListings != null &&
          currentUser!.favouriteListings!.isNotEmpty) {
        List<UnifiedListing> favorites = [];

        // Fetch each favorite listing by ID using the old service
        for (int listingId in currentUser.favouriteListings!) {
          try {
            final listing = await _favoriteListingService.getListingById(
              listingId,
            );
            if (listing != null) {
              favorites.add(listing);
            }
          } catch (e) {
            print('Error fetching listing $listingId: $e');
          }
        }

        setState(() {
          _favoriteListings = favorites;
          _isLoadingFavorites = false;
        });
      } else {
        setState(() {
          _favoriteListings = [];
          _isLoadingFavorites = false;
        });
      }
      _applyFilters();
    } catch (e) {
      print('Error loading favorite listings: $e');
      setState(() {
        _favoriteListings = [];
        _isLoadingFavorites = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    _filteredUserListings = _filterUserListings(_userListings);
    _filteredFavoriteListings = _filterListings(_favoriteListings);
  }

  List<UnifiedListing> _filterListings(List<UnifiedListing> listings) {
    List<UnifiedListing> filtered = List.from(listings);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((listing) {
            final title = listing.title?.toLowerCase() ?? '';
            final content = listing.cleanContent.toLowerCase();
            return title.contains(_searchQuery) ||
                content.contains(_searchQuery);
          }).toList();
    }

    // Category filter
    // if (_selectedCategory != 'All') {
    //   filtered = filtered.where((listing) {
    //     return listing.categories?.any((cat) =>
    //       cat.toLowerCase() == _selectedCategory.toLowerCase()) ?? false;
    //   }).toList();
    // }

    // Location filter
    if (_selectedLocation != 'All' && _userLocation != null) {
      filtered =
          filtered.where((listing) {
            if (listing.latitude == null || listing.longitude == null) {
              return false;
            }
            return _isWithinSelectedRadius(
              listing.latitude!,
              listing.longitude!,
            );
          }).toList();
    }

    // Price filter (only for items)
    if (_selectedPrice != 'All') {
      filtered =
          filtered.where((listing) {
            if (!listing.isItem || listing.priceAsDouble == null) return true;

            double price = listing.priceAsDouble!;
            switch (_selectedPrice) {
              case '\$0-\$50':
                return price <= 50;
              case '\$50-\$100':
                return price > 50 && price <= 100;
              case '\$100-\$200':
                return price > 100 && price <= 200;
              case '\$200+':
                return price > 200;
              default:
                return true;
            }
          }).toList();
    }

    return filtered;
  }

  // Separate filter method for user listings (new Listing model)
  List<Listing> _filterUserListings(List<Listing> listings) {
    List<Listing> filtered = List.from(listings);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((listing) {
            final title = listing.title.toLowerCase();
            final content = listing.cleanContent.toLowerCase();
            return title.contains(_searchQuery) ||
                content.contains(_searchQuery);
          }).toList();
    }

    // Category filter
    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((listing) {
            return listing.categoryNames?.any(
                  (cat) => cat.toLowerCase() == _selectedCategory.toLowerCase(),
                ) ??
                false;
          }).toList();
    }

    // Location filter
    if (_selectedLocation != 'All' && _userLocation != null) {
      filtered =
          filtered.where((listing) {
            if (listing.latitude == null || listing.longitude == null) {
              return false;
            }
            return _isWithinSelectedRadius(
              double.parse(listing.latitude!),
              double.parse(listing.longitude!),
            );
          }).toList();
    }

    // Price filter (only for items)
    if (_selectedPrice != 'All') {
      filtered =
          filtered.where((listing) {
            if (!listing.isItem || listing.priceAsDouble == null) return true;

            double price = listing.priceAsDouble!;
            switch (_selectedPrice) {
              case '\$0-\$50':
                return price <= 50;
              case '\$50-\$100':
                return price > 50 && price <= 100;
              case '\$100-\$200':
                return price > 100 && price <= 200;
              case '\$200+':
                return price > 200;
              default:
                return true;
            }
          }).toList();
    }

    return filtered;
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Navigator.pop(context);
        _showLocationError('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Navigator.pop(context);
          _showLocationError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Navigator.pop(context);
        _showLocationError('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = position;
        _isLoadingLocation = false;
      });

      Navigator.pop(context);
      _applyFilters();
    } catch (e) {
      Navigator.pop(context);
      _showLocationError('Failed to get location: $e');
    }
  }

  void _showLocationError(String message) {
    Get.snackbar(
      'Location Error',
      message,
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

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1609.34;
  }

  bool _isWithinSelectedRadius(double lat, double lon) {
    if (_selectedLocation == 'All' || _userLocation == null) {
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

  Widget _buildListingItem(Listing listing) {
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
                      listing.status == 'publish' ? 'Published' : 'Draft',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            listing.status == 'publish'
                                ? Color(0xFFF2B342)
                                : Color(0xFF8E8E93),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor(listing.listingType),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        listing.listingType.toUpperCase(),
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
                if (listing.priceAsDouble != null)
                  Text(
                    '\$${listing.priceAsDouble!.toStringAsFixed(2)}',
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
                        onTap: () => _editListing(listing),
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
                  listing.featuredImageUrl != null
                      ? DecorationImage(
                        image: NetworkImage(listing.featuredImageUrl!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                listing.featuredImageUrl == null
                    ? Icon(Icons.image, color: Colors.grey[600])
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(UnifiedListing listing) {
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
        onTap: () => _navigateToDetailScreen(listing),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child:
                    listing.featuredImageUrl != null
                        ? Image.network(
                          listing.featuredImageUrl!,
                          width: 80.w,
                          height: 80.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80.w,
                              height: 80.h,
                              color: Colors.grey[200],
                              child: Icon(
                                _getIconForListingType(listing.listingType),
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
                            _getIconForListingType(listing.listingType),
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
                        color: _getListingTypeColor(listing.listingType),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        listing.listingType,
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
                      listing.title ?? 'Untitled',
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
                    if (listing.categories != null &&
                        listing.categories!.isNotEmpty)
                      Text(
                        listing.categories!.join(', '),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    // Price for items
                    if (listing.isItem && listing.priceAsDouble != null)
                      Text(
                        '\$${listing.priceAsDouble!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF2B342),
                        ),
                      ),
                    // Added date
                    if (listing.createdAt != null)
                      Text(
                        'Added ${_formatDate(listing.createdAt!)}',
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
                onPressed: () => _removeFavorite(listing),
                icon: Icon(Icons.favorite, color: Colors.red, size: 24.w),
                tooltip: 'Remove from favorites',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
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
      case 'item':
        return Color(0xFFF2B342);
      case 'business':
        return Colors.blue;
      case 'event':
        return Color(0xFFF2B342);
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForListingType(String type) {
    switch (type) {
      case 'item':
        return Icons.shopping_bag;
      case 'business':
        return Icons.business;
      case 'event':
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

  void _editListing(Listing listing) {
    print('Edit ${listing.listingType}: ${listing.title}');
    // TODO: Implement navigation to edit screens based on listing type
  }

  void _deleteListing(Listing listing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete ${listing.listingType}'),
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

  Future<void> _performDelete(Listing listing) async {
    try {
      // TODO: Implement delete API calls based on your API

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${listing.listingType} deleted successfully'),
          backgroundColor: Color(0xFFF2B342),
        ),
      );

      // Refresh the data
      _loadUserListings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete ${listing.listingType}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFavorite(UnifiedListing listing) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Remove from local list
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

        // Refresh user info and favorites
        await _refreshUserInfo();
        _loadFavoriteListings();
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
      try {
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          currentUser.favouriteListings?.clear();
          // TODO: Update user favorites in your backend/API
          // await _authService.updateUserFavorites([]);

          Get.snackbar(
            'Cleared',
            'All favorites have been removed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Color(0xFFF2B342),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );

          // Refresh user info and favorites
          await _refreshUserInfo();
          _loadFavoriteListings();
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to clear favorites',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void _navigateToDetailScreen(dynamic listing) async {
    try {
      // TODO: Navigate to detail screen based on listing type
      // You'll need to implement this based on your existing detail screens

      Widget? page;
      String listingType;
      String title;

      // Handle both Listing and UnifiedListing types
      if (listing is Listing) {
        listingType = listing.listingType;
        title = listing.title;

        if (listing.isItem) {
          // page = ItemProductDetailScreen(product: listing);
        } else if (listing.isBusiness) {
          // page = BusinessDetailScreen(business: listing);
        } else if (listing.isEvent) {
          // page = EventDetailScreen(event: listing);
        }
      } else if (listing is UnifiedListing) {
        listingType = listing.listingType;
        title = listing.title ?? 'Untitled';

        if (listing.isItem) {
          // page = ItemProductDetailScreen(product: listing);
        } else if (listing.isBusiness) {
          // page = BusinessDetailScreen(business: listing);
        } else if (listing.isEvent) {
          // page = EventDetailScreen(event: listing);
        }
      }

      if (page != null) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page!));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading item details')));
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
    if (_isLoadingUserListings) {
      return _buildShimmerLoading();
    }

    if (_filteredUserListings.isEmpty) {
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
        await _loadUserListings();
      },
      child: ListView.builder(
        itemCount: _filteredUserListings.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _navigateToDetailScreen(_filteredUserListings[index]),
            child: _buildListingItem(_filteredUserListings[index]),
          );
        },
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_isLoadingFavorites) {
      return _buildShimmerLoading();
    }

    if (_filteredFavoriteListings.isEmpty) {
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
        await _refreshUserInfo();
        await _loadFavoriteListings();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredFavoriteListings.length,
        itemBuilder: (context, index) {
          return _buildFavoriteCard(_filteredFavoriteListings[index]);
        },
      ),
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
                    SizedBox(width: 24),
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
                          _applyFilters();
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
                          _applyFilters();
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
                          _applyFilters();
                        });
                      },
                      title: 'Price',
                    ),
                    SizedBox(width: 24),
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
