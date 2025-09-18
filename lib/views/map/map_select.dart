import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Model for location data
class LocationData {
  final double latitude;
  final double longitude;
  final String address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

// Main Location Map Widget
class LocationMapWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? googleApiKey;
  final double height;
  final String hintText;

  const LocationMapWidget({
    Key? key,
    required this.controller,
    this.googleApiKey,
    this.height = 500.0,
    this.hintText = "Select your location",
  }) : super(key: key);

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  LocationData? _selectedLocation;
  String _displayAddress = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Default location (New York)
  static const LatLng _defaultLocation = LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.text.isNotEmpty) {
      try {
        final parts = widget.controller.text.split(',');
        if (parts.length >= 2) {
          final lat = double.parse(parts[0].trim());
          final lng = double.parse(parts[1].trim());
          final address =
              parts.length > 2 ? parts.sublist(2).join(',').trim() : '';

          setState(() {
            _selectedLocation = LocationData(
              latitude: lat,
              longitude: lng,
              address: address,
            );
            _displayAddress = address;
          });

          _updateMapLocation(lat, lng);
          _animationController.forward();
        }
      } catch (e) {
        print('Error parsing controller text: $e');
      }
    } else {
      setState(() {
        _selectedLocation = null;
        _displayAddress = '';
      });
      _animationController.reverse();
    }
  }

  void _updateMapLocation(double lat, double lng) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 15.0, tilt: 45.0),
        ),
      );
    }
  }

  void _navigateToLocationSearch() async {
    final result = await Navigator.push<LocationData>(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                LocationSearchScreen(googleApiKey: widget.googleApiKey),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _displayAddress = result.address;
      });

      widget.controller.text =
          '${result.latitude},${result.longitude},${result.address}';

      _updateMapLocation(result.latitude, result.longitude);
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location/City & State',
            style: Appthemes.textSmall.copyWith(
              fontFamily: 'popins-bold',
              color: Color(0xFF424242),
            ),
          ),
          SizedBox(height: 10),
          // Content area
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Input Field
                GestureDetector(
                  onTap: _navigateToLocationSearch,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // gradient: LinearGradient(
                      //   colors: [Colors.grey.shade50, Colors.grey.shade100],
                      //   begin: Alignment.topLeft,
                      //   end: Alignment.bottomRight,
                      // ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _selectedLocation != null
                                ? const Color(0xFFF2B342)
                                : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_displayAddress.isNotEmpty)
                                Text(
                                  _displayAddress.isEmpty
                                      ? ''
                                      : 'Selected Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (_displayAddress.isNotEmpty)
                                const SizedBox(height: 2),
                              Text(
                                _displayAddress.isEmpty
                                    ? 'Listing address eg. 123 Main St, City, State'
                                    : _displayAddress,

                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color:
                                      _displayAddress.isEmpty
                                          ? Colors.grey.shade500
                                          : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Map Container with enhanced styling
                Container(
                  height: widget.height,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target:
                                _selectedLocation != null
                                    ? LatLng(
                                      _selectedLocation!.latitude,
                                      _selectedLocation!.longitude,
                                    )
                                    : _defaultLocation,
                            zoom: 14.0,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          markers:
                              _selectedLocation != null
                                  ? {
                                    Marker(
                                      markerId: const MarkerId(
                                        'selected_location',
                                      ),
                                      position: LatLng(
                                        _selectedLocation!.latitude,
                                        _selectedLocation!.longitude,
                                      ),
                                      infoWindow: InfoWindow(
                                        title: 'Selected Location',
                                        snippet: _selectedLocation!.address,
                                      ),
                                      icon:
                                          BitmapDescriptor.defaultMarkerWithHue(
                                            BitmapDescriptor.hueBlue,
                                          ),
                                    ),
                                  }
                                  : {},
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: false,
                          style: '''[
                            {
                              "featureType": "poi",
                              "elementType": "labels.text",
                              "stylers": [{"visibility": "off"}]
                            },
                            {
                              "featureType": "poi.business",
                              "stylers": [{"visibility": "off"}]
                            }
                          ]''',
                        ),
                      ),

                      // Custom zoom controls
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Column(
                          children: [
                            _buildZoomButton(Icons.add, () {
                              _mapController?.animateCamera(
                                CameraUpdate.zoomIn(),
                              );
                            }),
                            const SizedBox(height: 8),
                            _buildZoomButton(Icons.remove, () {
                              _mapController?.animateCamera(
                                CameraUpdate.zoomOut(),
                              );
                            }),
                          ],
                        ),
                      ),

                      // Location indicator when selected
                      if (_selectedLocation != null)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF2B342),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Location Selected',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.grey.shade700, size: 20),
          ),
        ),
      ),
    );
  }
}

// Enhanced Location Search Screen
class LocationSearchScreen extends StatefulWidget {
  final String? googleApiKey;

  const LocationSearchScreen({Key? key, this.googleApiKey}) : super(key: key);

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  LocationData? _currentLocation;
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        final address =
            '${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';

        setState(() {
          _currentLocation = LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            address: address,
          );
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || widget.googleApiKey == null) {
      setState(() {
        _predictions = [];
      });
      _listAnimationController.reverse();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=${widget.googleApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions =
            (data['predictions'] as List)
                .map((prediction) => PlacePrediction.fromJson(prediction))
                .toList();

        setState(() {
          _predictions = predictions;
        });

        if (predictions.isNotEmpty) {
          _listAnimationController.forward();
        }
      }
    } catch (e) {
      print('Error searching places: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    if (widget.googleApiKey == null) return;

    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=geometry,formatted_address'
          '&key=${widget.googleApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        final location = result['geometry']['location'];
        final address = result['formatted_address'];

        final locationData = LocationData(
          latitude: location['lat'].toDouble(),
          longitude: location['lng'].toDouble(),
          address: address,
        );

        Navigator.pop(context, locationData);
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Select Location',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
        ),
      ),
      body: Column(
        children: [
          // Use Current Location Card
          if (_currentLocation != null)
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF2B342), Color(0xFFF2B342)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context, _currentLocation),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use Current Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Automatically detect your location',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Search Field
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search location (e.g., Orangi Town, Karachi)',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.search, color: Colors.grey.shade600),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              onChanged: (value) {
                _searchPlaces(value);
              },
            ),
          ),

          const SizedBox(height: 20),

          // Loading Indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(20),
              child: const CircularProgressIndicator(),
            ),

          // Search Results
          Expanded(
            child: AnimatedBuilder(
              animation: _listAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _listAnimationController.value)),
                  child: Opacity(
                    opacity: _listAnimationController.value,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final prediction = _predictions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _getPlaceDetails(prediction.placeId),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.location_on,
                                        color: Colors.grey.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            prediction.description,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (prediction
                                                  .structuredFormatting
                                                  ?.secondaryText !=
                                              null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                prediction
                                                    .structuredFormatting!
                                                    .secondaryText!,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey.shade400,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Models for Google Places API
class PlacePrediction {
  final String description;
  final String placeId;
  final StructuredFormatting? structuredFormatting;

  PlacePrediction({
    required this.description,
    required this.placeId,
    this.structuredFormatting,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
      structuredFormatting:
          json['structured_formatting'] != null
              ? StructuredFormatting.fromJson(json['structured_formatting'])
              : null,
    );
  }
}

class StructuredFormatting {
  final String? mainText;
  final String? secondaryText;

  StructuredFormatting({this.mainText, this.secondaryText});

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) {
    return StructuredFormatting(
      mainText: json['main_text'],
      secondaryText: json['secondary_text'],
    );
  }
}
