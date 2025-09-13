import 'dart:math';

import 'package:dedicated_cowboy/views/products_listings/listing_location.dart';
import 'package:dedicated_cowboy/views/word_listings/model.dart';
import 'package:dedicated_cowboy/views/word_listings/service.dart';
import 'package:dedicated_cowboy/views/word_listings/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class WebsiteProductListingScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialCategory;
  final List<Map<String, dynamic>> categories;
  final Function(UnifiedListing) onProductTap;
  final Map<String, dynamic>? appliedFilters;

  const WebsiteProductListingScreen({
    super.key,
    required this.initialCategory,
    required this.categories,
    required this.onProductTap,
    this.appliedFilters,
  });

  @override
  _WebsiteProductListingScreenState createState() =>
      _WebsiteProductListingScreenState();
}

class _WebsiteProductListingScreenState
    extends State<WebsiteProductListingScreen> {
  String sortBy = '';
  bool isSearching = false;
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  List<Map<String, dynamic>> currentCategories = [];
  Map<String, dynamic> currentFilters = {};

  List<UnifiedListing> _allListings = [];
  List<UnifiedListing> _filteredListings = [];

  // WordPress service
  final WordPressListingService _listingService = WordPressListingService();

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _loadListings();
  }

  void _initializeFilters() {
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      currentFilters = Map<String, dynamic>.from(
        Get.arguments as Map<String, dynamic>,
      );
    } else if (widget.appliedFilters != null) {
      currentFilters = Map<String, dynamic>.from(widget.appliedFilters!);
    }

    currentCategories = widget.initialCategory;

    searchQuery = currentFilters['searchQuery'] ?? '';
    searchController.text = searchQuery;
  }

  Future<void> _loadListings() async {
    setState(() {
      isLoading = true;
    });

    try {
      String listingType = currentFilters['listingType'] ?? 'All';
      List<UnifiedListing> listings;

      if (currentCategories.length == 1 &&
          currentCategories[0]['name'] == 'All') {
        listings = await _listingService.getFilteredListings(
          listingType: listingType,
          perPage: 100,
        );
      } else {
        final categoryIds = currentCategories;
        listings = await _listingService.getFilteredListings(
          listingType: listingType,
          categories: categoryIds.map((id) => id['id'] as int).toList(),
          perPage: 100,
        );
      }

      setState(() {
        _allListings = listings;
        _filteredListings = _filterListings(listings);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading listings: $e');
    }
  }

  List<UnifiedListing> _filterListings(List<UnifiedListing> listings) {
    List<UnifiedListing> filtered = List.from(listings);

    // Apply listing type filter
    String listingType = currentFilters['listingType'] ?? 'All';
    if (listingType != 'All') {
      filtered =
          filtered
              .where(
                (listing) =>
                    listing.listingType.toLowerCase() ==
                    listingType.toLowerCase(),
              )
              .toList();
    }

    // Apply search filter
    String searchTerm = currentFilters['searchQuery'] ?? searchQuery;
    if (searchTerm.isNotEmpty) {
      filtered =
          filtered.where((listing) {
            final title = listing.title?.toLowerCase() ?? '';
            final content = listing.cleanContent.toLowerCase();

            return title.contains(searchTerm.toLowerCase()) ||
                content.contains(searchTerm.toLowerCase());
          }).toList();
    }

    // Apply price range filter (only for Items)
    if (currentFilters['priceRange'] != null) {
      double maxPrice = currentFilters['priceRange'].toDouble();
      filtered =
          filtered.where((listing) {
            if (!listing.isItem || listing.priceAsDouble == null) return true;
            return listing.priceAsDouble! <= maxPrice;
          }).toList();
    }

    // Apply location radius filter
    if (currentFilters['radiusRange'] != null &&
        currentFilters['latitude'] != null &&
        currentFilters['longitude'] != null) {
      double userLat = currentFilters['latitude'].toDouble();
      double userLng = currentFilters['longitude'].toDouble();
      double maxRadius = currentFilters['radiusRange'].toDouble();

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
    _sortListings(filtered);

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

  void _sortListings(List<UnifiedListing> listings) {
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
      default:
        listings.sort((a, b) {
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
        currentFilters.remove('searchQuery');
        _filteredListings = _filterListings(_allListings);
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
      _filteredListings = _filterListings(_allListings);
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
                      title: Text(category['name']),
                      trailing: () {
                        if (category['name'] == 'All') {
                          return currentCategories.length ==
                                  widget.categories.length
                              ? Icon(Icons.check, color: Color(0xFFF2B342))
                              : null;
                        } else {
                          if (currentCategories.length ==
                              widget.categories.length) {
                            return null;
                          }
                          return currentCategories.contains(category)
                              ? Icon(Icons.check, color: Color(0xFFF2B342))
                              : null;
                        }
                      }(),
                      onTap: () {
                        setState(() {
                          if (category['name'] == 'All') {
                            currentCategories = widget.categories;
                          } else {
                            currentCategories = [
                              {'name': 'All', 'id': 0},
                              category,
                            ];
                          }
                          currentFilters['category'] = category;
                        });
                        Navigator.pop(context);
                        _loadListings();
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

    String listingType = currentFilters['listingType'] ?? 'All';
    if (listingType != 'All') {
      chips.add(
        _buildFilterChip(listingType, () {
          setState(() {
            currentFilters.remove('listingType');
            _filteredListings = _filterListings(_allListings);
          });
        }),
      );
    }

    if (currentFilters['priceRange'] != null) {
      double price = currentFilters['priceRange'].toDouble();
      chips.add(
        _buildFilterChip('Under \$${price.round()}', () {
          setState(() {
            currentFilters.remove('priceRange');
            _filteredListings = _filterListings(_allListings);
          });
        }),
      );
    }

    if (currentFilters['useMyLocation'] == true) {
      chips.add(
        _buildFilterChip('My Location', () {
          setState(() {
            currentFilters.remove('useMyLocation');
            currentFilters.remove('latitude');
            currentFilters.remove('longitude');
            currentFilters.remove('radiusRange');
            _filteredListings = _filterListings(_allListings);
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
            _filteredListings = _filterListings(_allListings);
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
              // _showFilterBottomSheet(context);
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
                                        currentCategories[0]['name'] == 'All'
                                    ? 'All'
                                    : currentCategories
                                        .where((e) => e['name'] != 'All')
                                        .map(
                                          (e) => e['name'],
                                        ) // extract only names
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Active filters chips
            _buildActiveFiltersChips(),
            if (_hasActiveFilters()) SizedBox(height: 8),

            // Items found and sort section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredListings.length} ${_getPluralListingType(listingType)} found',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      setState(() {
                        sortBy = value;
                        _filteredListings = _filterListings(_allListings);
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            if (isLoading)
              _buildShimmerLoading()
            else if (_filteredListings.isEmpty)
              _buildEmptyState(
                searchQuery.isNotEmpty
                    ? 'No ${_getPluralListingType(listingType)} found for "$searchQuery"'
                    : 'No ${_getPluralListingType(listingType)} found in selected categories\nBe the first to list something!',
                context,
              )
            else
              Padding(
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
                  itemCount: _filteredListings.length,
                  itemBuilder: (context, index) {
                    final listing = _filteredListings[index];
                    return GestureDetector(
                      onTap: () => widget.onProductTap(listing),
                      child: UnifiedProductCard(
                        listing: listing,
                        categorySelected:
                            currentCategories
                                .map((category) => category['name'].toString())
                                .toList(),
                        onFavoriteTap: () {
                          print('Added to favorites: ${listing.title}');
                        },
                      ),
                    );
                  },
                ),
              ),

            SizedBox(height: 40),

            // Map widget (if needed)
            if (!isLoading && _filteredListings.isNotEmpty)
              ListingsMapWidget(
                listings: _filteredListings,
                onListingTap: (listing) {
                  widget.onProductTap(listing);
                },
                initialZoom: 12.0,
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
