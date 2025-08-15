import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  var searchController = TextEditingController();
  List<Category> get categories => [
    Category(
      title: 'Western Style',
      imageUrl: 'assets/images/Rectangle 3463809.png',
    ),
    Category(
      title: 'Home & Ranch Decor',
      imageUrl: 'assets/images/Rectangle 3463809 (1).png',
    ),
    Category(
      title: 'Tack & Live Stock',
      imageUrl: 'assets/images/Rectangle 3463809 (2).png',
    ),
    Category(
      title: 'Western Life & Events',
      imageUrl: 'assets/images/Rectangle 3463809 (3).png',
    ),
    Category(
      title: 'Businesses & Services',
      imageUrl: "assets/images/Rectangle 3463809 (4).png",
    ),
  ];
}

class Category {
  final String title;
  final String imageUrl;
  final String subtitle;

  Category({required this.title, required this.imageUrl, this.subtitle = ''});
}
