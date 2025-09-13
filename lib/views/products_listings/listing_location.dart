import 'dart:async';
import 'dart:math' as math;
import 'package:dedicated_cowboy/views/products_listings/products_listings.dart';
import 'package:dedicated_cowboy/views/word_listings/model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ListingsMapWidget extends StatefulWidget {
  final List<UnifiedListing> listings;
  final Function(UnifiedListing)? onListingTap;
  final double initialZoom;
  final LatLng? initialCenter;

  const ListingsMapWidget({
    Key? key,
    required this.listings,
    this.onListingTap,
    this.initialZoom = 12.0,
    this.initialCenter,
  }) : super(key: key);

  @override
  State<ListingsMapWidget> createState() => _ListingsMapWidgetState();
}

class _ListingsMapWidgetState extends State<ListingsMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasValidListings = false;
  bool _hasUserLocation = false;

  // Default location (fallback if no listings and no user location)
  static const LatLng _defaultLocation = LatLng(
    37.7749,
    -122.4194,
  ); // San Francisco

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await _getCurrentLocation();
      _createMarkers();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      _hasUserLocation = true;
    } catch (e) {
      print('Error getting location: $e');
      _hasUserLocation = false;
      _currentLocation = null;
      // Don't set a fallback location here - let the smart centering handle it
    }
  }

  void _createMarkers() {
    Set<Marker> markers = {};
    _hasValidListings = false;

    print(
      'Creating markers - hasUserLocation: $_hasUserLocation, currentLocation: $_currentLocation',
    );

    // Add current location marker only if we have user location
    if (_currentLocation != null && _hasUserLocation) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current location',
          ),
        ),
      );
      print('Added user location marker at $_currentLocation');
    }

    // Add listing markers
    for (int i = 0; i < widget.listings.length; i++) {
      final listing = widget.listings[i];

      // Skip listings without valid coordinates
      if (listing.latitude == null ||
          listing.longitude == null ||
          listing.latitude == 0.0 ||
          listing.longitude == 0.0) {
        print(
          'Skipping listing $i - invalid coordinates: lat=${listing.latitude}, lng=${listing.longitude}',
        );
        continue;
      }

      _hasValidListings = true;
      final position = LatLng(listing.latitude!, listing.longitude!);
      print('Adding listing marker $i at $position');

      markers.add(
        Marker(
          markerId: MarkerId('listing_${listing.id ?? i}'),
          position: position,
          icon: _getMarkerIcon(listing.listingType),
          onTap: () => _showListingDialog(listing),
          infoWindow: InfoWindow(
            title: listing.title ?? 'Unnamed ${listing.title}',
            snippet: _getMarkerSnippet(listing),
          ),
        ),
      );
    }

    print(
      'Total markers created: ${markers.length}, hasValidListings: $_hasValidListings',
    );

    setState(() {
      _markers = markers;
    });
  }

  BitmapDescriptor _getMarkerIcon(String listingType) {
    switch (listingType.toLowerCase()) {
      case 'item':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      case 'business':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'event':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  String _getMarkerSnippet(UnifiedListing listing) {
    switch (listing.listingType.toLowerCase()) {
      case 'item':
        return listing.price != null ? '\$${listing.price!}' : 'Item';
      case 'business':
        return 'Business';
      case 'event':
        return 'Event';
      default:
        return listing.listingType;
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
      return '${date.day}/${date.month}';
    }
  }

  void _showListingDialog(UnifiedListing listing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image section
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    color: Color(0xFFF8F4E6),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child:
                            listing.images != null && listing.images!.isNotEmpty
                                ? Image.network(
                                  listing.images!.first.url.toString(),
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
                      // Close button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      // Listing type badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getListingTypeColor(listing.listingType),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            listing.listingType,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      // Additional badges
                      // if (listing.c != null && listing.type == 'Item')
                      //   Positioned(
                      //     bottom: 8,
                      //     left: 8,
                      //     child: Container(
                      //       padding: EdgeInsets.symmetric(
                      //         horizontal: 8,
                      //         vertical: 4,
                      //       ),
                      //       decoration: BoxDecoration(
                      //         color: Colors.black.withOpacity(0.7),
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       child: Text(
                      //         listing.condition!,
                      //         style: TextStyle(
                      //           color: Colors.white,
                      //           fontSize: 10,
                      //           fontWeight: FontWeight.w500,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // if (listing. == true &&
                      //     listing.type == 'Business')
                      //   Positioned(
                      //     bottom: 8,
                      //     right: 8,
                      //     child: Container(
                      //       padding: EdgeInsets.symmetric(
                      //         horizontal: 6,
                      //         vertical: 2,
                      //       ),
                      //       decoration: BoxDecoration(
                      //         color: Color(0xFFF2B342),
                      //         borderRadius: BorderRadius.circular(8),
                      //       ),
                      //       child: Row(
                      //         mainAxisSize: MainAxisSize.min,
                      //         children: [
                      //           Icon(
                      //             Icons.verified,
                      //             color: Colors.white,
                      //             size: 10,
                      //           ),
                      //           SizedBox(width: 2),
                      //           Text(
                      //             'Verified',
                      //             style: TextStyle(
                      //               color: Colors.white,
                      //               fontSize: 8,
                      //               fontWeight: FontWeight.w500,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
                // Content section
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title ?? 'Unnamed ${listing.title}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      if (listing.content != null)
                        Text(
                          listing.content!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: 12),
                      // Price for items or event date or business info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (listing.listingType == 'Item' &&
                              listing.price != null)
                            Text(
                              '\$${listing.price}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF2B342),
                              ),
                            ),
                          // else if (listing.type == 'Event' &&
                          //     listing.eventStartDate != null)
                          //   Text(
                          //     _formatEventDate(listing.eventStartDate!),
                          //     style: TextStyle(
                          //       fontSize: 14,
                          //       color: Colors.blue[700],
                          //       fontWeight: FontWeight.w600,
                          //     ),
                          //   )
                          // else if (listing.type == 'Business')
                          //   Text(
                          //     'Contact for info',
                          //     style: TextStyle(
                          //       fontSize: 14,
                          //       color: Colors.grey[600],
                          //       fontStyle: FontStyle.italic,
                          //     ),
                          //   ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (widget.onListingTap != null) {
                                widget.onListingTap!(listing);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF2B342),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              'View Details',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getListingTypeColor(String type) {
    switch (type) {
      case 'Item':
        return Color(0xFFF2B342);
      case 'Business':
        return Colors.blue;
      case 'Event':
        return Colors.tealAccent;
      default:
        return Colors.grey;
    }
  }

  /// Smart map center calculation with improved fallback logic
  LatLng _getMapCenter() {
    // Priority 1: Use explicitly provided initial center
    if (widget.initialCenter != null) {
      return widget.initialCenter!;
    }

    // Priority 2: Use user's current location if available
    if (_currentLocation != null && _hasUserLocation) {
      return _currentLocation!;
    }

    // Priority 3: Use center of all valid listings
    if (_hasValidListings) {
      return _getListingsCenter();
    }

    // Priority 4: Use first valid listing
    for (final listing in widget.listings) {
      if (listing.latitude != null &&
          listing.longitude != null &&
          listing.latitude != 0.0 &&
          listing.longitude != 0.0) {
        return LatLng(listing.latitude!, listing.longitude!);
      }
    }

    // Final fallback: default location
    return _defaultLocation;
  }

  /// Calculate the geographic center of all valid listings
  LatLng _getListingsCenter() {
    List<LatLng> validListingPositions = [];

    for (final listing in widget.listings) {
      if (listing.latitude != null &&
          listing.longitude != null &&
          listing.latitude != 0.0 &&
          listing.longitude != 0.0) {
        validListingPositions.add(
          LatLng(listing.latitude!, listing.longitude!),
        );
      }
    }

    if (validListingPositions.isEmpty) {
      return _defaultLocation;
    }

    if (validListingPositions.length == 1) {
      return validListingPositions.first;
    }

    // Calculate center point
    double totalLat = 0;
    double totalLng = 0;

    for (final position in validListingPositions) {
      totalLat += position.latitude;
      totalLng += position.longitude;
    }

    return LatLng(
      totalLat / validListingPositions.length,
      totalLng / validListingPositions.length,
    );
  }

  /// Get appropriate zoom level based on available data
  double _getSmartZoomLevel() {
    // If we have user location and listings, use default zoom to show local area
    if (_hasUserLocation && _hasValidListings) {
      return widget.initialZoom;
    }

    // If we only have listings, calculate zoom based on their spread
    if (_hasValidListings) {
      List<LatLng> validListingPositions = [];

      for (final listing in widget.listings) {
        if (listing.latitude != null &&
            listing.longitude != null &&
            listing.latitude != 0.0 &&
            listing.longitude != 0.0) {
          validListingPositions.add(
            LatLng(listing.latitude!, listing.longitude!),
          );
        }
      }

      if (validListingPositions.length == 1) {
        return 14.0; // Closer zoom for single listing
      }

      // For multiple listings, we'll let _fitBoundsToMarkers handle the zoom
      return widget.initialZoom;
    }

    return widget.initialZoom;
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    // Always fit bounds to show all markers if we have any listings
    if (_hasValidListings || (_hasUserLocation && _currentLocation != null)) {
      // Add a small delay to ensure the map is fully loaded
      await Future.delayed(Duration(milliseconds: 500));
      // _fitBoundsToMarkers();
    }
  }

  void _fitBoundsToMarkers() {
    if (_mapController == null || _markers.isEmpty) return;

    // If only one marker (either user location or single listing), just center on it
    if (_markers.length == 1) {
      final marker = _markers.first;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, _getSmartZoomLevel()),
      );
      return;
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    // Calculate bounds for all markers
    for (final marker in _markers) {
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }

    // Calculate the span
    double latSpan = maxLat - minLat;
    double lngSpan = maxLng - minLng;

    // Add adaptive padding based on span
    double latPadding = math.max(
      latSpan * 0.2,
      0.001,
    ); // 20% padding, min 0.001
    double lngPadding = math.max(
      lngSpan * 0.2,
      0.001,
    ); // 20% padding, min 0.001

    // If all markers are very close together, use minimum padding
    if (latSpan < 0.001) {
      latPadding = 0.005; // About 500m
    }
    if (lngSpan < 0.001) {
      lngPadding = 0.005; // About 500m
    }

    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - latPadding, minLng - lngPadding),
            northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
          ),
          100.0, // padding in pixels
        ),
      );
    } catch (e) {
      print('Error fitting bounds: $e');
      // Fallback to centering on the calculated center with smart zoom
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_getMapCenter(), _getSmartZoomLevel()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2B342)),
              ),
              SizedBox(height: 16),
              Text('Loading map...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading map',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeMap();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 400,
      child: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _getMapCenter(),
          zoom: _getSmartZoomLevel(),
        ),
        markers: _markers,
        myLocationEnabled: _hasUserLocation,
        myLocationButtonEnabled: _hasUserLocation,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
        compassEnabled: true,
        buildingsEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
