import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:dedicated_cowboy/views/listing/events_listings/list_item_form.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/list_item_form.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/widgets/add_item_button.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class ListAnEventScreen extends StatefulWidget {
  const ListAnEventScreen({Key? key}) : super(key: key);

  @override
  State<ListAnEventScreen> createState() => _ListAnEventScreenState();
}

class _ListAnEventScreenState extends State<ListAnEventScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section with Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF5F5F5),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back Button on the left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // Centered Title
                  Text(
                    'List a Event',
                    style: Appthemes.textMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: appColors.darkBlueText,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Add Your Item Button
                    GestureDetector(
                      onTap: () {
                        Get.to(() => ListEventForm());
                      },
                      child: AddItemButton(
                        ontap: () {
                          Get.to(() => ListEventForm());
                        },
                        text: 'Add Your Event',
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
