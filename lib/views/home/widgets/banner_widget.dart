import 'package:dedicated_cowboy/consts/appColors.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:dedicated_cowboy/views/home/widgets/dropdown_widget.dart';
import 'package:dedicated_cowboy/views/listing/bussiness_listing/list_an_bussines.dart';
import 'package:dedicated_cowboy/views/listing/events_listings/list_an_item.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/list_an_item.dart';
import 'package:dedicated_cowboy/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:google_fonts/google_fonts.dart';

class WesternMarketplaceWidget extends StatelessWidget {
  final String imageUrl;
  final String mainText;
  final String subText;

  const WesternMarketplaceWidget({
    Key? key,
    required this.imageUrl,
    this.mainText = "Find Everything Western\nWithout The Hassle",
    this.subText =
        "Dedicated Cowboy Is Your Western Marketplace To Discover,\nPromote, And Connect—Bringing Together Goods, Services, And\nEvents From Across The Western World.",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.h,
      width: double.infinity,
      decoration: BoxDecoration(
        // borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Caching and Blur Effect
            Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imageUrl, // this must be a local asset path like 'assets/images/sample.png'
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.brown.shade300,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Image Failed to Load',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Blur Effect Overlay
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                  child: Container(color: Colors.transparent),
                ),
              ],
            ),

            // Dark Overlay for Text Readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),

            // Text Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main Title
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(
                          text: "Find Everything ",
                          style: Appthemes.textLarge.copyWith(
                            color: Colors.white,
                            fontFamily: 'popins-bold',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: "Western",
                          style: Appthemes.textLarge.copyWith(
                            color: appColors.pYellow,
                            fontFamily: 'popins-bold',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: "\nWithout The Hassle",
                          style: Appthemes.textLarge.copyWith(
                            color: Colors.white,
                            fontFamily: 'popins-bold',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    textAlign: TextAlign.start,
                    subText,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListBrowseToggleWidget extends StatefulWidget {
  final String leftText;
  final String rightText;
  final VoidCallback? onListTap;
  final VoidCallback? onBrowseTap;
  final bool isListSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color textColor;
  final Color unselectedTextColor;

  const ListBrowseToggleWidget({
    Key? key,
    this.leftText = "List",
    this.rightText = "Browse",
    this.onListTap,
    this.onBrowseTap,
    this.isListSelected = true,
    this.selectedColor = const Color(0xFFF2B342), // Orange color
    this.unselectedColor = const Color(0xFF9E9E9E), // Gray color
    this.textColor = Colors.white,
    this.unselectedTextColor = Colors.white,
  }) : super(key: key);

  @override
  State<ListBrowseToggleWidget> createState() => _ListBrowseToggleWidgetState();
}

class _ListBrowseToggleWidgetState extends State<ListBrowseToggleWidget> {
  ListOption selectedOption = ListOption.item;
  String lastAction = "None";
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(color: appColors.darkBlue),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          // mainAxisSize: MainAxisSize.min,
          children: [
            // List Button
            Text(
              'I Want To',
              style: Appthemes.textMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: Colors.white,
              ),
            ),
            Spacer(),
            DropdownListWidget(
              selectedColor: appColors.darkBlue,
              backgroundColor: appColors.pYellow,
              selectedOption: selectedOption,
              onItemTap: () {
                setState(() {
                  selectedOption = ListOption.item;
                  lastAction = "List An Item tapped!";
                });
                Get.to(() => ListAnItemScreen());
              },
              onBusinessTap: () {
                setState(() {
                  selectedOption = ListOption.business;
                  lastAction = "List A Business tapped!";
                });

                Get.to(() => ListAnBussinessScreen());
              },
              onEventTap: () {
                setState(() {
                  selectedOption = ListOption.event;
                  lastAction = "List An Event tapped!";
                });
                Get.to(() => ListAnEventScreen());
              },
            ),

            const SizedBox(width: 4),

            // Browse Button
            GestureDetector(
              onTap: widget.onBrowseTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      !widget.isListSelected
                          ? widget.selectedColor
                          : widget.unselectedColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/Search in Browser.png',
                      width: 20.w,
                      height: 20.h,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.rightText,
                      style: TextStyle(
                        color:
                            !widget.isListSelected
                                ? widget.textColor
                                : widget.unselectedTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
}
