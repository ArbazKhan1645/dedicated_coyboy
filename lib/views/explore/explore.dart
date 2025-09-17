import 'package:dedicated_cowboy/views/word_listings/model.dart';
import 'package:dedicated_cowboy/views/word_listings/service.dart';
import 'package:dedicated_cowboy/views/word_listings/widgets.dart';
import 'package:dedicated_cowboy/widgets/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ExploreScreen extends StatefulWidget {
  final Function(UnifiedListing)? onBusinessTap;
  final Function(UnifiedListing)? onEventTap;

  const ExploreScreen({super.key, this.onBusinessTap, this.onEventTap});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // WordPress service
  final WordPressListingService _listingService = WordPressListingService();

  // Data lists
  List<UnifiedListing> _allBusinesses = [];
  List<UnifiedListing> _allEvents = [];
  List<UnifiedListing> _filteredBusinesses = [];
  List<UnifiedListing> _filteredEvents = [];

  // Loading states
  bool _isLoadingBusinesses = false;
  bool _isLoadingEvents = false;

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

  Future<void> _loadData() async {
    await Future.wait([_loadBusinesses(), _loadEvents()]);
  }

  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoadingBusinesses = true;
    });

    try {
      final businesses = await _listingService.getFilteredListings(
        listingType: 'Business',
        perPage: 100,
      );

      setState(() {
        _allBusinesses = businesses;
        _filteredBusinesses = _filterBusinesses(businesses);
        _isLoadingBusinesses = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBusinesses = false;
      });
      print('Error loading businesses: $e');
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final events = await _listingService.getFilteredListings(
        listingType: 'Event',
        perPage: 100,
      );

      setState(() {
        _allEvents = events;
        _filteredEvents = _filterEvents(events);
        _isLoadingEvents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEvents = false;
      });
      print('Error loading events: $e');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredBusinesses = _filterBusinesses(_allBusinesses);
      _filteredEvents = _filterEvents(_allEvents);
    });
  }

  List<UnifiedListing> _filterBusinesses(List<UnifiedListing> businesses) {
    if (_searchQuery.isEmpty) return businesses;

    return businesses.where((business) {
      final name = business.title?.toLowerCase() ?? '';
      final description = business.cleanContent.toLowerCase();
      final location = business.address?.toLowerCase() ?? '';

      return name.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          location.contains(_searchQuery);
    }).toList();
  }

  List<UnifiedListing> _filterEvents(List<UnifiedListing> events) {
    if (_searchQuery.isEmpty) return events;

    return events.where((event) {
      final name = event.title?.toLowerCase() ?? '';
      final description = event.cleanContent.toLowerCase();
      final location = event.address?.toLowerCase() ?? '';

      return name.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          location.contains(_searchQuery);
    }).toList();
  }

  String _formatEventDateTime(UnifiedListing event) {
    if (event.createdAt != null) {
      final date = event.createdAt!;
      final formattedDate =
          '${_getMonthName(date.month)} ${date.day}, ${date.year}';
      return formattedDate;
    }
    return 'Date not specified';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Container(width: 150, height: 14, color: Colors.white),
                      SizedBox(height: 4),
                      Container(width: 200, height: 12, color: Colors.white),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  width: 60,
                  height: 60,
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

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error loading data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text('Please try again later', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: Text('Retry')),
        ],
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
            SearchBarWidget(
              hintText: 'Search Business and Events',
              controller: _searchController,
              onChanged: (c) {
                _onSearchChanged();
              },
            ),
            // Tab Bar
            Container(
              color: const Color(0xFFFAFAF5),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Color(0xff364C63),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                tabs: [Tab(text: 'Business'), Tab(text: 'Events')],
              ),
            ),
            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Business Tab
                  _buildBusinessTab(),
                  // Events Tab
                  _buildEventsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessTab() {
    if (_isLoadingBusinesses) {
      return _buildShimmerLoading();
    }

    if (_filteredBusinesses.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isEmpty
            ? 'No businesses found\nBe the first to list your business!'
            : 'No businesses match your search\nTry different keywords',
        _searchQuery.isEmpty ? Icons.business_outlined : Icons.search_off,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBusinesses,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredBusinesses.length,
        itemBuilder: (context, index) {
          final business = _filteredBusinesses[index];
          return GestureDetector(
            onTap: () => widget.onBusinessTap?.call(business),
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.listingType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff364C63),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          business.title ?? 'Unnamed Business',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff000000),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hours not specified - ${business.address ?? 'Location not specified'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff364C63),
                          ),
                        ),
                        // Show featured badge if applicable
                        if (business.featured == '1') ...[
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Color(0xFFF2B342),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Featured',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFF2B342),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        business.featuredImageUrl ?? '',
                        fit: BoxFit.cover,
                      ),
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

  Widget _buildEventsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'UPCOMING EVENTS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child:
              _isLoadingEvents
                  ? _buildShimmerLoading()
                  : _filteredEvents.isEmpty
                  ? _buildEmptyState(
                    _searchQuery.isEmpty
                        ? 'No upcoming events\nCheck back later for new events!'
                        : 'No events match your search\nTry different keywords',
                    _searchQuery.isEmpty
                        ? Icons.event_outlined
                        : Icons.search_off,
                  )
                  : RefreshIndicator(
                    onRefresh: _loadEvents,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = _filteredEvents[index];
                        return GestureDetector(
                          onTap: () => widget.onEventTap?.call(event),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title ?? 'Unnamed Event',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _formatEventDateTime(event),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xff364C63),
                                        ),
                                      ),
                                      if (event.address != null) ...[
                                        SizedBox(height: 2),
                                        Text(
                                          event.address!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xff364C63),
                                          ),
                                        ),
                                      ],
                                      // Show price if it's an item (though events might not have prices)
                                      if (event.priceAsDouble != null &&
                                          event.priceAsDouble! > 0) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          '\$${event.priceAsDouble!.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFFF2B342),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16),
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[300],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      fit: BoxFit.cover,
                                      event.featuredImageUrl ?? '',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }
}

// Example Usage Widget
class ExampleExploreApp extends StatelessWidget {
  const ExampleExploreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ExploreScreen(
      onBusinessTap: (business) {
        // Navigate to unified detail screen for business
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnifiedDetailScreen(listing: business),
          ),
        );
      },
      onEventTap: (event) {
        // Navigate to unified detail screen for event
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnifiedDetailScreen(listing: event),
          ),
        );
      },
    );
  }
}
