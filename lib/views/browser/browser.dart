import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

// Import your new unified models and services
import 'package:dedicated_cowboy/views/word_listings/model.dart';
import 'package:dedicated_cowboy/views/word_listings/service.dart';
import 'package:dedicated_cowboy/views/word_listings/widgets.dart';
import 'package:dedicated_cowboy/views/products_listings/listing_location.dart';
import 'package:shimmer/shimmer.dart';

class BrowseFilterScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  final bool mainRoute;

  const BrowseFilterScreen({
    super.key,
    this.initialFilters,
    required this.mainRoute,
  });

  @override
  State<BrowseFilterScreen> createState() => _BrowseFilterScreenState();
}

class _BrowseFilterScreenState extends State<BrowseFilterScreen> {
  // State variables
  String selectedListingType = 'All';
  String selectedMainCategory = 'All';
  String selectedSubCategory = 'All';
  String selectedRadius = '50 miles';
  bool useMyLocation = false;
  bool isLoadingLocation = false;
  bool filtersApplied = false;

  // Location variables
  double? latitude;
  double? longitude;
  String? currentLocationName;
  List<Map<String, dynamic>> locationSuggestions = [];
  bool showSuggestions = false;
  bool isSearchingLocation = false;

  // Controllers
  final TextEditingController addressController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  final FocusNode addressFocusNode = FocusNode();

  // Form keys for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Listings related variables
  final WordPressListingService _listingService = WordPressListingService();
  List<UnifiedListing> _allListings = [];
  List<UnifiedListing> _filteredListings = [];
  bool isLoadingListings = false;
  String sortBy = 'Featured';
  String searchQuery = '';

  // Constants
  static const String googleApiKey = 'AIzaSyDIz7irjECc_418w_XfkdzcFuCZaxMNzYg';

  // Static data
  static const List<String> listingTypes = ['All', 'Item', 'Business', 'Event'];

  static const List<String> mainCategories = [
    'All',
    'Western Style',
    'Home & Ranch Decor',
    'Western Life & Events',
    'Business & Services',
    'Tack & Livestock',
  ];

  static const List<String> radiusOptions = [
    '50 miles',
    '100 miles',
    '200 miles',
    '300 miles',
    '500 miles',
    '1000 miles',
  ];

  // Updated category structure with IDs
  static const Map<String, List<String>> categoriesStatic = {
    "Business & Services": [
      'Business & Services',
      "Western Retail Shops",
      "Boutiques",
      "Ranch Services",
      "All Other",
    ],
    "Tack & Livestock": [
      "Tack & Livestock",
      "Tack",
      "Horses",
      "Livestock",
      "Miscellaneous",
    ],
    "Home & Ranch Decor": ['Home & Ranch Decor', "Furniture", "Art", "Decor"],
    "Western Life & Events": [
      'Western Life & Events',
      "Rodeos",
      "Barrel Races",
      "Team Roping",
      "All Other Events",
    ],
    "Western Style": ["Western Style", "Women", "Men", "Kids", "Accessories"],
  };

