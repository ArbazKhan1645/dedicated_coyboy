// lib/bindings/initial_bindings.dart
import 'package:dedicated_cowboy/views/home/controller/home_controller.dart';
import 'package:dedicated_cowboy/views/listing/events_listings/controller/add_listing_controller.dart';
import 'package:dedicated_cowboy/views/listing/item_listing/controller/add_listing_controller.dart';
import 'package:dedicated_cowboy/views/sign_in/controller/sign_in_controller.dart';
import 'package:dedicated_cowboy/views/sign_up/controller/sign_up_controller.dart';
import 'package:get/get.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // Get.put(SignInController(), permanent: true);
    // Get.put(SignUpController(), permanent: true);
    // Get.put(HomeController(), permanent: true);
    // Get.put(ListItemController(), permanent: true);
    // Get.put(ListEventController(), permanent: true);
  }
}
