import 'dart:convert';
import 'dart:math';
import 'package:dedicated_cowboy/views/word_listings/model.dart';
import 'package:http/http.dart' as http;

class WordPressListingService {
  static final WordPressListingService _instance =
      WordPressListingService._internal();
  factory WordPressListingService() => _instance;
  WordPressListingService._internal();

  static const String baseUrl = 'https://dedicatedcowboy.com/wp-json/wp/v2';
  static const String listingsEndpoint = '/at_biz_dir';

  // Listing Type IDs
  static const int businessTypeId = 130;
  static const int eventTypeId = 335;
  static const int itemTypeId = 131;

  // ==================== GET LISTINGS ====================

  /// Get all listings with optional filters
  Future<List<UnifiedListing>> getAllListings({
    int? page = 1,
    int? perPage = 10,
    List<int>? categories,
    List<int>? listingTypes,
    String? search,
    String? slug,
    int? author,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (page != null) queryParams['page'] = page.toString();
      if (perPage != null) queryParams['per_page'] = perPage.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (slug != null && slug.isNotEmpty) queryParams['slug'] = slug;
      if (author != null) queryParams['author'] = author.toString();

      // Handle categories
      if (categories != null && categories.isNotEmpty) {
        for (int i = 0; i < categories.length; i++) {
          queryParams['at_biz_dir-category[$i]'] = categories[i].toString();
        }
      }

      // Handle listing types
      if (listingTypes != null && listingTypes.isNotEmpty) {
        for (int i = 0; i < listingTypes.length; i++) {
          queryParams['atbdp_listing_types[$i]'] = listingTypes[i].toString();
        }
      }

      Uri uri;
      if (author != null) {
        uri = Uri.parse(
          'https://dedicatedcowboy.com/wp-json/custom/v1/directory-listings?author=$author&status=all',
        );
      } else {
        uri = Uri.parse(
          '$baseUrl$listingsEndpoint',
        ).replace(queryParameters: queryParams);
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => UnifiedListing.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load listings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching listings: $e');
    }
  }

  /// Get listings by type (Item, Business, Event)
  Future<List<UnifiedListing>> getListingsByType(
    String type, {
    int? page = 1,
    int? perPage = 10,
  }) async {
    int? typeId;
    switch (type.toLowerCase()) {
      case 'item':
        typeId = itemTypeId;
        break;
      case 'business':
        typeId = businessTypeId;
        break;
      case 'event':
        typeId = eventTypeId;
        break;
    }

    if (typeId == null) {
      throw Exception('Invalid listing type: $type');
    }

    return getAllListings(page: page, perPage: perPage, listingTypes: [typeId]);
  }

  /// Get listings by category
  Future<List<UnifiedListing>> getListingsByCategory(
    List<int> categoryIds, {
    int? page = 1,
    int? perPage = 10,
    String? type,
  }) async {
    List<int>? typeIds;
    if (type != null && type.toLowerCase() != 'all') {
      switch (type.toLowerCase()) {
        case 'item':
          typeIds = [itemTypeId];
          break;
        case 'business':
          typeIds = [businessTypeId];
          break;
        case 'event':
          typeIds = [eventTypeId];
          break;
      }
    }

    return getAllListings(
      page: page,
      perPage: perPage,
      categories: categoryIds,
      listingTypes: typeIds,
    );
  }

  /// Get user's listings
  Future<List<UnifiedListing>> getUserListings(
    int userId, {
    int? page = 1,
    int? perPage = 10,
  }) async {
    return getAllListings(page: page, perPage: perPage, author: userId);
  }

  /// Search listings
  Future<List<UnifiedListing>> searchListings(
    String query, {
    int? page = 1,
    int? perPage = 10,
    String? type,
    List<int>? categories,
  }) async {
    List<int>? typeIds;
    if (type != null && type.toLowerCase() != 'all') {
      switch (type.toLowerCase()) {
        case 'item':
          typeIds = [itemTypeId];
          break;
        case 'business':
          typeIds = [businessTypeId];
          break;
        case 'event':
          typeIds = [eventTypeId];
          break;
      }
    }

    return getAllListings(
      page: page,
      perPage: perPage,
      search: query,
      listingTypes: typeIds,
      categories: categories,
    );
  }

  /// Get listings with complex filters
  Future<List<UnifiedListing>> getFilteredListings({
    int? page = 1,
    int? perPage = 10,
    String? listingType,
    List<int>? categories,
    String? searchQuery,
    double? maxPrice,
    double? latitude,
    double? longitude,
    double? radiusInMiles,
  }) async {
    // First get listings based on API filters
    List<int>? typeIds;
    if (listingType != null && listingType.toLowerCase() != 'all') {
      switch (listingType.toLowerCase()) {
        case 'item':
          typeIds = [itemTypeId];
          break;
        case 'business':
          typeIds = [businessTypeId];
          break;
        case 'event':
          typeIds = [eventTypeId];
          break;
      }
    }

    var listings = await getAllListings(
      page: page,
      perPage: perPage,
      search: searchQuery,
      listingTypes: typeIds,
      categories: categories,
    );

    // Apply client-side filters for price and location
    if (maxPrice != null) {
      listings =
          listings.where((listing) {
            if (listing.priceAsDouble == null) return true;
            return listing.priceAsDouble! <= maxPrice;
          }).toList();
    }

    if (latitude != null && longitude != null && radiusInMiles != null) {
      listings =
          listings.where((listing) {
            if (listing.latitude == null || listing.longitude == null) {
              return false;
            }

            double distance = _calculateDistance(
              latitude,
              longitude,
              listing.latitude!,
              listing.longitude!,
            );

            return distance <= radiusInMiles;
          }).toList();
    }

    return listings;
  }

  /// Get single listing by ID
  Future<UnifiedListing?> getListingById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$listingsEndpoint/$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UnifiedListing.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error fetching listing: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Calculate distance between two coordinates in miles
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

  /// Convert category names to IDs (you'll need to maintain this mapping)

  /// Get listing type name from ID
  String getListingTypeName(int typeId) {
    switch (typeId) {
      case businessTypeId:
        return 'Business';
      case eventTypeId:
        return 'Event';
      case itemTypeId:
        return 'Item';
      default:
        return 'Unknown';
    }
  }

  // ==================== STREAM WRAPPERS ====================

  /// Convert Future to Stream for compatibility with existing UI code
  Stream<List<UnifiedListing>> getAllListingsStream({
    String? listingType,
    List<int>? categories,
  }) async* {
    try {
      final listings = await getFilteredListings(
        listingType: listingType,
        categories: categories,
        perPage: 100, // Get more items for stream
      );
      yield listings;
    } catch (e) {
      yield [];
    }
  }

  /// Get items stream
  Stream<List<UnifiedListing>> getAllItemsStream() async* {
    try {
      final items = await getListingsByType('item', perPage: 100);
      yield items;
    } catch (e) {
      yield [];
    }
  }

  /// Get businesses stream
  Stream<List<UnifiedListing>> getAllBusinessesStream() async* {
    try {
      final businesses = await getListingsByType('business', perPage: 100);
      yield businesses;
    } catch (e) {
      yield [];
    }
  }

  /// Get events stream
  Stream<List<UnifiedListing>> getAllEventsStream() async* {
    try {
      final events = await getListingsByType('event', perPage: 100);
      yield events;
    } catch (e) {
      yield [];
    }
  }

  /// User listings stream
  Stream<List<UnifiedListing>> getUserListingsStream(int userId) async* {
    try {
      final listings = await getUserListings(userId, perPage: 100);
      yield listings;
    } catch (e) {
      yield [];
    }
  }
}