  final Map<String, Map<String, dynamic>> categoriesStaticNumber = {
    "Business & Services": {
      "id": 310,
      "parent": 0,
      "name": "Business & Services",
      "children": [
        {"name": "Business & Services", "id": 310, "parent": 0},
        {"name": "All Other", "id": 352, "parent": 310},
        {"name": "Boutiques", "id": 350, "parent": 310},
        {"name": "Ranch Services", "id": 351, "parent": 310},
        {"name": "Western Retail Shops", "id": 349, "parent": 310},
      ],
    },
    "Home & Ranch Decor": {
      "id": 290,
      "parent": 0,
      "name": "Home & Ranch Decor",
      "children": [
        {"name": "Home & Ranch Decor", "id": 290, "parent": 0},
        {"name": "Art", "id": 339, "parent": 290},
        {"name": "Decor", "id": 340, "parent": 290},
        {"name": "Furniture", "id": 338, "parent": 290},
      ],
    },
    "Tack & Livestock": {
      "id": 296,
      "parent": 0,
      "name": "Tack & Livestock",
      "children": [
        {"name": "Tack & Livestock", "id": 296, "parent": 0},
        {"name": "Horses", "id": 342, "parent": 296},
        {"name": "Livestock", "id": 343, "parent": 296},
        {"name": "Miscellaneous", "id": 344, "parent": 296},
        {"name": "Tack", "id": 341, "parent": 296},
      ],
    },
    "Western Life & Events": {
      "id": 303,
      "parent": 0,
      "name": "Western Life & Events",
      "children": [
        {"name": "Western Life & Events", "id": 303, "parent": 0},
        {"name": "All Other Events", "id": 348, "parent": 303},
        {"name": "Barrel Races", "id": 346, "parent": 303},
        {"name": "Rodeos", "id": 345, "parent": 303},
        {"name": "Team Roping", "id": 347, "parent": 303},
      ],
    },
    "Western Style": {
      "id": 284,
      "parent": 0,
      "name": "Western Style",
      "children": [
        {"name": "Western Style", "id": 284, "parent": 0},
        {"name": "Accessories", "id": 337, "parent": 284},
        {"name": "Kids", "id": 336, "parent": 284},
        {"name": "Mens", "id": 286, "parent": 284},
        {"name": "Womens", "id": 285, "parent": 284},
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeWithExistingFilters();
    _setupFocusListener();
    _loadListings();
  }

  void _setupFocusListener() {
    addressFocusNode.addListener(() {
      if (!addressFocusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              showSuggestions = false;
            });
          }
        });
      }
    });
  }

  Future<void> _loadListings() async {
    setState(() {
      isLoadingListings = true;
    });

    try {
      List<UnifiedListing> listings;

      if (selectedMainCategory == 'All') {
        print('object');
        listings = await _listingService.getFilteredListings(
          listingType: selectedListingType,
          perPage: 100,
        );
      } else {
        print('object1');
        List<int> categoryIds = _getCategoryIds();
        print(categoryIds);
        listings = await _listingService.getFilteredListings(
          listingType: selectedListingType,
          categories: categoryIds,
          perPage: 100,
        );
      }

      setState(() {
        _allListings = listings;
        _filteredListings = _filterProducts(listings);
        isLoadingListings = false;
      });
    } catch (e) {
      setState(() {
        isLoadingListings = false;
      });
      print('Error loading listings: $e');
    }
  }

  List<int> _getCategoryIds() {
    if (selectedMainCategory == 'All') return [];

    final categoryData = categoriesStaticNumber[selectedMainCategory];
    if (categoryData == null) return [];
    print(selectedSubCategory);

    if (selectedSubCategory == 'All' ||
        selectedSubCategory == selectedMainCategory) {
      // Return all children IDs for this main category
      final children = categoryData['children'] as List<dynamic>;
      return children.map((child) => child['id'] as int).toList();
    } else {
      // Return specific subcategory ID
      final children = categoryData['children'] as List<dynamic>;
      final subcategory = children.firstWhereOrNull(
        (child) => child['name'] == selectedSubCategory,
      );
      return subcategory != null ? [subcategory['id'] as int] : [];
    }
  }

  List<UnifiedListing> _filterProducts(List<UnifiedListing> listings) {
    List<UnifiedListing> filtered = List.from(listings);

    // Apply listing type filter
    if (selectedListingType != 'All') {
      filtered =
          filtered
              .where(
                (listing) =>
                    listing.listingType.toLowerCase() ==
                    selectedListingType.toLowerCase(),
              )
              .toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered =
          filtered.where((listing) {
            final title = listing.title?.toLowerCase() ?? '';
            final content = listing.cleanContent.toLowerCase();

            return title.contains(searchQuery.toLowerCase()) ||
                content.contains(searchQuery.toLowerCase());
          }).toList();
    }

    // Apply price range filter (only for Items)
    if (minPriceController.text.isNotEmpty ||
        maxPriceController.text.isNotEmpty) {
      double? minPrice =
          minPriceController.text.isNotEmpty
              ? double.tryParse(minPriceController.text)
              : null;
      double? maxPrice =
          maxPriceController.text.isNotEmpty
              ? double.tryParse(maxPriceController.text)
              : null;

      filtered =
          filtered.where((listing) {
            if (!listing.isItem || listing.priceAsDouble == null) return true;

            bool passesMin =
                minPrice == null || listing.priceAsDouble! >= minPrice;
            bool passesMax =
                maxPrice == null || listing.priceAsDouble! <= maxPrice;

            return passesMin && passesMax;
          }).toList();
    }

    // Apply location radius filter
    if ((useMyLocation || addressController.text.isNotEmpty) &&
        latitude != null &&
        longitude != null) {
      double userLat = latitude!;
      double userLng = longitude!;
      double maxRadius = double.parse(selectedRadius.split(' ')[0]);

      filtered =
          filtered.where((listing) {
            if (listing.latitude == null || listing.longitude == null) {
              return false;
            }

            double distance = _calculateDistance(
              userLat,
              userLng,
              listing.latitude!,
              listing.longitude!,
            );

            return distance <= maxRadius;
          }).toList();
    }

    // Apply sorting
    _sortProducts(filtered);

    return filtered;
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusMiles = 3959.0;
    const double pi = 3.14159265359;

    double lat1Rad = lat1 * (pi / 180.0);
    double lng1Rad = lng1 * (pi / 180.0);
    double lat2Rad = lat2 * (pi / 180.0);
    double lng2Rad = lng2 * (pi / 180.0);

    double dLat = lat2Rad - lat1Rad;
    double dLng = lng2Rad - lng1Rad;

    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1Rad) * cos(lat2Rad) * sin(dLng / 2) * sin(dLng / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusMiles * c;
  }

  void _sortProducts(List<UnifiedListing> listings) {
    switch (sortBy) {
      case 'Price: Low to High':
        listings.sort((a, b) {
          double priceA = a.priceAsDouble ?? double.infinity;
          double priceB = b.priceAsDouble ?? double.infinity;
          return priceA.compareTo(priceB);
        });
        break;
      case 'Price: High to Low':
        listings.sort((a, b) {
          double priceA = a.priceAsDouble ?? 0;
          double priceB = b.priceAsDouble ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'Name: A to Z':
        listings.sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
        break;
      case 'Name: Z to A':
        listings.sort((a, b) => (b.title ?? '').compareTo(a.title ?? ''));
        break;
      case 'Newest First':
        listings.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case 'Featured':
      default:
        // Keep original order or implement featured logic
        break;
    }
  }

  Future<void> _searchLocations() async {
    if (useMyLocation || addressController.text.trim().length < 3) {
      return;
    }

    setState(() {
      isSearchingLocation = true;
    });

    try {
      final String query = addressController.text.trim();
      final String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
          'input=$query&key=$googleApiKey&types=address';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List<Map<String, dynamic>> suggestions = [];

          for (var prediction in data['predictions']) {
            suggestions.add({
              'description': prediction['description'],
              'placeId': prediction['place_id'],
            });
          }

          setState(() {
            locationSuggestions = suggestions;
            showSuggestions = suggestions.isNotEmpty;
          });
        } else {
          _showLocationError('No locations found for "$query"');
        }
      }
    } catch (e) {
      _showLocationError('Error searching locations: ${e.toString()}');
    } finally {
      setState(() {
        isSearchingLocation = false;
      });
    }
  }

  Future<void> _getLocationDetails(String placeId, String description) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/place/details/json?'
          'place_id=$placeId&key=$googleApiKey&fields=geometry';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          setState(() {
            latitude = location['lat'];
            longitude = location['lng'];
            addressController.text = description;
            showSuggestions = false;
            locationSuggestions.clear();
          });
          addressFocusNode.unfocus();
        }
      }
    } catch (e) {
      _showLocationError('Error getting location details: ${e.toString()}');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions are permanently denied');
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String locationName = _formatLocationName(place);

        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
          currentLocationName = locationName;
          addressController.text = locationName;
        });
      }
    } catch (e) {
      _showLocationError('Failed to get current location: ${e.toString()}');
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  String _formatLocationName(Placemark place) {
    List<String> parts = [];
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    return parts.isEmpty ? 'Current Location' : parts.join(', ');
  }

  void _showLocationError(String message) {
    Get.snackbar(
      'Location Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  List<String> _getSubCategories() {
    if (selectedMainCategory == 'All') {
      return ['All'];
    }
    return categoriesStatic[selectedMainCategory] ?? ['All'];
  }

  void _onMainCategoryChanged(String? category) {
    if (category != null) {
      setState(() {
        selectedMainCategory = category;
        selectedSubCategory = 'All';
      });
      _loadListings();
    }
  }

  String? _validatePriceField(String? value, bool isMin) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final double? price = double.tryParse(value.trim());
    if (price == null) {
      return 'Enter a valid number';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    if (isMin) {
      final maxValue = maxPriceController.text.trim();
      if (maxValue.isNotEmpty) {
        final double? maxPrice = double.tryParse(maxValue);
        if (maxPrice != null && price > maxPrice) {
          return 'Min price cannot be greater than max price';
        }
      }
    } else {
      final minValue = minPriceController.text.trim();
      if (minValue.isNotEmpty) {
        final double? minPrice = double.tryParse(minValue);
        if (minPrice != null && price < minPrice) {
          return 'Max price cannot be less than min price';
        }
      }
    }

    return null;
  }

  void _initializeWithExistingFilters() {
    if (widget.initialFilters != null) {
      final filters = widget.initialFilters!;
      setState(() {
        selectedListingType = filters['listingType'] ?? 'All';
        selectedMainCategory = filters['mainCategory'] ?? 'All';
        selectedSubCategory = filters['subCategory'] ?? 'All';
        selectedRadius = filters['radius'] ?? '50 miles';
        useMyLocation = filters['useMyLocation'] ?? false;
        latitude = filters['latitude'];
        longitude = filters['longitude'];
        searchController.text = filters['searchQuery'] ?? '';
        addressController.text = filters['address'] ?? '';
        currentLocationName = filters['currentLocationName'];
        minPriceController.text = filters['minPrice']?.toString() ?? '';
        maxPriceController.text = filters['maxPrice']?.toString() ?? '';
        searchQuery = filters['searchQuery'] ?? '';
        filtersApplied = filters['filtersApplied'] ?? false;
      });
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    searchController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    addressFocusNode.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      selectedListingType = 'All';
      selectedMainCategory = 'All';
      selectedSubCategory = 'All';
      selectedRadius = '50 miles';
      useMyLocation = false;
      latitude = null;
      longitude = null;
      currentLocationName = null;
      addressController.clear();
      searchController.clear();
      minPriceController.clear();
      maxPriceController.clear();
      showSuggestions = false;
      locationSuggestions.clear();
      searchQuery = '';
      filtersApplied = false;
    });
    _formKey.currentState?.reset();
    _loadListings();
  }

  void _toggleLocationMode() {
    setState(() {
      useMyLocation = !useMyLocation;
      showSuggestions = false;
      locationSuggestions.clear();

      if (useMyLocation) {
        addressController.clear();
        latitude = null;
        longitude = null;
        currentLocationName = null;
        _getCurrentLocation();
      } else {
        latitude = null;
        longitude = null;
        currentLocationName = null;
      }
    });
  }

  void _applyFilters() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      filtersApplied = true;
      searchQuery = searchController.text.trim();
    });

    _loadListings();

    Get.snackbar(
      'Filters Applied',
      'Your filters have been applied successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF2B342),
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );
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

  String _getListingsText() {
    if (!filtersApplied) {
      return 'All Listings';
    }

    List<String> activeFilters = [];

    if (selectedListingType != 'All') {
      activeFilters.add(selectedListingType);
    }

    if (selectedMainCategory != 'All') {
      if (selectedSubCategory != 'All') {
        activeFilters.add(selectedSubCategory);
      } else {
        activeFilters.add(selectedMainCategory);
      }
    }

    if (searchQuery.isNotEmpty) {
      activeFilters.add('matching "$searchQuery"');
    }

    if (useMyLocation || addressController.text.isNotEmpty) {
      activeFilters.add('near ${useMyLocation ? "you" : "selected location"}');
    }

    if (activeFilters.isEmpty) {
      return 'Filtered Listings';
    }

    return 'Listings: ${activeFilters.join(', ')}';
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
            onPressed: _resetFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF2B342),
              foregroundColor: Colors.white,
            ),
            child: Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  void _navigateToProductDetail(UnifiedListing listing) {
    // Navigate to unified detail screen
    Get.to(() => UnifiedDetailScreen(listing: listing))?.then((a) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSearchSection(),
                                SizedBox(height: 24),
                                _buildAddressSection(),
                                SizedBox(height: 24),
                                _buildListingTypeSection(),
                                SizedBox(height: 24),
                                _buildCategorySection(),
                                SizedBox(height: 24),
                                if (selectedListingType == 'Item' ||
                                    selectedListingType == 'All')
                                  _buildPriceRangeSection(),
                                _buildRadiusSection(),
                                SizedBox(height: 40),
                                _buildApplyButton(),
                                SizedBox(height: 40),
                                _buildListingsHeader(),
                                SizedBox(height: 20),
                                _buildListingsGrid(),
                                SizedBox(height: 40),
                                _buildMapSection(),
                              ],
                            ),
                          ),
                        ),
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
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Browse & Filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _resetFilters,
                child: Text(
                  'Reset',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
              if (widget.mainRoute)
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Close',
                    style: TextStyle(fontSize: 16, color: Color(0xFF373737)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Row(
      children: [
        if (widget.mainRoute)
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          ),
        if (widget.mainRoute) SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search products, businesses, events...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(11),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: addressController,
                  focusNode: addressFocusNode,
                  enabled: !useMyLocation,
                  decoration: InputDecoration(
                    hintText:
                        useMyLocation
                            ? isLoadingLocation
                                ? 'Getting current location...'
                                : currentLocationName ??
                                    'Using current location...'
                            : 'Type your address...',
                    hintStyle: TextStyle(
                      color: useMyLocation ? Colors.grey[400] : Colors.grey,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    if (!useMyLocation && value.length >= 3) {
                      _searchLocations();
                    }
                  },
                ),
              ),
              if (!useMyLocation)
                SizedBox(
                  height: 44,
                  width: 44,
                  child: Material(
                    color: Color(0xFFF2B342),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: InkWell(
                      onTap: isSearchingLocation ? null : _searchLocations,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: Center(
                        child:
                            isSearchingLocation
                                ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: 20,
                                ),
                      ),
                    ),
                  ),
                ),
              if (useMyLocation && isLoadingLocation)
                Container(
                  width: 44,
                  height: 44,
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFF2B342),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showSuggestions && locationSuggestions.isNotEmpty)
          _buildLocationSuggestions(),
        SizedBox(height: 4),
        GestureDetector(
          onTap: _toggleLocationMode,
          child: Row(
            children: [
              Icon(
                useMyLocation ? Icons.check_circle : Icons.location_on,
                size: 16,
                color: Colors.black,
              ),
              SizedBox(width: 4),
              Text(
                useMyLocation ? 'Using my location' : 'Use my location',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSuggestions() {
    return Container(
      margin: EdgeInsets.only(top: 4),
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: locationSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = locationSuggestions[index];
          return InkWell(
            onTap:
                () => _getLocationDetails(
                  suggestion['placeId'],
                  suggestion['description'],
                ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border:
                    index < locationSuggestions.length - 1
                        ? Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))
                        : null,
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion['description'],
                      style: TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildListingTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listing Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              listingTypes.map((type) {
                return _buildFilterChip(
                  type,
                  selectedListingType == type,
                  true,
                  onTap: () {
                    setState(() {
                      selectedListingType = type;
                    });
                    _loadListings();
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Main Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMainCategory,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  onChanged: _onMainCategoryChanged,
                  items:
                      mainCategories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category, style: TextStyle(fontSize: 16)),
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (selectedMainCategory != 'All') ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sub Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSubCategory,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSubCategory = value;
                        });
                        _loadListings();
                      }
                    },
                    items:
                        ['All', ..._getSubCategories()].map((subCategory) {
                          return DropdownMenuItem(
                            value: subCategory,
                            child: Text(
                              subCategory,
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRICE RANGE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Min Price',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextFormField(
                      controller: minPriceController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) => _validatePriceField(value, true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max Price',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextFormField(
                      controller: maxPriceController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) => _validatePriceField(value, false),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRadiusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RADIUS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRadius,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedRadius = value;
                  });
                }
              },
              items:
                  radiusOptions.map((radius) {
                    return DropdownMenuItem(
                      value: radius,
                      child: Text(
                        radius,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _applyFilters,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF2B342),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Apply Filter',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    bool isOrange, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected && isOrange ? Color(0xFFF2B342) : Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected && isOrange
                  ? null
                  : Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow:
              isSelected && isOrange
                  ? [
                    BoxShadow(
                      color: Color(0xFFF2B342).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected && isOrange ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildListingsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _getListingsText(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_filteredListings.length} ${_getPluralListingType(selectedListingType)} found',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                setState(() {
                  sortBy = value;
                  _filteredListings = _filterProducts(_allListings);
                });
              },
              color: Color(0xFFF2B342),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              itemBuilder:
                  (BuildContext context) => [
                    PopupMenuItem(
                      value: 'Featured',
                      child: Center(
                        child: Text(
                          'Featured',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    if (selectedListingType == 'Item' ||
                        selectedListingType == 'All') ...[
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sort by: $sortBy',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
          ],
        ),
      ],
    );
  }

  Widget _buildListingsGrid() {
    if (isLoadingListings) {
      return _buildShimmerLoading();
    }

    if (_filteredListings.isEmpty) {
      return SizedBox(
        height: 200,
        child: _buildEmptyState(
          searchQuery.isNotEmpty
              ? 'No ${_getPluralListingType(selectedListingType)} found for "$searchQuery"'
              : 'No ${_getPluralListingType(selectedListingType)} found in selected categories\nBe the first to list something!',
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: _filteredListings.length,
      itemBuilder: (context, index) {
        final listing = _filteredListings[index];
        return GestureDetector(
          onTap: () => _navigateToProductDetail(listing),
          child: UnifiedProductCard(
            key: Key(listing.id.toString()),
            listing: listing,
            categorySelected: [selectedMainCategory],
            onFavoriteTap: () {
              print('Added to favorites: ${listing.title}');
            },
          ),
        );
      },
    );
  }

  Widget _buildMapSection() {
    if (isLoadingListings || _filteredListings.isEmpty) {
      return Container();
    }

    return ListingsMapWidget(
      listings: _filteredListings,
      onListingTap: (listing) => _navigateToProductDetail(listing),
      initialZoom: 12.0,
    );
  }
}
