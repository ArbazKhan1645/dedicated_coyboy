import 'package:dedicated_cowboy/app/services/listings_service.dart';
import 'package:dedicated_cowboy/views/products_listings/products_listings.dart';
import 'package:dedicated_cowboy/widgets/search_bar_widget.dart';

import 'package:dedicated_cowboy/app/models/modules_models/business_model.dart';
import 'package:dedicated_cowboy/app/models/modules_models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ExploreScreen extends StatefulWidget {
  final Function(BusinessListing)? onBusinessTap;
  final Function(EventListing)? onEventTap;

  const ExploreScreen({super.key, this.onBusinessTap, this.onEventTap});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Firebase services
  final FirebaseServices _firebaseServices = FirebaseServices();

  // Data streams
  Stream<List<BusinessListing>>? _businessesStream;
  Stream<List<EventListing>>? _eventsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _initializeStreams();
  }

  void _initializeStreams() {
    // Get all active businesses and upcoming events
    _businessesStream = _firebaseServices.getAllBusinesses();
    _eventsStream = _firebaseServices.getUpcomingEvents();
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
    });
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

  Widget _buildErrorState(String error) {
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
          ElevatedButton(
            onPressed: () {
              setState(() {
                _initializeStreams();
              });
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  List<BusinessListing> _filterBusinesses(List<BusinessListing> businesses) {
    if (_searchQuery.isEmpty) return businesses;

    return businesses.where((business) {
      final name = business.businessName?.toLowerCase() ?? '';
      final description = business.description?.toLowerCase() ?? '';
      final location = business.address?.toLowerCase() ?? '';
      final categories = business.businessCategory ?? []; // List<String>

      return name.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          location.contains(_searchQuery) ||
          categories.any((c) => c.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  List<EventListing> _filterEvents(List<EventListing> events) {
    if (_searchQuery.isEmpty) return events;

    return events.where((event) {
      final name = event.eventName?.toLowerCase() ?? '';
      final description = event.description?.toLowerCase() ?? '';
      final location = event.address?.toLowerCase() ?? '';
      final categories = event.eventCategory ?? []; // List<String>

      return name.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          location.contains(_searchQuery) ||
          categories.any((c) => c.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  String _formatBusinessHours(BusinessListing business) {
    // You can customize this based on your business model structure
    // if (business.businessHours != null && business.businessHours!.isNotEmpty) {
    //   return business.businessHours!;
    // }
    return 'Hours not specified';
  }

  String _formatEventDateTime(EventListing event) {
    if (event.eventStartDate != null) {
      final date = event.eventStartDate!;
      final formattedDate =
          '${_getMonthName(date.month)} ${date.day}, ${date.year}';

      if (event.eventStartDate != null) {
        return '$formattedDate';
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      body: SafeArea(
        child: Column(
          children: [
            SearchBarWidget(
              hintText: 'Seach Business and Events',
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
    return StreamBuilder<List<BusinessListing>>(
      stream: _businessesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            _searchQuery.isEmpty
                ? 'No businesses found\nBe the first to list your business!'
                : 'No businesses match your search\nTry different keywords',
            Icons.business_outlined,
          );
        }

        final filteredBusinesses = _filterBusinesses(snapshot.data!);

        if (filteredBusinesses.isEmpty) {
          return _buildEmptyState(
            'No businesses match your search\nTry different keywords',
            Icons.search_off,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _initializeStreams();
            });
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filteredBusinesses.length,
            itemBuilder: (context, index) {
              final business = filteredBusinesses[index];
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
                              (business.businessCategory ?? []).join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xff364C63),
                              ),
                            ),
                            SizedBox(height: 4),

                            Text(
                              business.businessName ?? 'Unnamed Business',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff000000),
                              ),
                            ),

                            SizedBox(height: 2),
                            Text(
                              '${_formatBusinessHours(business)} - ${business.address ?? 'Location not specified'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xff364C63),
                              ),
                            ),
                            if (business.isVerified == true) ...[
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
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
                        child:
                            business.photoUrls != null &&
                                    business.photoUrls!.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    business.photoUrls!.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.business,
                                        color: Colors.grey[600],
                                        size: 24,
                                      );
                                    },
                                  ),
                                )
                                : Icon(
                                  Icons.business,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEventsTab() {
    return StreamBuilder<List<EventListing>>(
      stream: _eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
              Expanded(child: _buildShimmerLoading()),
            ],
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            _searchQuery.isEmpty
                ? 'No upcoming events\nCheck back later for new events!'
                : 'No events match your search\nTry different keywords',
            Icons.event_outlined,
          );
        }

        final filteredEvents = _filterEvents(snapshot.data!);

        if (filteredEvents.isEmpty) {
          return _buildEmptyState(
            'No events match your search\nTry different keywords',
            Icons.search_off,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _initializeStreams();
            });
          },
          child: Column(
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
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.eventName ?? 'Unnamed Event',
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
                                  // if (event.entryFee != null && event.entryFee! > 0) ...[
                                  //   SizedBox(height: 4),
                                  //   Text(
                                  //     '£${event.entryFee!.toStringAsFixed(2)}',
                                  //     style: TextStyle(
                                  //       fontSize: 14,
                                  //       color: Color(0xFFF2B342),
                                  //       fontWeight: FontWeight.w600,
                                  //     ),
                                  //   ),
                                  // ],
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
                              child:
                                  event.photoUrls != null &&
                                          event.photoUrls!.isNotEmpty
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          event.photoUrls!.first,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Icon(
                                              Icons.event,
                                              color: Colors.grey[600],
                                              size: 24,
                                            );
                                          },
                                        ),
                                      )
                                      : Icon(
                                        Icons.event,
                                        color: Colors.grey[600],
                                        size: 24,
                                      ),
                            ),
                          ],
                        ),
                      ),
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
}

// Example Usage Widget
class ExampleExploreApp extends StatelessWidget {
  const ExampleExploreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ExploreScreen(
      onBusinessTap: (business) {
        Widget page;
        page = BusinessDetailScreen(business: business);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        // Handle business tap - navigate to business detail screen
      },
      onEventTap: (event) {
        Widget page;
        page = EventDetailScreen(event: event);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        // Handle event tap - navigate to event detail screen
      },
    );
  }
}
