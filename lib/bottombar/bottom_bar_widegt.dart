import 'package:dedicated_cowboy/app/services/firebase_notifications/firebase_notification_service.dart';
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:dedicated_cowboy/views/chats/chats_view.dart';
import 'package:dedicated_cowboy/views/chats/rooms.dart';
import 'package:dedicated_cowboy/views/explore/explore.dart';
import 'package:dedicated_cowboy/views/home/home_view.dart';
import 'package:dedicated_cowboy/views/profile/views/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CustomCurvedNavBar extends StatelessWidget {
  CustomCurvedNavBar({super.key});

  final NavController controller = Get.put(NavController());

  Widget _buildTab({
    required String imagePath,
    required String label,
    required bool isSelected,
  }) {
    return SizedBox(
      width: 60.w,
      height: 55.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: isSelected ? 28.w : 24.w,
            height: isSelected ? 28.h : 24.h,
            color:
                isSelected ? appColors.black : appColors.grey.withOpacity(0.6),
          ),
          if (!isSelected) ...[
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: appColors.grey.withOpacity(0.8),
                fontSize: 9.sp,
                fontWeight: FontWeight.w400,
                fontFamily: 'Popins',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: controller.getPage(controller.selectedIndex.value),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: CurvedNavigationBar(
            index: controller.selectedIndex.value,
            height: 65.h,
            color: appColors.white,
            backgroundColor: appColors.transparent,
            buttonBackgroundColor: appColors.white,
            animationDuration: const Duration(milliseconds: 300),
            animationCurve: Curves.easeInOut,
            items: List.generate(controller.tabs.length, (index) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 5.h),
                child: _buildTab(
                  imagePath: controller.tabs[index]['image'],
                  label: controller.tabs[index]['label'],
                  isSelected: controller.selectedIndex.value == index,
                ),
              );
            }),
            onTap: controller.changeTab,
          ),
        ),
      ),
    );
  }
}

class NavController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  final List<Map<String, dynamic>> tabs = [
    {'image': 'assets/images/home.png', 'label': 'Home'},
    {'image': 'assets/images/Explore.png', 'label': 'Explore'},
    {'image': 'assets/images/chat.png', 'label': 'Chat'},
    {'image': 'assets/images/person.png', 'label': 'My Account'},
  ];

  /// Persistent instance of Chat screen
  final ChatScreen _chatScreen = const ChatScreen();

  Widget getPage(int index) {
    switch (index) {
      case 0:
        return HomeView();
      case 1:
        return const ExampleExploreApp();
      case 2:
        return _chatScreen; // keep alive
      case 3:
        return const ProfileView();
      default:
        return HomeView();
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeNotificationService();
  }

  final FirebaseNotificationService _notificationService =
      FirebaseNotificationService();
  Future<void> _initializeNotificationService() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  void changeTab(int index) {
    selectedIndex.value = index;
    if (index == 2) {
      if (Get.isRegistered<ChatRoomsController>() == false) {
        Get.put(ChatRoomsController(), permanent: true);
      }
    }
  }
}
