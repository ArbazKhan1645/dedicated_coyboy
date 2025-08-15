import 'package:dedicated_cowboy/views/products_listings/products_listings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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
  String selectedListingType = 'Item';
  String selectedCategory = 'All';
  String selectedSubCategory = 'Women';
  double priceRange = 300;
  double radiusRange = 500;
  bool useMyLocation = false;
  bool isLoadingLocation = false;

  // Location variables
  double? latitude;
  double? longitude;
  String? currentLocationName;
  List<Map<String, dynamic>> locationSuggestions = [];
  bool showSuggestions = false;
  Timer? _debounceTimer;

  // Controllers
  final TextEditingController addressController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode addressFocusNode = FocusNode();

  // Constants
  static const String googleApiKey = 'AIzaSyDIz7irjECc_418w_XfkdzcFuCZaxMNzYg';

  // Cached data lists (performance optimization)
  static const List<String> listingTypes = ['Item', 'Business', 'Event'];
  static const List<String> categories = [
    'All',
    'Western style',
    'Home & Ranch Decor',
    'Tack & Livestock',
    'Western Life & Events',
    'Business & Services',
  ];

  @override
  void initState() {
    super.initState();
    _initializeWithExistingFilters();
    _setupAddressListener();
    _setupFocusListener();
  }

  void _setupAddressListener() {
    addressController.addListener(() {
      if (!useMyLocation && addressController.text.isNotEmpty) {
        _debounceLocationSearch(addressController.text);
      } else {
        setState(() {
          showSuggestions = false;
          locationSuggestions.clear();
        });
      }
    });
  }

  void _setupFocusListener() {
    addressFocusNode.addListener(() {
      if (!addressFocusNode.hasFocus) {
        // Hide suggestions when focus is lost
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

  void _debounceLocationSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (query.length > 2) {
        _searchLocations(query);
      } else {
        setState(() {
          showSuggestions = false;
          locationSuggestions.clear();
        });
      }
    });
  }

  Future<void> _searchLocations(String query) async {
    try {
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
        }
      }
    } catch (e) {
      debugPrint('Error searching locations: $e');
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
      debugPrint('Error getting location details: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Check permissions
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

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      // Get address from coordinates
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

  void _initializeWithExistingFilters() {
    if (widget.initialFilters != null) {
      final filters = widget.initialFilters!;
      setState(() {
        selectedListingType = filters['listingType'] ?? 'Item';
        selectedCategory = filters['category'] ?? 'All';
        selectedSubCategory = filters['subCategory'] ?? 'Women';
        priceRange = filters['priceRange']?.toDouble() ?? 300.0;
        radiusRange = filters['radiusRange']?.toDouble() ?? 500.0;
        useMyLocation = filters['useMyLocation'] ?? false;
        latitude = filters['latitude'];
        longitude = filters['longitude'];
        searchController.text = filters['searchQuery'] ?? '';
        addressController.text = filters['address'] ?? '';
        currentLocationName = filters['currentLocationName'];
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    addressController.dispose();
    searchController.dispose();
    addressFocusNode.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      selectedListingType = 'Item';
      selectedCategory = 'All';
      selectedSubCategory = 'Women';
      priceRange = 300;
      radiusRange = 500;
      useMyLocation = false;
      latitude = null;
      longitude = null;
      currentLocationName = null;
      addressController.clear();
      searchController.clear();
      showSuggestions = false;
      locationSuggestions.clear();
    });
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
    // Validate location data
    // if (useMyLocation && (latitude == null || longitude == null)) {
    //   Get.snackbar(
    //     'Location Required',
    //     'Please wait for location to be fetched or enter address manually',
    //     snackPosition: SnackPosition.BOTTOM,
    //     backgroundColor: Colors.orange,
    //     colorText: Colors.white,
    //     duration: Duration(seconds: 3),
    //   );
    //   return;
    // }

    // if (!useMyLocation && addressController.text.trim().isEmpty) {
    //   Get.snackbar(
    //     'Address Required',
    //     'Please enter an address or use current location',
    //     snackPosition: SnackPosition.BOTTOM,
    //     backgroundColor: Colors.orange,
    //     colorText: Colors.white,
    //     duration: Duration(seconds: 3),
    //   );
    //   return;
    // }

    // Create filter data to return
    final filterData = {
      'listingType': selectedListingType,
      'category': selectedCategory,
      'subCategory': selectedSubCategory,
      'priceRange': priceRange,
      'radiusRange': radiusRange,
      'address': addressController.text.trim(),
      'useMyLocation': useMyLocation,
      'latitude': latitude,
      'longitude': longitude,
      'currentLocationName': currentLocationName,
      'searchQuery': searchController.text.trim(),
    };

    if (widget.mainRoute) {
      // Navigate to products listing screen
      Get.to(
        () => ProductListingScreen(
          initialCategory: 'All',
          categories: ['All'],
          onProductTap: (product) {},
          appliedFilters: filterData,
        ),
        arguments: filterData,
      );
    } else {
      Get.back(result: filterData);
    }

    // Return the filter data to previous screen

    // Show success message
    Get.snackbar(
      'Filters Applied',
      'Your filters have been applied successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFF3B340),
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: SafeArea(
        child: Column(
          children: [
            // Main content
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
                    // Header
                    _buildHeader(),
                    // Content
                    Expanded(
                      child: Container(
                        color: Colors.white,
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
                              if (selectedListingType == 'Item')
                                _buildPriceRangeSection(),
                              _buildRadiusSection(),
                              SizedBox(height: 40),
                              _buildApplyButton(),
                              SizedBox(height: 20),
                            ],
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
            'Filter',
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
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Close',
                  style: TextStyle(fontSize: 16, color: Color(0xFF007AFF)),
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
        GestureDetector(
          onTap: () => Get.back(),
          child: Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        ),
        SizedBox(width: 16),
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
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
          child: TextField(
            controller: addressController,
            focusNode: addressFocusNode,
            enabled: !useMyLocation,
            decoration: InputDecoration(
              hintText:
                  useMyLocation
                      ? isLoadingLocation
                          ? 'Getting current location...'
                          : currentLocationName ?? 'Using current location...'
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
              suffixIcon:
                  useMyLocation && isLoadingLocation
                      ? Container(
                        width: 20,
                        height: 20,
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFF3B340),
                          ),
                        ),
                      )
                      : null,
            ),
          ),
        ),
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
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE0E0E0)),
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
          'Category',
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
              categories.map((category) {
                return _buildFilterChip(
                  category,
                  selectedCategory == category,
                  true,
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                );
              }).toList(),
        ),
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
        SizedBox(height: 8),
        Text(
          '\$${priceRange.round()}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF3B340),
          ),
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Color(0xFFFF9500),
            inactiveTrackColor: Color(0xFFE0E0E0),
            thumbColor: Color(0xFFF3B340),
            overlayColor: Color(0xFFF3B340).withOpacity(0.3),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 4,
          ),
          child: Slider(
            value: priceRange,
            min: 10,
            max: 500,
            divisions: 49,
            onChanged: (value) {
              setState(() {
                priceRange = value;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$10',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              '\$500',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
        SizedBox(height: 8),
        Text(
          '${radiusRange.round()} ${radiusRange.round() == 1 ? 'mile' : 'miles'}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF3B340),
          ),
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Color(0xFFFF9500),
            inactiveTrackColor: Color(0xFFE0E0E0),
            thumbColor: Color(0xFFF3B340),
            overlayColor: Color(0xFFF3B340).withOpacity(0.3),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 4,
          ),
          child: Slider(
            value: radiusRange,
            min: 1,
            max: 1000,
            divisions: 999,
            onChanged: (value) {
              setState(() {
                radiusRange = value;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1 mile',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              '1000 miles',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
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
          backgroundColor: Color(0xFFF3B340),
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
          color: isSelected && isOrange ? Color(0xFFF3B340) : Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected && isOrange
                  ? null
                  : Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow:
              isSelected && isOrange
                  ? [
                    BoxShadow(
                      color: Color(0xFFF3B340).withOpacity(0.3),
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
}
