import 'dart:math';

import 'package:dedicated_cowboy/app/services/chat_room_service/chat_room_service.dart';
import 'package:dedicated_cowboy/app/services/favorite_service/fav_service.dart';
import 'package:dedicated_cowboy/views/browser/browser.dart';
import 'package:dedicated_cowboy/views/chats/chats_view.dart';
import 'package:dedicated_cowboy/views/products_listings/helpers.dart';
import 'package:dedicated_cowboy/views/products_listings/listing_location.dart';
import 'package:dedicated_cowboy/views/reports/my_reports.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dedicated_cowboy/app/services/listings_service.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:photo_view/photo_view.dart';

import 'package:dedicated_cowboy/app/models/modules_models/item_model.dart';
import 'package:dedicated_cowboy/app/models/modules_models/business_model.dart';
import 'package:dedicated_cowboy/app/models/modules_models/event_model.dart';

// Create a base class for all listings
abstract class BaseListing {
  String? get id;
  String? get name;
  String? get description;
  List<String>? get category;
  String? get userId;
  List<String>? get photoUrls;
  DateTime? get createdAt;
  double? get latitude;
  double? get longitude;
  bool? get isActive;
}

// Extend your existing models to implement BaseListing
class ListingWrapper implements BaseListing {
  final dynamic _listing;
  final String _type;

  ListingWrapper(this._listing, this._type);

  String get type => _type;
  dynamic get listing => _listing;

  @override
  String? get id {
    if (_listing is ItemListing) return (_listing).id;
    if (_listing is BusinessListing) return (_listing).id;
    if (_listing is EventListing) return (_listing).id;
    return null;
  }

  @override
  String? get name {
    if (_listing is ItemListing) return (_listing).itemName;
    if (_listing is BusinessListing) return (_listing).businessName;
    if (_listing is EventListing) return (_listing).eventName;
    return null;
  }

  @override
  String? get description {
    if (_listing is ItemListing) return (_listing).description;
    if (_listing is BusinessListing) return (_listing).description;
    if (_listing is EventListing) return (_listing).description;
    return null;
  }

  @override
  List<String>? get category {
    if (_listing is ItemListing) return (_listing).category;
    if (_listing is BusinessListing) return (_listing).businessCategory;
    if (_listing is EventListing) return (_listing).eventCategory;
    return null;
  }

  @override
  String? get userId {
    if (_listing is ItemListing) return (_listing).userId;
    if (_listing is BusinessListing) return (_listing).userId;
    if (_listing is EventListing) return (_listing).userId;
    return null;
  }

  @override
  List<String>? get photoUrls {
    if (_listing is ItemListing) return (_listing).photoUrls;
    if (_listing is BusinessListing) return (_listing).photoUrls;
    if (_listing is EventListing) return (_listing).photoUrls;
    return null;
  }

  @override
  DateTime? get createdAt {
    if (_listing is ItemListing) return (_listing).createdAt;
    if (_listing is BusinessListing) return (_listing).createdAt;
    if (_listing is EventListing) return (_listing).createdAt;
    return null;
  }

  @override
  double? get latitude {
    if (_listing is ItemListing) return (_listing).latitude;
    if (_listing is BusinessListing) return (_listing).latitude;
    if (_listing is EventListing) return (_listing).latitude;
    return null;
  }

  @override
  double? get longitude {
    if (_listing is ItemListing) return (_listing).longitude;
    if (_listing is BusinessListing) return (_listing).longitude;
    if (_listing is EventListing) return (_listing).longitude;
    return null;
  }

  @override
  bool? get isActive {
    if (_listing is ItemListing) return (_listing).isActive;
    if (_listing is BusinessListing) return (_listing).isActive;
    if (_listing is EventListing) return (_listing).isActive;
    return null;
  }

  // Additional properties for specific types
  double? get price {
    if (_listing is ItemListing) return (_listing).price;
    return null;
  }

  String? get condition {
    if (_listing is ItemListing) return (_listing).condition;
    return null;
  }

  bool? get isVerified {
    if (_listing is BusinessListing) return (_listing).isVerified;
    return null;
  }

  DateTime? get eventStartDate {
    if (_listing is EventListing) return (_listing).eventStartDate;
    return null;
  }

  DateTime? get eventEndDate {
    if (_listing is EventListing) return (_listing).eventEndDate;
    return null;
  }
}

class ProductListingScreen extends StatefulWidget {
  final List<String> initialCategory;
  final List<String> categories;
  final Function(dynamic)
  onProductTap; // Changed to dynamic to handle all types
  final Map<String, dynamic>? appliedFilters;

  const ProductListingScreen({
    super.key,
    required this.initialCategory,
    required this.categories,
    required this.onProductTap,
    this.appliedFilters,
  });

  @override
  _ProductListingScreenState createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  String sortBy = '';
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  List<String> currentCategories = [];
  Map<String, dynamic> currentFilters = {};

