import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

// Import your existing components from product listing screen
import 'package:dedicated_cowboy/views/products_listings/products_listings.dart';
import 'package:dedicated_cowboy/app/services/listings_service.dart';
import 'package:dedicated_cowboy/app/models/modules_models/item_model.dart';
import 'package:dedicated_cowboy/app/models/modules_models/business_model.dart';
import 'package:dedicated_cowboy/app/models/modules_models/event_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dedicated_cowboy/views/products_listings/listing_location.dart';

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
  final FirebaseServices _firebaseServices = FirebaseServices();
  Stream<List<ListingWrapper>>? _listingsStream;
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
    'Tack & Live Stock',
    'Western Life & Events',
    'Business & Services',
  ];

  static const List<String> radiusOptions = [
    '50 miles',
    '100 miles',
    '200 miles',
    '300 miles',
    '500 miles',
    '1000 miles',
  ];

  static const Map<String, List<String>> categoriesStatic = {
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

  @override
  void initState() {
    super.initState();
    _initializeWithExistingFilters();
    _setupFocusListener();
    _initializeListingsStream();
  }

  void _initializeListingsStream() {
    if (selectedMainCategory == 'All') {
      _listingsStream = _getCombinedListingsStream(selectedListingType);
    } else {
      List<String> categories =
          selectedSubCategory == 'All'
              ? (categoriesStatic[selectedMainCategory] ?? [])
              : [selectedSubCategory];
      _listingsStream = _getCombinedListingsByCategoryStream(
        categories,
        selectedListingType,
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

    return _combineStreams(streams);
  }

  Stream<List<ListingWrapper>> _getCombinedListingsByCategoryStream(
    List<String> categories,
    String listingType,
  ) {
    List<Stream<List<ListingWrapper>>> streams = [];

    if (listingType == 'All' || listingType == 'Item') {
      streams.add(
        _firebaseServices
            .getItemsByCategory(categories)
            .map(
              (items) =>
                  items.map((item) => ListingWrapper(item, 'Item')).toList(),
            ),
      );
    }

    if (listingType == 'All' || listingType == 'Business') {
      streams.add(
        _firebaseServices
            .getBusinessesByCategory(categories)
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
            .getEventsByCategory(categories)
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
    const double earthRadiusMiles = 3959.0;

    double lat1Rad = lat1 * (3.14159265359 / 180.0);
    double lng1Rad = lng1 * (3.14159265359 / 180.0);
    double lat2Rad = lat2 * (3.14159265359 / 180.0);
    double lng2Rad = lng2 * (3.14159265359 / 180.0);

    double dLat = lat2Rad - lat1Rad;
    double dLng = lng2Rad - lng1Rad;

    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1Rad) * cos(lat2Rad) * sin(dLng / 2) * sin(dLng / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = earthRadiusMiles * c;

    return distance;
  }

  List<ListingWrapper> _filterProducts(List<ListingWrapper> products) {
    List<ListingWrapper> filtered = products;

    if (searchQuery.isNotEmpty) {
      filtered =
          filtered.where((product) {
            final title = product.name?.toLowerCase() ?? '';
            final description = product.description?.toLowerCase() ?? '';
            final categories = product.category ?? [];

            return title.contains(searchQuery.toLowerCase()) ||
                description.contains(searchQuery.toLowerCase()) ||
                categories.any(
                  (c) => c.toLowerCase().contains(searchQuery.toLowerCase()),
                );
          }).toList();
    }

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
          filtered.where((product) {
            if (product.type != 'Item' || product.price == null) return true;

            bool passesMin = minPrice == null || product.price! >= minPrice;
            bool passesMax = maxPrice == null || product.price! <= maxPrice;

            return passesMin && passesMax;
          }).toList();
    }

    if ((useMyLocation || addressController.text.isNotEmpty) &&
        latitude != null &&
        longitude != null) {
      double userLat = latitude!;
      double userLng = longitude!;
      double maxRadius = double.parse(selectedRadius.split(' ')[0]);

      filtered =
          filtered.where((product) {
            if (product.latitude == null ||
                product.longitude == null ||
                product.latitude == 0.0 ||
                product.longitude == 0.0) {
              return false;
            }

            double productLat = product.latitude!.toDouble();
            double productLng = product.longitude!.toDouble();

            double distance = _calculateDistance(
              userLat,
              userLng,
              productLat,
              productLng,
            );

            return distance <= maxRadius;
          }).toList();
    }

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
      case 'Featured':
      default:
        break;
    }
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
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
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
        _initializeListingsStream();
      });
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
    _initializeListingsStream();
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

    _initializeListingsStream();

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

  void _navigateToProductDetail(ListingWrapper listing) {
    if (listing.listing is ItemListing) {
      Get.to(() => ItemProductDetailScreen(product: listing.listing))?.then((
        a,
      ) {
        setState(() {});
      });
    } else if (listing.listing is BusinessListing) {
      Get.to(() => BusinessDetailScreen(business: listing.listing))?.then((a) {
        setState(() {});
      });
    } else if (listing.listing is EventListing) {
      Get.to(() => EventDetailScreen(event: listing.listing))?.then((a) {
        setState(() {});
      });
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error loading listings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text('Please try again later', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _initializeListingsStream();
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
                      _initializeListingsStream();
                    });
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
                          _initializeListingsStream();
                        });
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
    return StreamBuilder<List<ListingWrapper>>(
      stream: _listingsStream,
      builder: (context, snapshot) {
        final filteredProducts =
            snapshot.hasData
                ? _filterProducts(snapshot.data!)
                : <ListingWrapper>[];

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
                  '${filteredProducts.length} ${_getPluralListingType(selectedListingType)} found',
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
      },
    );
  }

  Widget _buildListingsGrid() {
    return StreamBuilder<List<ListingWrapper>>(
      stream: _listingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 200,
            child: _buildEmptyState(
              searchQuery.isNotEmpty
                  ? 'No ${_getPluralListingType(selectedListingType)} found for "$searchQuery"'
                  : 'No ${_getPluralListingType(selectedListingType)} found in selected categories\nBe the first to list something!',
            ),
          );
        }

        final filteredProducts = _filterProducts(snapshot.data!);

        if (filteredProducts.isEmpty) {
          return SizedBox(
            height: 200,
            child: _buildEmptyState(
              searchQuery.isNotEmpty
                  ? 'No ${_getPluralListingType(selectedListingType)} found for "$searchQuery"'
                  : 'No ${_getPluralListingType(selectedListingType)} match your current filters',
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
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return GestureDetector(
              onTap: () => _navigateToProductDetail(product),
              child: ProductCard(
                categorySelected: [selectedMainCategory],
                listingWrapper: product,
                onFavoriteTap: () {
                  print('Added to favorites: ${product.name}');
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapSection() {
    return StreamBuilder<List<ListingWrapper>>(
      stream: _listingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return Container();
        }

        final filteredProducts = _filterProducts(snapshot.data!);

        if (filteredProducts.isEmpty) {
          return Container();
        }

        return ListingsMapWidget(
          listings: filteredProducts,
          onListingTap: (listing) => _navigateToProductDetail(listing),
          initialZoom: 12.0,
        );
      },
    );
  }
}
