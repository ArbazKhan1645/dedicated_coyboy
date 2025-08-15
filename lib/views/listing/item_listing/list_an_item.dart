import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/list_item_form.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/widgets/add_item_button.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class ListAnItemScreen extends StatefulWidget {
  const ListAnItemScreen({Key? key}) : super(key: key);

  @override
  State<ListAnItemScreen> createState() => _ListAnItemScreenState();
}

class _ListAnItemScreenState extends State<ListAnItemScreen> {
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
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
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

                  const SizedBox(width: 12),

                  // Search Bar
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {},
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
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
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      'List An Item',
                      style: Appthemes.textMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: appColors.darkBlueText,
                        decoration: TextDecoration.underline,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Add Your Item Button
                    GestureDetector(
                      onTap: () {
                        Get.to(() => ListItemForm());
                      },
                      child: AddItemButton(
                        ontap: () {
                          Get.to(() => ListItemForm());
                        },
                        text: 'Add Your Item',
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
