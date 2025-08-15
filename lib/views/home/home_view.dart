import 'package:dedicated_cowboy/app/models/modules_models/business_model.dart';
import 'package:dedicated_cowboy/app/models/modules_models/item_model.dart';
import 'package:dedicated_cowboy/consts/appColors.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:dedicated_cowboy/views/browser/browser.dart';
import 'package:dedicated_cowboy/views/home/controller/home_controller.dart';
import 'package:dedicated_cowboy/views/home/widgets/banner_widget.dart';
import 'package:dedicated_cowboy/views/home/widgets/feature_widget.dart';
import 'package:dedicated_cowboy/views/products_listings/products_listings.dart';
import 'package:dedicated_cowboy/views/subscriptions.dart';
import 'package:dedicated_cowboy/widgets/custom_elevated_button_widget.dart';
import 'package:dedicated_cowboy/widgets/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  final HomeController controller = Get.find<HomeController>();

  void _openProductDetail(BuildContext context, dynamic product) {
    Widget page;
    if (product is ItemListing) {
      page = ProductDetailScreen(product: product);
    } else if (product is BusinessListing) {
      page = BusinessDetailScreen(business: product);
    } else {
      page = EventDetailScreen(event: product);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _categoryCard(BuildContext context, Category category) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => ProductListingScreen(
            initialCategory: category.title,
            categories: ['All', ...controller.categories.map((c) => c.title)],
            onProductTap: (product) => _openProductDetail(context, product),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                category.imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Text(
              category.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = controller.categories;

    return Scaffold(
      backgroundColor: appColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchBarWidget(
                controller: controller.searchController,
                onSearchTap: () {
                  Get.to(
                    () => ProductListingScreen(
                      appliedFilters: {
                        'searchQuery': controller.searchController.text,
                      },
                      initialCategory: 'All',
                      categories: [
                        'All',
                        ...controller.categories.map((c) => c.title),
                      ],
                      onProductTap:
                          (product) => _openProductDetail(context, product),
                    ),
                  );
                  controller.searchController.clear();
                },
                onSubmitted: () {
                  Get.to(
                    () => ProductListingScreen(
                      appliedFilters: {
                        'searchQuery': controller.searchController.text,
                      },
                      initialCategory: 'All',
                      categories: [
                        'All',
                        ...controller.categories.map((c) => c.title),
                      ],
                      onProductTap:
                          (product) => _openProductDetail(context, product),
                    ),
                  );
                  controller.searchController.clear();
                },
              ),
              const SizedBox(height: 5),
              WesternMarketplaceWidget(
                imageUrl: 'assets/images/bg.png',
                mainText: "Custom Western\nMarketplace",
                subText:
                    "Dedicated Cowboy is your Western marketplace to discover, promote, and connect—bringing together goods, services, and events from across the Western world.",
              ),
              ListBrowseToggleWidget(
                onListTap: () {},
                onBrowseTap:
                    () => Get.to(() => BrowseFilterScreen(mainRoute: true)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Text(
                  'All Categories',
                  style: Appthemes.textLarge.copyWith(
                    fontFamily: 'popins-bold',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 08,
                    mainAxisSpacing: 0,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: categories.length,
                  itemBuilder:
                      (context, index) =>
                          _categoryCard(context, categories[index]),
                ),
              ),
              SizedBox(height: 20),
              const FeatureWidget(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 55.h,
                  child: CustomElevatedButton(
                    borderRadius: 16.r,
                    text: 'Join Now',
                    textColor: appColors.white,
                    backgroundColor: appColors.pYellow,
                    isLoading: false,
                    onTap: () {
                      Get.to(() => SubscriptionManagementScreen());
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