  // Firebase services
  final FirebaseServices _firebaseServices = FirebaseServices();
  Stream<List<ListingWrapper>>? _listingsStream;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _initializeStream();
  }

  void _initializeFilters() {
    // Check if filters are passed from Browse screen
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      currentFilters = Map<String, dynamic>.from(
        Get.arguments as Map<String, dynamic>,
      );
    } else if (widget.appliedFilters != null) {
      currentFilters = Map<String, dynamic>.from(widget.appliedFilters!);
    } else {}

    // Set initial values from filters
    currentCategories =
        (currentFilters['category'] is String)
            ? [currentFilters['category']]
            : (currentFilters['category'] as List<String>?) ??
                widget.initialCategory;

    searchQuery = currentFilters['searchQuery'] ?? '';

    searchController.text = searchQuery;
  }

  void _initializeStream() {
    // Get listing type from filters, default to 'All'
    String listingType = currentFilters['listingType'] ?? 'All';
    if (currentCategories.length == 1 && currentCategories[0] == 'All') {
      _listingsStream = _getCombinedListingsStream(listingType);
    } else {
      _listingsStream = _getCombinedListingsByCategoryStream(
        currentCategories,
        listingType,
      );
    }
  }

  Stream<List<ListingWrapper>> _getCombinedListingsStream(String listingType) {
    List<Stream<List<ListingWrapper>>> streams = [];

    if (listingType == 'All' || listingType == 'Item') {
      streams.add(
        _firebaseServices.getAllItems().map(
          (items) => items.map((item) => ListingWrapper(item, 'Item')).toList(),
        ),
      );
    }

    if (listingType == 'All' || listingType == 'Business') {
      streams.add(
        _firebaseServices.getAllBusinesses().map(
          (businesses) =>
              businesses
                  .map((business) => ListingWrapper(business, 'Business'))
                  .toList(),
        ),
      );
    }

    if (listingType == 'All' || listingType == 'Event') {
      streams.add(
        _firebaseServices.getUpcomingEvents().map(
          (events) =>
              events.map((event) => ListingWrapper(event, 'Event')).toList(),
        ),
      );
    }

    if (streams.isEmpty) {
      return Stream.value([]);
    }

    // Combine all streams
    return _combineStreams(streams);
  }

  Stream<List<ListingWrapper>> _getCombinedListingsByCategoryStream(
    List<String> category,
    String listingType,
  ) {
    List<Stream<List<ListingWrapper>>> streams = [];

    if (listingType == 'All' || listingType == 'Item') {
      streams.add(
        _firebaseServices
            .getItemsByCategory(category)
            .map(
              (items) =>
                  items.map((item) => ListingWrapper(item, 'Item')).toList(),
            ),
      );
    }

    if (listingType == 'All' || listingType == 'Business') {
      streams.add(
        _firebaseServices
            .getBusinessesByCategory(category)
            .map(
              (businesses) =>
                  businesses
                      .map((business) => ListingWrapper(business, 'Business'))
                      .toList(),
            ),
      );
    }

    if (listingType == 'All' || listingType == 'Event') {
      streams.add(
        _firebaseServices
            .getEventsByCategory(category)
            .map(
              (events) =>
                  events
                      .map((event) => ListingWrapper(event, 'Event'))
                      .toList(),
            ),
      );
    }

    if (streams.isEmpty) {
      return Stream.value([]);
    }

    return _combineStreams(streams);
  }

  Stream<List<ListingWrapper>> _combineStreams(
    List<Stream<List<ListingWrapper>>> streams,
  ) {
    if (streams.length == 1) {
      return streams.first;
    }

    return streams.reduce((stream1, stream2) {
      return stream1.asyncMap((list1) async {
        final list2 = await stream2.first;
        return [...list1, ...list2];
      });
    });
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusMiles = 3959.0; // Earth's radius in miles

    // Convert degrees to radians
    double lat1Rad = lat1 * (3.14159265359 / 180.0);
    double lng1Rad = lng1 * (3.14159265359 / 180.0);
    double lat2Rad = lat2 * (3.14159265359 / 180.0);
    double lng2Rad = lng2 * (3.14159265359 / 180.0);

    // Calculate differences
    double dLat = lat2Rad - lat1Rad;
    double dLng = lng2Rad - lng1Rad;

    // Apply Haversine formula
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1Rad) * cos(lat2Rad) * sin(dLng / 2) * sin(dLng / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Calculate distance in miles
    double distance = earthRadiusMiles * c;

    return distance;
  }

  List<ListingWrapper> _filterProducts(List<ListingWrapper> products) {
    List<ListingWrapper> filtered = products;

    // Apply listing type filter
    String listingType = currentFilters['listingType'] ?? 'All';
    if (listingType != 'All') {
      filtered =
          filtered.where((product) => product.type == listingType).toList();
    }

    // Apply search filter
    String searchTerm = currentFilters['searchQuery'] ?? searchQuery;
    if (searchTerm.isNotEmpty) {
      filtered =
          filtered.where((product) {
            final title = product.name?.toLowerCase() ?? '';
            final description = product.description?.toLowerCase() ?? '';
            final categories = product.category ?? []; // this is a List<String>

            return title.contains(searchTerm.toLowerCase()) ||
                description.contains(searchTerm.toLowerCase()) ||
                categories.any(
                  (c) => c.toLowerCase().contains(searchTerm.toLowerCase()),
                );
          }).toList();
    }

    // Apply price range filter (only for Items)
    if (currentFilters['priceRange'] != null) {
      double maxPrice = currentFilters['priceRange'].toDouble();
      filtered =
          filtered.where((product) {
            if (product.type != 'Item' || product.price == null) return true;
            return product.price! <= maxPrice;
          }).toList();
    }

    // Apply location radius filter if needed
    if (currentFilters['radiusRange'] != null &&
        currentFilters['latitude'] != null &&
        currentFilters['longitude'] != null) {
      double userLat = currentFilters['latitude'].toDouble();
      double userLng = currentFilters['longitude'].toDouble();
      double maxRadius = currentFilters['radiusRange'].toDouble(); // in miles

      filtered =
          filtered.where((product) {
            // Check if product has valid coordinates
            if (product.latitude == null ||
                product.longitude == null ||
                product.latitude == 0.0 ||
                product.longitude == 0.0) {
              return false; // Exclude products without valid location data
            }

            double productLat = product.latitude!.toDouble();
            double productLng = product.longitude!.toDouble();

            // Calculate distance between user location and product location
            double distance = _calculateDistance(
              userLat,
              userLng,
              productLat,
              productLng,
            );

            // Return true if product is within the specified radius
            return distance <= maxRadius;
          }).toList();
    }

    // Apply sorting
    _sortProducts(filtered);

    return filtered;
  }

  void _sortProducts(List<ListingWrapper> products) {
    switch (sortBy) {
      case 'Price: Low to High':
        products.sort((a, b) {
          double priceA = a.price ?? double.infinity;
          double priceB = b.price ?? double.infinity;
          return priceA.compareTo(priceB);
        });
        break;
      case 'Price: High to Low':
        products.sort((a, b) {
          double priceA = a.price ?? 0;
          double priceB = b.price ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'Name: A to Z':
        products.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        break;
      case 'Name: Z to A':
        products.sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
        break;
      case 'Newest First':
        products.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case 'Sort By':
        products.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
      case '':
        products.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });

      default:
        products.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
    }
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        searchController.clear();
        searchQuery = '';
        // Update filters to remove search query
        currentFilters.remove('searchQuery');
        _initializeStream(); // Reinitialize stream when clearing search
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      if (value.isEmpty) {
        currentFilters.remove('searchQuery');
      } else {
        currentFilters['searchQuery'] = value;
      }
    });
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: BrowseFilterScreen(
            initialFilters: currentFilters,
            mainRoute: false,
          ),
        );
      },
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          // Create a fresh copy of filters
          currentFilters = Map<String, dynamic>.from(result);
          currentCategories = [result['category'] ?? ''];
          searchQuery = result['searchQuery'] ?? '';
          searchController.text = searchQuery;
          _initializeStream(); // Always reinitialize stream when filters change
        });
      }
    });
  }

  void _showCategoryBottomSheet(BuildContext context) {
    if (currentCategories.length == 1 && currentCategories[0] == 'All') {
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.categories.length,
                  itemBuilder: (context, index) {
                    final category = widget.categories[index];
                    return ListTile(
                      title: Text(category),
                      trailing: () {
                        if (category == 'All') {
                          // "All" is selected if *every* category except "All" is selected
                          return currentCategories.length ==
                                  widget.categories.length
                              ? Icon(Icons.check, color: Color(0xFFF2B342))
                              : null;
                        } else {
                          if (currentCategories.length ==
                              widget.categories.length) {
                            return null;
                          }
                          // Normal category check
                          return currentCategories.contains(category)
                              ? Icon(Icons.check, color: Color(0xFFF2B342))
                              : null;
                        }
                      }(),

                      onTap: () {
                        setState(() {
                          if (category == 'All') {
                            currentCategories = widget.categories;
                          } else {
                            currentCategories = ['All', category];
                          }

                          currentFilters['category'] = category;
                          _initializeStream();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveFiltersChips() {
    List<Widget> chips = [];

    // Listing type chip
    String listingType = currentFilters['listingType'] ?? 'All';
    if (listingType != 'All') {
      chips.add(
        _buildFilterChip(listingType, () {
          setState(() {
            currentFilters.remove('listingType');
            _initializeStream(); // Reinitialize stream when removing filter
          });
        }),
      );
    }

    // Price range chip (only for Items)
    if (currentFilters['priceRange'] != null) {
      double price = currentFilters['priceRange'].toDouble();
      chips.add(
        _buildFilterChip('Under \$${price.round()}', () {
          setState(() {
            currentFilters.remove('priceRange');
            // Don't need to reinitialize stream for price filter as it's applied client-side
          });
        }),
      );
    }

    // Location chip
    if (currentFilters['useMyLocation'] == true) {
      chips.add(
        _buildFilterChip('My Location', () {
          setState(() {
            currentFilters.remove('useMyLocation');
            currentFilters.remove('latitude');
            currentFilters.remove('longitude');
            currentFilters.remove('radiusRange');
            // Don't need to reinitialize stream for location filter as it's applied client-side
          });
        }),
      );
    } else if (currentFilters['address']?.isNotEmpty == true) {
      chips.add(
        _buildFilterChip('Custom Location', () {
          setState(() {
            currentFilters.remove('address');
            currentFilters.remove('latitude');
            currentFilters.remove('longitude');
            currentFilters.remove('radiusRange');
            // Don't need to reinitialize stream for location filter as it's applied client-side
          });
        }),
      );
    }

    if (chips.isEmpty) return SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: chips,
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFF2B342).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFF2B342)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFFF2B342),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: Color(0xFFF2B342)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFEDEDED),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 14,
                          color: Colors.white,
                        ),
                        SizedBox(height: 4),
                        Container(width: 80, height: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _showFilterBottomSheet(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF2B342),
              foregroundColor: Colors.white,
            ),
            child: Text('Adjust Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error loading listings $error',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text('Please try again later', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _initializeStream();
              });
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String listingType = currentFilters['listingType'] ?? 'All';

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            isSearching
                ? TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText:
                        'Search ${listingType.toLowerCase() == 'all' ? 'listings' : '${listingType.toLowerCase()}s'}...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  onChanged: _onSearchChanged,
                )
                : GestureDetector(
                  onTap: () => _showCategoryBottomSheet(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentCategories.isEmpty
                                    ? 'All'
                                    : currentCategories.length == 1 &&
                                        currentCategories[0] == 'All'
                                    ? 'All'
                                    : currentCategories
                                        .where((e) => e != 'All')
                                        .join(', '),
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (currentCategories.isNotEmpty &&
                                currentCategories.length > 1)
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: Colors.black,
            ),
            onPressed: _toggleSearch,
          ),
          // IconButton(
          //   icon: Stack(
          //     children: [
          //       Icon(Icons.filter_list, color: Colors.black),
          //       if (_hasActiveFilters())
          //         Positioned(
          //           right: 0,
          //           top: 0,
          //           child: Container(
          //             width: 8,
          //             height: 8,
          //             decoration: BoxDecoration(
          //               color: Color(0xFFF2B342),
          //               shape: BoxShape.circle,
          //             ),
          //           ),
          //         ),
          //     ],
          //   ),
          //   onPressed: () => _showFilterBottomSheet(context),
          // ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Active filters chips
            _buildActiveFiltersChips(),
            if (_hasActiveFilters()) SizedBox(height: 8),

            // Items found and sort section
            StreamBuilder<List<ListingWrapper>>(
              stream: _listingsStream,
              builder: (context, snapshot) {
                final filteredProducts =
                    snapshot.hasData
                        ? _filterProducts(snapshot.data!)
                        : <ListingWrapper>[];

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredProducts.length} ${_getPluralListingType(listingType)} found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (String value) {
                          setState(() {
                            sortBy = value;
                          });
                        },
                        color: Color(0xFFF2B342),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        itemBuilder:
                            (BuildContext context) => [
                              PopupMenuItem(
                                value: '',
                                child: Center(
                                  child: Text(
                                    'All',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              if (listingType == 'Item' ||
                                  listingType == 'All') ...[
                                PopupMenuItem(
                                  value: 'Price: Low to High',
                                  child: Center(
                                    child: Text(
                                      'Price: Low to High',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'Price: High to Low',
                                  child: Center(
                                    child: Text(
                                      'Price: High to Low',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                              PopupMenuItem(
                                value: 'Name: A to Z',
                                child: Center(
                                  child: Text(
                                    'Name: A to Z',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'Name: Z to A',
                                child: Center(
                                  child: Text(
                                    'Name: Z to A',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'Newest First',
                                child: Center(
                                  child: Text(
                                    'Newest First',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xffD9D9D9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sortBy == '' ? 'sort by' : sortBy,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey[600],
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Search results message
            if (searchQuery.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Results for "$searchQuery"',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            // Listings Grid
            StreamBuilder<List<ListingWrapper>>(
              stream: _listingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(
                    searchQuery.isNotEmpty
                        ? 'No ${_getPluralListingType(listingType)} found for "$searchQuery"'
                        : 'No ${_getPluralListingType(listingType)} found in selected categories\nBe the first to list something!',
                    context,
                  );
                }

                final filteredProducts = _filterProducts(snapshot.data!);

                if (filteredProducts.isEmpty) {
                  return _buildEmptyState(
                    searchQuery.isNotEmpty
                        ? 'No ${_getPluralListingType(listingType)} found for "$searchQuery"'
                        : 'No ${_getPluralListingType(listingType)} match your current filters',
                    context,
                  );
                }

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return GestureDetector(
                        onTap: () => widget.onProductTap(product.listing),
                        child: ProductCard(
                          categorySelected: currentCategories,
                          listingWrapper: product,
                          onFavoriteTap: () {
                            print('Added to favorites: ${product.name}');
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            SizedBox(height: 40),
            StreamBuilder<List<ListingWrapper>>(
              stream: _listingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container();
                }

                if (snapshot.hasError) {
                  return Container();
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container();
                }

                final filteredProducts = _filterProducts(snapshot.data!);

                if (filteredProducts.isEmpty) {
                  return Container();
                }

                return ListingsMapWidget(
                  listings: filteredProducts,
                  onListingTap: (listing) {
                    // Navigate to detail screen based on listing type
                    if (listing.listing is ItemListing) {
                      Get.to(
                        () => ItemProductDetailScreen(product: listing.listing),
                      );
                    } else if (listing.listing is BusinessListing) {
                      Get.to(
                        () => BusinessDetailScreen(business: listing.listing),
                      );
                    } else if (listing.listing is EventListing) {
                      Get.to(() => EventDetailScreen(event: listing.listing));
                    }
                  },
                  initialZoom: 12.0,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  bool _hasActiveFilters() {
    return (currentFilters['listingType'] != null &&
            currentFilters['listingType'] != 'All') ||
        currentFilters['priceRange'] != null ||
        currentFilters['useMyLocation'] == true ||
        currentFilters['address']?.isNotEmpty == true;
  }

  String _getPluralListingType(String listingType) {
    switch (listingType.toLowerCase()) {
      case 'item':
        return 'items';
      case 'business':
        return 'businesses';
      case 'event':
        return 'events';
      case 'all':
      default:
        return 'listings';
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// Updated ProductCard Widget to handle all listing types with favorites
class ProductCard extends StatefulWidget {
  final ListingWrapper listingWrapper;
  final List<String> categorySelected;
  final VoidCallback?
  onFavoriteTap; // Made optional since we handle it internally

  const ProductCard({
    super.key,
    required this.listingWrapper,
    required this.categorySelected,
    this.onFavoriteTap,
  });

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    if (widget.listingWrapper.id != null) {
      final isFav = await _favoritesService.isFavorite(
        widget.listingWrapper.id!,
      );
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    final listing = widget.listingWrapper;
    if (listing.id == null || listing.userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newFavoriteStatus = await _favoritesService.toggleFavorite(
        listingId: listing.id!,
        listingType: listing.type,
        listingName: listing.name ?? 'Unnamed ${listing.type}',
        listingImage:
            listing.photoUrls?.isNotEmpty == true
                ? listing.photoUrls!.first
                : null,
        category: listing.category,
        price: listing.price,
        ownerId: listing.userId!,
      );

      if (mounted) {
        setState(() {
          _isFavorite = newFavoriteStatus;
          _isLoading = false;
        });

        // Show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFavoriteStatus
                  ? 'Added to favorites'
                  : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: newFavoriteStatus ? Color(0xFFF2B342) : Colors.red,
          ),
        );

        // Call the optional callback
        if (widget.onFavoriteTap != null) {
          widget.onFavoriteTap!();
        }
      }
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

  @override
  Widget build(BuildContext context) {
    final listing = widget.listingWrapper;

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
            flex: 4,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child:
                      listing.photoUrls != null && listing.photoUrls!.isNotEmpty
                          ? Image.network(
                            listing.photoUrls!.first,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/Rectangle 3463809 (4).png',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                          : Image.asset(
                            'assets/images/Rectangle 3463809 (4).png',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
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

                // // Show listing type badge
                // Positioned(
                //   top: 8,
                //   left: 8,
                //   child: Container(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 8,
                //       vertical: 4,
                //     ),
                //     decoration: BoxDecoration(
                //       color: _getListingTypeColor(listing.type),
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     child: Text(
                //       listing.type,
                //       style: const TextStyle(
                //         color: Colors.white,
                //         fontSize: 10,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   ),
                // ),

                // Show condition for items
                if (listing.condition != null && listing.type == 'Item')
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        listing.condition!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // Show verified badge for businesses
                if (listing.isVerified == true && listing.type == 'Business')
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFF2B342),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 10),
                          SizedBox(width: 2),
                          Text(
                            'Verified',
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
                    listing.name ?? 'Unnamed ${listing.type}',
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Show price only for Items
                      if (listing.type == 'Item')
                        Text(
                          listing.price != null
                              ? '\$${listing.price!.toStringAsFixed(2)}'
                              : 'Price not set',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF2B342),
                          ),
                        )
                      // Show event date for Events
                      else if (listing.type == 'Event' &&
                          listing.eventStartDate != null)
                        Text(
                          _formatEventDate(listing.eventStartDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      // Show contact info for Businesses
                      else if (listing.type == 'Business')
                        Text(
                          (listing._listing as BusinessListing).description ??
                              'Contact info not set',
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
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
    switch (type) {
      case 'Item':
        return const Color(0xFFF2B342);
      case 'Business':
        return Colors.blue;
      case 'Event':
        return Colors.tealAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) {
      return 'Today';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Favorite Button Widget - Standalone component for use in detail screens
class FavoriteButton extends StatefulWidget {
  final String listingId;
  final String listingType;
  final String listingName;
  final String? listingImage;
  final List<String>? category;
  final double? price;
  final String ownerId;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteButton({
    super.key,
    required this.listingId,
    required this.listingType,
    required this.listingName,
    this.listingImage,
    this.category,
    this.price,
    required this.ownerId,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.listingId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newFavoriteStatus = await _favoritesService.toggleFavorite(
        listingId: widget.listingId,
        listingType: widget.listingType,
        listingName: widget.listingName,
        listingImage: widget.listingImage,
        category: widget.category,
        price: widget.price,
        ownerId: widget.ownerId,
      );

      if (mounted) {
        setState(() {
          _isFavorite = newFavoriteStatus;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFavoriteStatus
                  ? 'Added to favorites'
                  : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: newFavoriteStatus ? Color(0xFFF2B342) : Colors.red,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
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
                  width: widget.size - 8,
                  height: widget.size - 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.inactiveColor ?? Colors.grey[600]!,
                    ),
                  ),
                )
                : Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: widget.size,
                  color:
                      _isFavorite
                          ? (widget.activeColor ?? Colors.black)
                          : (widget.inactiveColor ?? Colors.grey[600]),
                ),
      ),
    );
  }
}

// Business Detail Screen Widget
class BusinessDetailScreen extends StatefulWidget {
  final BusinessListing business;

  const BusinessDetailScreen({super.key, required this.business});

  @override
  _BusinessDetailScreenState createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  String selectedPaymentMethod = 'Cash';
  bool isFavorite = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              'Business/',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              (widget.business.businessCategory ?? []).join('/'),
              style: TextStyle(
                color: Color(0xFFF3B340),
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          ReportButton(
            listingId: widget.business.id ?? '',
            listingType: 'Business',
            listingName: widget.business.businessName ?? 'Unnamed Business',
            listingImage: widget.business.photoUrls?.first,
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Gallery Section
            _buildMediaGallery(),

            // Business Info
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Name
                  Text(
                    widget.business.businessName ?? 'Unnamed Business',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Description
                  Text(
                    widget.business.description ?? 'No description available.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Business Categories
                  if (widget.business.businessCategory != null &&
                      widget.business.businessCategory!.isNotEmpty) ...[
                    Text(
                      'Business Categories:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children:
                          widget.business.businessCategory!.map((category) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFF3B340).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(0xFFF3B340),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.business,
                                    color: Color(0xFFF3B340),
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFF3B340),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                    SizedBox(height: 20),
                  ],

                  // Website/Online Store
                  if (widget.business.websiteOnlineStore != null &&
                      widget.business.websiteOnlineStore!.isNotEmpty) ...[
                    _buildInfoRow(
                      'Website/Online Store:',
                      widget.business.websiteOnlineStore!,
                      isLink: true,
                    ),
                    SizedBox(height: 12),
                  ],

                  SizedBox(height: 8),

                  // Location Section
                  if (widget.business.address != null &&
                      widget.business.address!.isNotEmpty)
                    _buildLocationSection(),

                  SizedBox(height: 20),

                  // Contact Information Section
                  _buildContactInfoSection(),

                  SizedBox(height: 32),

                  // Contact Button
                  if (widget.business.userId != null &&
                      widget.business.userId !=
                          FirebaseAuth.instance.currentUser!.uid)
                    CustomElevatedButton(
                      text: 'Contact Business',
                      backgroundColor: Color(0xFFF3B340),
                      textColor: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      borderRadius: 28,
                      onTap: () async {
                        final chatService = ChatService.instance;

                        try {
                          Get.dialog(
                            const Center(child: CircularProgressIndicator()),
                            barrierDismissible: false,
                          );

                          final currentUserId =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (currentUserId == null) {
                            throw Exception('User not authenticated');
                          }

                          final currentUser = await chatService.getUserProfile(
                            currentUserId,
                          );
                          if (currentUser == null) {
                            throw Exception('Please Sign in again');
                          }

                          final otherUserId = widget.business.userId;
                          if (otherUserId == null || otherUserId.isEmpty) {
                            throw Exception(
                              'Business owner information is missing',
                            );
                          }

                          final otherUser = await chatService.getUserProfile(
                            otherUserId,
                          );
                          if (otherUser == null) {
                            throw Exception(
                              'Business owner information not found',
                            );
                          }

                          final chatRoomId = await chatService
                              .createOrGetChatRoom(
                                otherUser: otherUser,
                                currentUser: currentUser,
                                currentUserId: currentUserId,
                                otherUserId: otherUserId,
                                productId: widget.business.id,
                                productTitle: widget.business.businessName,
                                productImage: widget.business.photoUrls?.first,
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
                        } on FirebaseException catch (e) {
                          Get.back();
                          Get.snackbar(
                            'Error',
                            'Firebase error: ${e.message ?? 'Unknown error'}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } on Exception catch (e) {
                          Get.back();
                          Get.snackbar(
                            'Error',
                            e.toString(),
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } catch (e) {
                          Get.back();
                          Get.snackbar(
                            'Error',
                            'An unexpected error occurred',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
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
    final hasImages =
        widget.business.photoUrls != null &&
        widget.business.photoUrls!.isNotEmpty;
    final hasVideos =
        widget.business.videoUrls != null &&
        widget.business.videoUrls!.isNotEmpty;
    final hasAttachments =
        widget.business.attachmentUrls != null &&
        widget.business.attachmentUrls!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images Section
        if (hasImages) ...[
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: widget.business.photoUrls!.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ImageViewer(
                                  imageUrl:
                                      widget.business.photoUrls?[index] ?? '',
                                ),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F4E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.business.photoUrls![index],
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/Rectangle 3463809 (4).png',
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Favorite Button
                            Positioned(
                              top: 16,
                              right: 16,
                              child: FavoriteButton(
                                listingId: widget.business.id ?? '',
                                listingType: 'Business',
                                listingName:
                                    widget.business.businessName ??
                                    'Unnamed Business',
                                listingImage:
                                    widget.business.photoUrls?.isNotEmpty ==
                                            true
                                        ? widget.business.photoUrls!.first
                                        : null,
                                category: widget.business.businessCategory,
                                ownerId: widget.business.userId ?? '',
                              ),
                            ),
                            // Verified Badge
                            if (widget.business.isVerified == true)
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF3B340),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
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
                    );
                  },
                ),
                // Image indicator dots
                if (widget.business.photoUrls!.length > 1)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.business.photoUrls!.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _currentImageIndex == index
                                    ? Color(0xFFF3B340)
                                    : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ] else ...[
          Container(
            height: 200,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 50, color: Colors.grey.shade400),
                  SizedBox(height: 8),
                  Text(
                    'No business images available',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Videos Section
        if (hasVideos) ...[
          VideoListWidget(
            videoUrls: widget.business.videoUrls ?? [],
            title: 'Business Videos',
          ),
        ],

        // Attachments Section
        if (hasAttachments) ...[
          AttachmentListWidget(
            attachmentUrls: widget.business.attachmentUrls ?? [],
            title: 'Business Documents',
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isLink ? Colors.black : Colors.black,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
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
            'Business Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFFF3B340), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.business.address!,
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
          Column(
            children: [
              // Email (Required)
              if (widget.business.email != null &&
                  widget.business.email!.isNotEmpty) ...[
                _buildContactRow(
                  Icons.email_outlined,
                  'Email:',
                  widget.business.email!,
                ),
                SizedBox(height: 12),
              ],

              // Website/Online Store
              if (widget.business.websiteOnlineStore != null &&
                  widget.business.websiteOnlineStore!.isNotEmpty) ...[
                _buildContactRow(
                  Icons.web,
                  'Website:',
                  widget.business.websiteOnlineStore!,
                  isLink: true,
                ),
                SizedBox(height: 12),
              ],

              // Phone Call
              if (widget.business.phoneCall != null &&
                  widget.business.phoneCall!.isNotEmpty) ...[
                _buildContactRow(
                  Icons.phone_outlined,
                  'Phone Calls:',
                  widget.business.phoneCall!,
                ),
                SizedBox(height: 12),
              ],

              // Phone Text
              if (widget.business.phoneText != null &&
                  widget.business.phoneText!.isNotEmpty) ...[
                _buildContactRow(
                  Icons.message_outlined,
                  'Text Messages:',
                  widget.business.phoneText!,
                ),
                SizedBox(height: 12),
              ],

              // Facebook/Instagram
              if (widget.business.facebookInstagramLink != null &&
                  widget.business.facebookInstagramLink!.isNotEmpty) ...[
                _buildContactRow(
                  Icons.link,
                  'Social Media:',
                  widget.business.facebookInstagramLink!,
                  isLink: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Color(0xFFF3B340), size: 18),
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
              color: isLink ? Colors.black : Colors.black87,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
  }
}

// Event Detail Screen Widget
class EventDetailScreen extends StatefulWidget {
  final EventListing event;

  const EventDetailScreen({super.key, required this.event});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String selectedPaymentMethod = 'At Event';
  bool isFavorite = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatEventDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatEventTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _getEventDuration() {
    if (widget.event.eventStartDate == null ||
        widget.event.eventEndDate == null) {
      return 'Duration not specified';
    }

    final start = widget.event.eventStartDate!;
    final end = widget.event.eventEndDate!;
    final duration = end.difference(start);

    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
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
              'Events/',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              (widget.event.eventCategory ?? []).join('/'),
              style: TextStyle(
                color: Color(0xFFF2B342),
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          ReportButton(
            listingId: widget.event.id ?? '',
            listingType: 'Event',
            listingName: widget.event.eventName ?? 'Unnamed Event',
            listingImage: widget.event.photoUrls?.first,
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Gallery Section
            _buildMediaGallery(),

            // Event Info
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Name
                  Text(
                    widget.event.eventName ?? 'Unnamed Event',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Description
                  Text(
                    widget.event.description ?? 'No description available.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Event Categories
                  if (widget.event.eventCategory != null &&
                      widget.event.eventCategory!.isNotEmpty) ...[
                    Text(
                      'Event Categories:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children:
                          widget.event.eventCategory!.map((category) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFF2B342).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(0xFFF2B342),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event,
                                    color: Color(0xFFF2B342),
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFF2B342),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                    SizedBox(height: 20),
                  ],

                  // Event Schedule Section
                  _buildEventScheduleSection(),
                  SizedBox(height: 20),

                  // Location Section
                  if (widget.event.address != null &&
                      widget.event.address!.isNotEmpty)
                    _buildLocationSection(),

                  SizedBox(height: 20),

                  // Event Links Section
                  _buildEventLinksSection(),

                  SizedBox(height: 20),

                  // Contact Information Section
                  _buildContactInfoSection(),

                  SizedBox(height: 32),

                  // Contact Organizer Button
                  if (widget.event.userId != null &&
                      widget.event.userId !=
                          FirebaseAuth.instance.currentUser!.uid)
                    CustomElevatedButton(
                      text: 'Contact Organizer',
                      backgroundColor: Color(0xFFF2B342),
                      textColor: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      borderRadius: 28,
                      onTap: () async {
                        final chatService = ChatService.instance;

                        try {
                          Get.dialog(
                            const Center(child: CircularProgressIndicator()),
                            barrierDismissible: false,
                          );

                          final currentUserId =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (currentUserId == null) {
                            throw Exception('User not authenticated');
                          }

                          final currentUser = await chatService.getUserProfile(
                            currentUserId,
                          );
                          if (currentUser == null) {
                            throw Exception('Please Sign in again');
                          }

                          final otherUserId = widget.event.userId;
                          if (otherUserId == null || otherUserId.isEmpty) {
                            throw Exception(
                              'Event organizer information is missing',
                            );
                          }

                          final otherUser = await chatService.getUserProfile(
                            otherUserId,
                          );
                          if (otherUser == null) {
                            throw Exception(
                              'Event organizer information not found',
                            );
                          }

                          final chatRoomId = await chatService
                              .createOrGetChatRoom(
                                otherUser: otherUser,
                                currentUser: currentUser,
                                currentUserId: currentUserId,
                                otherUserId: otherUserId,
                                productId: widget.event.id,
                                productTitle: widget.event.eventName,
                                productImage: widget.event.photoUrls?.first,
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
                        } on FirebaseException catch (e) {
                          Get.back();
                          Get.snackbar(
                            'Error',
                            'Firebase error: ${e.message ?? 'Unknown error'}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } on Exception catch (e) {
                          Get.back();
                          Get.snackbar(
                            'Error',
                            e.toString(),
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } catch (e) {
                          Get.back();
                          Get.snackbar(
                            'Error',
                            'An unexpected error occurred',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
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
    final hasImages =
        widget.event.photoUrls != null && widget.event.photoUrls!.isNotEmpty;
    final hasVideos =
        widget.event.videoUrls != null && widget.event.videoUrls!.isNotEmpty;
    final hasAttachments =
        widget.event.attachmentUrls != null &&
        widget.event.attachmentUrls!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images Section
        if (hasImages) ...[
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: widget.event.photoUrls!.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ImageViewer(
                                  imageUrl:
                                      widget.event.photoUrls?[index] ?? '',
                                ),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F4E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.event.photoUrls![index],
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/Rectangle 3463809 (4).png',
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Favorite Button
                            Positioned(
                              top: 16,
                              right: 16,
                              child: FavoriteButton(
                                listingId: widget.event.id ?? '',
                                listingType: 'Event',
                                listingName:
                                    widget.event.eventName ?? 'Unnamed Event',
                                listingImage:
                                    widget.event.photoUrls?.isNotEmpty == true
                                        ? widget.event.photoUrls!.first
                                        : null,
                                category: widget.event.eventCategory,
                                ownerId: widget.event.userId ?? '',
                              ),
                            ),
                            // Event Status Badge
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.tealAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'EVENT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Image indicator dots
                if (widget.event.photoUrls!.length > 1)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.event.photoUrls!.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _currentImageIndex == index
                                    ? Color(0xFFF2B342)
                                    : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ] else ...[
          Container(
            height: 200,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event, size: 50, color: Colors.grey.shade400),
                  SizedBox(height: 8),
                  Text(
                    'No event images available',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Videos Section
        // Videos Section
        if (hasVideos) ...[
          VideoListWidget(
            videoUrls: widget.event.videoUrls ?? [],
            title: 'Event Videos',
          ),
        ],

        // Attachments Section
        if (hasAttachments) ...[
          AttachmentListWidget(
            attachmentUrls: widget.event.attachmentUrls ?? [],
            title: 'Event Documents',
          ),
        ],
      ],
    );
  }

  Widget _buildEventScheduleSection() {
    final hasStartDate = widget.event.eventStartDate != null;
    final hasEndDate = widget.event.eventEndDate != null;

    if (!hasStartDate && !hasEndDate) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Schedule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12),

          // Start Date and Time
          if (hasStartDate) ...[
            Row(
              children: [
                Icon(Icons.event_available, color: Color(0xFFF2B342), size: 20),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starts: ${_formatEventDate(widget.event.eventStartDate!)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'at ${_formatEventTime(widget.event.eventStartDate!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],

          if (hasStartDate && hasEndDate) SizedBox(height: 8),

          // End Date and Time
          if (hasEndDate) ...[
            Row(
              children: [
                Icon(Icons.event_busy, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ends: ${_formatEventDate(widget.event.eventEndDate!)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'at ${_formatEventTime(widget.event.eventEndDate!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],

          if (hasStartDate && hasEndDate) ...[
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.timelapse, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Duration: ${_getEventDuration()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
            'Event Location',
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
                  widget.event.address!,
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

  Widget _buildEventLinksSection() {
    final hasWebsiteLink =
        widget.event.eventWebsiteRegistrationLink != null &&
        widget.event.eventWebsiteRegistrationLink!.isNotEmpty;
    final hasFacebookLink =
        widget.event.facebookEventSocialLink != null &&
        widget.event.facebookEventSocialLink!.isNotEmpty;

    if (!hasWebsiteLink && !hasFacebookLink) return SizedBox.shrink();

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
            'Event Links',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),

          // Website/Registration Link
          if (hasWebsiteLink) ...[
            Row(
              children: [
                Icon(Icons.web, color: Color(0xFFF2B342), size: 18),
                SizedBox(width: 12),
                Text(
                  'Website/Registration:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event.eventWebsiteRegistrationLink!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Facebook/Social Link
          if (hasFacebookLink) ...[
            if (hasWebsiteLink) SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.facebook, color: Colors.blue.shade700, size: 18),
                SizedBox(width: 12),
                Text(
                  'Facebook Event:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event.facebookEventSocialLink!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    final hasEmail =
        widget.event.email != null && widget.event.email!.isNotEmpty;
    final hasPhone =
        widget.event.phoneCall != null && widget.event.phoneCall!.isNotEmpty;

    if (!hasEmail && !hasPhone) return SizedBox.shrink();

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
            'Event Organizer Contact',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),

          // Email
          if (hasEmail) ...[
            Row(
              children: [
                Icon(Icons.email_outlined, color: Color(0xFFF2B342), size: 18),
                SizedBox(width: 12),
                Text(
                  'Email:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event.email!,
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

          // Phone
          if (hasPhone) ...[
            if (hasEmail) SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, color: Color(0xFFF2B342), size: 18),
                SizedBox(width: 12),
                Text(
                  'Phone:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event.phoneCall!,
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

          if (!hasEmail && !hasPhone) ...[
            Text(
              'Contact organizer for event details and registration',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

// Updated ProductDetailScreen with moveable images
class ItemProductDetailScreen extends StatefulWidget {
  final ItemListing product;

  const ItemProductDetailScreen({super.key, required this.product});

  @override
  _ItemProductDetailScreenState createState() =>
      _ItemProductDetailScreenState();
}

class _ItemProductDetailScreenState extends State<ItemProductDetailScreen> {
  String selectedSize = 'S';
  String selectedPaymentMethod = 'Paypal';
  bool isFavorite = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  initState() {
    super.initState();
    selectedSize = widget.product.sizeDimensions ?? 'no identified size';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              'Western Style/',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              'Kids',
              style: TextStyle(
                color: Color(0xFFF2B342),
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          ReportButton(
            listingId: widget.product.id ?? '',
            listingType: 'Item',
            listingName: widget.product.itemName ?? 'Unnamed Item',
            listingImage: widget.product.photoUrls?.first,
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Gallery Section
            _buildMediaGallery(),

            // Product Info
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    widget.product.itemName ?? 'Unnamed Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Description
                  Text(
                    (widget.product.description ?? '').isNotEmpty
                        ? widget.product.description ?? ''
                        : 'Get ready for a wild west adventure with this vibrant western-themed costume set designed specifically for little cowboys and cowgirls aged 4-7. This set comes complete with a classic cowboy hat, a rugged vest, and a playful bandana. It\'s the perfect touch of cowboy charm to any themed parties. Saddle up for some fun!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Categories
                  if (widget.product.category != null &&
                      widget.product.category!.isNotEmpty) ...[
                    Text(
                      'Categories:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children:
                          widget.product.category!.map((category) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFF2B342).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(0xFFF2B342),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFF2B342),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Price
                  Text(
                    '\$${(widget.product.price ?? 0).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF2B342),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Brand
                  if (widget.product.brand != null &&
                      widget.product.brand!.isNotEmpty) ...[
                    _buildInfoRow('Brand:', widget.product.brand!),
                    SizedBox(height: 12),
                  ],

                  // Condition
                  if (widget.product.condition != null) ...[
                    _buildInfoRow(
                      'Condition:',
                      widget.product.condition.toString(),
                    ),
                    SizedBox(height: 12),
                  ],

                  // Size / Dimensions
                  if (widget.product.sizeDimensions != null &&
                      widget.product.sizeDimensions!.isNotEmpty) ...[
                    _buildInfoRow(
                      'Size / Dimensions:',
                      widget.product.sizeDimensions!,
                    ),
                    SizedBox(height: 12),
                  ],

                  // Link/Website
                  if (widget.product.linkWebsite != null &&
                      widget.product.linkWebsite!.isNotEmpty) ...[
                    _buildInfoRow(
                      'Website:',
                      widget.product.linkWebsite!,
                      isLink: true,
                    ),
                    SizedBox(height: 12),
                  ],

                  SizedBox(height: 8),

                  // Location Section
                  if (widget.product.cityState != null &&
                      widget.product.cityState!.isNotEmpty)
                    _buildLocationSection(),

                  SizedBox(height: 20),

                  // Shipping Info Section
                  if (widget.product.shippingInfo != null &&
                      widget.product.shippingInfo!.isNotEmpty)
                    _buildShippingSection(),

                  SizedBox(height: 20),

                  // Payment Methods Section
                  _buildPaymentMethodsSection(),

                  SizedBox(height: 20),

                  // Other Payment Methods Section
                  if (widget.product.otherPaymentOptions != null &&
                      widget.product.otherPaymentOptions!.isNotEmpty)
                    _buildOtherPaymentSection(),

                  SizedBox(height: 20),

                  // Contact Information Section
                  _buildContactInfoSection(),

                  SizedBox(height: 32),

                  // Inquire Now Button
                  if (widget.product.userId != null &&
                      widget.product.userId !=
                          FirebaseAuth.instance.currentUser!.uid)
                    CustomElevatedButton(
                      text: 'Inquire Now',
                      backgroundColor: Color(0xFFF2B342),
                      textColor: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      borderRadius: 28,
                      onTap: () async {
                        final chatService = ChatService.instance;

                        try {
                          // Show loading
                          Get.dialog(
                            const Center(child: CircularProgressIndicator()),
                            barrierDismissible: false,
                          );

                          // Get current user profile
                          final currentUserId =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (currentUserId == null) {
                            throw Exception('User not authenticated');
                          }

                          final currentUser = await chatService.getUserProfile(
                            currentUserId,
                          );
                          if (currentUser == null) {
                            throw Exception('Please Sign in again');
                          }

                          // Validate product user ID
                          final otherUserId = widget.product.userId;
                          if (otherUserId == null || otherUserId.isEmpty) {
                            throw Exception(
                              'Product owner information is missing',
                            );
                          }

                          // Get other user profile
                          final otherUser = await chatService.getUserProfile(
                            otherUserId,
                          );
                          if (otherUser == null) {
                            throw Exception(
                              'Product owner information not found',
                            );
                          }

                          // Create or get chat room
                          final chatRoomId = await chatService
                              .createOrGetChatRoom(
                                otherUser: otherUser,
                                currentUser: currentUser,
                                currentUserId: currentUserId,
                                otherUserId: otherUserId,
                                productId: widget.product.id,
                                productTitle: widget.product.itemName,
                                productImage: widget.product.photoUrls?.first,
                              );

                          // Close loading
                          Get.back();

                          // Navigate to chat screen
                          Get.to(
                            () => const ChatMessageScreen(),
                            arguments: {
                              'chatRoomId': chatRoomId,
                              'currentUserId': currentUserId,
                              'otherUserId': otherUserId,
                            },
                          );
                        } on FirebaseException catch (e) {
                          Get.back(); // Close loading
                          Get.snackbar(
                            'Error',
                            'Firebase error: ${e.message ?? 'Unknown error'}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } on Exception catch (e) {
                          Get.back(); // Close loading
                          Get.snackbar(
                            'Error',
                            e.toString(),
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } catch (e) {
                          Get.back(); // Close loading
                          Get.snackbar(
                            'Error',
                            'An unexpected error occurred',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          debugPrint('Unexpected error: $e');
                        }
                      },
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
    final hasImages =
        widget.product.photoUrls != null &&
        widget.product.photoUrls!.isNotEmpty;
    final hasVideos =
        widget.product.videoUrls != null &&
        widget.product.videoUrls!.isNotEmpty;
    final hasAttachments =
        widget.product.attachmentUrls != null &&
        widget.product.attachmentUrls!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images Section
        if (hasImages) ...[
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: widget.product.photoUrls!.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ImageViewer(
                                  imageUrl:
                                      widget.product.photoUrls?[index] ?? '',
                                ),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F4E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.product.photoUrls![index],
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/Rectangle 3463809 (4).png',
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Favorite Button
                            Positioned(
                              top: 16,
                              right: 16,
                              child: FavoriteButton(
                                listingId: widget.product.id ?? '',
                                listingType: 'Item',
                                listingName:
                                    widget.product.itemName ?? 'Unnamed Item',
                                listingImage:
                                    widget.product.photoUrls?.isNotEmpty == true
                                        ? widget.product.photoUrls!.first
                                        : null,
                                price: widget.product.price,
                                ownerId: widget.product.userId ?? '',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Image indicator dots
                if (widget.product.photoUrls!.length > 1)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.product.photoUrls!.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _currentImageIndex == index
                                    ? Color(0xFFF2B342)
                                    : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ] else ...[
          Container(
            height: 200,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 50, color: Colors.grey.shade400),
                  SizedBox(height: 8),
                  Text(
                    'No images available',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Videos Section
        if (hasVideos) ...[
          VideoListWidget(
            videoUrls: widget.product.videoUrls ?? [],
            title: 'Item Videos',
          ),
        ],

        // Attachments Section
        if (hasAttachments) ...[
          AttachmentListWidget(
            attachmentUrls: widget.product.attachmentUrls ?? [],
            title: 'Item Documents',
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isLink ? Colors.black : Colors.black,
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
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
                  widget.product.cityState!,
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

  Widget _buildShippingSection() {
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
            'Shipping Info / Pickup',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.local_shipping, color: Color(0xFFF2B342), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.product.shippingInfo!,
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

  Widget _buildPaymentMethodsSection() {
    final hasPaymentMethods =
        widget.product.paymentMethod != null &&
        widget.product.paymentMethod!.isNotEmpty;

    if (!hasPaymentMethods) return SizedBox.shrink();

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
            'Payment Methods',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12.0,
            runSpacing: 8.0,
            children:
                widget.product.paymentMethod!.map((method) {
                  IconData icon;
                  switch (method.toLowerCase()) {
                    case 'paypal':
                      icon = Icons.payment;
                      break;
                    case 'cash':
                      icon = Icons.attach_money;
                      break;
                    case 'venmo':
                      icon = Icons.account_balance_wallet;
                      break;
                    case 'cashapp':
                      icon = Icons.account_balance_wallet;
                      break;
                    case 'credit card':
                      icon = Icons.credit_card;
                      break;
                    default:
                      icon = Icons.payment;
                  }

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFFF2B342).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Color(0xFFF2B342), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Color(0xFFF2B342), size: 16),
                        SizedBox(width: 6),
                        Text(
                          method,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF2B342),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),

          // Payment account details
          SizedBox(height: 12),

          if (widget.product.paymentMethod!.contains('Paypal') &&
              widget.product.paypalAccount != null &&
              widget.product.paypalAccount!.isNotEmpty) ...[
            _buildPaymentAccountRow(
              'PayPal Account:',
              widget.product.paypalAccount!,
            ),
            SizedBox(height: 8),
          ],

          if (widget.product.paymentMethod!.contains('VENMO') &&
              widget.product.venmoAccount != null &&
              widget.product.venmoAccount!.isNotEmpty) ...[
            _buildPaymentAccountRow(
              'Venmo Account:',
              widget.product.venmoAccount!,
            ),
            SizedBox(height: 8),
          ],

          if (widget.product.paymentMethod!.contains('CashApp') &&
              widget.product.cashappAccount != null &&
              widget.product.cashappAccount!.isNotEmpty) ...[
            _buildPaymentAccountRow(
              'CashApp Account:',
              widget.product.cashappAccount!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentAccountRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherPaymentSection() {
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
            'Other Payment Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.more_horiz, color: Color(0xFFF2B342), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.product.otherPaymentOptions!,
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
          Column(
            children: [
              // Email
              if (widget.product.email != null &&
                  widget.product.email!.isNotEmpty) ...[
                _buildContactRow(
                  Icons.email_outlined,
                  'Email:',
                  widget.product.email!,
                ),
                SizedBox(height: 12),
              ],

              // Preferred Contact Method
              if (widget.product.preferredContactMethod != null &&
                  widget.product.preferredContactMethod!.isNotEmpty) ...[
                _buildContactRow(
                  Icons.contact_support,
                  'Preferred Contact:',
                  widget.product.preferredContactMethod!,
                ),
                SizedBox(height: 12),
              ],

              // Shipping info is already shown in its own section
            ],
          ),
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
}

class ImageViewer extends StatelessWidget {
  final String imageUrl; // you can also use ImageProvider instead of String

  const ImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context), // close on tap
        child: Center(
          child: PhotoView(
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            imageProvider: NetworkImage(imageUrl), // or AssetImage / FileImage
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3, // zoom limit
            heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
          ),
        ),
      ),
    );
  }
}
