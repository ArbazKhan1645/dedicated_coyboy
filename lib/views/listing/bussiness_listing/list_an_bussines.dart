import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/consts/appthemes.dart';
import 'package:dedicated_cowboy/views/listing/bussiness_listing/list_bussiness_form.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/list_item_form.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/widgets/add_item_button.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class ListAnBussinessScreen extends StatefulWidget {
  const ListAnBussinessScreen({Key? key}) : super(key: key);

  @override
  State<ListAnBussinessScreen> createState() => _ListAnBussinessScreenState();
}

class _ListAnBussinessScreenState extends State<ListAnBussinessScreen> {
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
                      onTap: () => Get.back(),
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
                    'List a Business',
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
                        Get.to(() => ListItemForm());
                      },
                      child: AddItemButton(
                        ontap: () {
                          Get.to(() => ListBusinessForm());
                        },
                        text: 'Add Your Business',
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
