import 'package:dedicated_cowboy/app/services/favorite_service/fav_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FavoritesService _favoritesService = FavoritesService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  final List<String> _tabs = ['All', 'Items', 'Businesses', 'Events'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  Stream<List<FavoriteItem>> _getFavoritesStream() {
    if (_searchQuery.isNotEmpty) {
      return _favoritesService.searchFavorites(_searchQuery);
    }

    final currentTab = _tabs[_tabController.index];
    switch (currentTab) {
      case 'Items':
        return _favoritesService.getFavoritesByType('Item');
      case 'Businesses':
        return _favoritesService.getFavoritesByType('Business');
      case 'Events':
        return _favoritesService.getFavoritesByType('Event');
      default:
        return _favoritesService.getUserFavorites();
    }
  }

  Future<void> _removeFavorite(FavoriteItem item) async {
    final success = await _favoritesService.removeFromFavorites(item.listingId);
    if (success) {
      Get.snackbar(
        'Removed',
        '${item.listingName} removed from favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _clearAllFavorites() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text('Are you sure you want to remove all favorites? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _favoritesService.clearAllFavorites();
      if (success) {
        Get.snackbar(
          'Cleared',
          'All favorites have been removed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xffF3B340),
          colorText: Colors.white,
        );
      }
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.only(bottom: 16.h),
            height: 120.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Start exploring and add items to your favorites!',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          CustomElevatedButton(
            text: 'Browse Listings',
            backgroundColor: appColors.pYellow,
            textColor: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            borderRadius: 24.r,
            onTap: () {
              Get.back(); // Go back to browse/home screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to detail screen based on listing type
          _navigateToDetailScreen(item);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: item.listingImage != null && item.listingImage!.isNotEmpty
                    ? Image.network(
                        item.listingImage!,
                        width: 80.w,
                        height: 80.h,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80.w,
                            height: 80.h,
                            color: Colors.grey[200],
                            child: Icon(
                              _getIconForListingType(item.listingType),
                              color: Colors.grey[400],
                              size: 32.w,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          _getIconForListingType(item.listingType),
                          color: Colors.grey[400],
                          size: 32.w,
                        ),
                      ),
              ),
              SizedBox(width: 12.w),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Listing type badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getListingTypeColor(item.listingType),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        item.listingType,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    
                    // Name
                    Text(
                      item.listingName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    
                    // Category
                    if (item.category != null)
                      Text(
                        item.category!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    
                    // Price for items
                    if (item.listingType == 'Item' && item.price != null)
                      Text(
                        '\$${item.price!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: appColors.pYellow,
                        ),
                      ),
                    
                    // Added date
                    if (item.addedAt != null)
                      Text(
                        'Added ${_formatDate(item.addedAt!)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Remove button
              IconButton(
                onPressed: () => _removeFavorite(item),
                icon: Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 24.w,
                ),
                tooltip: 'Remove from favorites',
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForListingType(String type) {
    switch (type) {
      case 'Item':
        return Icons.shopping_bag;
      case 'Business':
        return Icons.business;
      case 'Event':
        return Icons.event;
      default:
        return Icons.favorite;
    }
  }

  Color _getListingTypeColor(String type) {
    switch (type) {
      case 'Item':
        return appColors.pYellow;
      case 'Business':
        return Colors.blue;
      case 'Event':
        return Color(0xffF3B340);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToDetailScreen(FavoriteItem item) {
    // You would implement navigation to appropriate detail screens here
    // based on the listing type
    switch (item.listingType) {
      case 'Item':
        // Navigate to ItemDetailScreen
        print('Navigate to Item detail: ${item.listingId}');
        break;
      case 'Business':
        // Navigate to BusinessDetailScreen
        print('Navigate to Business detail: ${item.listingId}');
        break;
      case 'Event':
        // Navigate to EventDetailScreen
        print('Navigate to Event detail: ${item.listingId}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search favorites...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black, fontSize: 16),
                onChanged: _onSearchChanged,
              )
            : Text(
                'My Favorites',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.black,
            ),
            onPressed: _toggleSearch,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _clearAllFavorites();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert, color: Colors.black),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                color: appColors.pYellow,
                borderRadius: BorderRadius.circular(24.r),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              onTap: (index) {
                setState(() {}); // Refresh the stream when tab changes
              },
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          return StreamBuilder<List<FavoriteItem>>(
            stream: _getFavoritesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerLoading();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64.w,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Error loading favorites',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Please try again later',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              final favorites = snapshot.data ?? [];

              if (favorites.isEmpty) {
                String message = _searchQuery.isNotEmpty
                    ? 'No favorites found for "$_searchQuery"'
                    : tab == 'All'
                        ? 'No favorites yet'
                        : 'No ${tab.toLowerCase()} favorites';
                
                return _buildEmptyState(message);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // This will rebuild the StreamBuilder
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    return _buildFavoriteCard(favorites[index]);
                  },
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}