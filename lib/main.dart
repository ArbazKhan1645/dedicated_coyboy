// ignore_for_file: unused_catch_clause, non_constant_identifier_names, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/services/chat_room_service/chat_room_service.dart';
import 'package:dedicated_cowboy/app/services/chat_service/chat_service.dart';
import 'package:dedicated_cowboy/app/services/firebase_notifications/firebase_notification_service.dart';
import 'package:dedicated_cowboy/bindings/initial_bindings.dart';
import 'package:dedicated_cowboy/firebase_options.dart';
import 'package:dedicated_cowboy/views/welcome/welcome_view.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    host: 'firestore.googleapis.com',
    sslEnabled: true,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  try {
    await Get.putAsync(() => ChatService().init());
  } catch (e, stackTrace) {
    Get.log('Error initializing AuthService: $e\n$stackTrace', isError: true);
  }

  try {
    await Get.putAsync(() => AuthService().init());
  } catch (e, stackTrace) {
    Get.log('Error initializing AuthService: $e\n$stackTrace', isError: true);
  }

  final ai_chat_service = AIChatService(
    apiKey:
        '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',
    baseUrl: 'https://api.openai.com/v1',
    systemPrompt:
        "want to rewrite the description , for instant enchance the very short description, i am passing the original description . the original description is:",
  );

  await Get.putAsync(() => ai_chat_service.init());

  // await EmailTemplates.sendListingUnderReviewEmail(
  //   recipientEmail: 'shahlili1645@gmail.com',
  //   recipientName: 'Shah Lili',
  //   listingTitle: 'Testing Laptop Arbaz',
  //   listingUrl: 'https://dedicatedcowboy.com/Testing Laptop Arbaz',
  // );

  // final userStatusService = UserStatusService();
  // userStatusService.init();

  // await NotificationService().initialize();
  // await SubscriptionService().initializeSubscriptionPlans();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          initialBinding: InitialBindings(),
          title: 'Dedicated Cowboy',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'popins', // 👈 Set default font
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2C3E50), // Use your dark blue
            ),
            useMaterial3: true,
            primarySwatch: Colors.brown,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          transitionDuration: const Duration(milliseconds: 200),
          defaultTransition: Transition.rightToLeft,
          home: WelcomeView(),
        );
      },
    );
  }
}

Future<String> uploadMedia(
  List<File> files, {
  String? directory,
  int? width,
  int? height,
}) async {
  var uri = Uri.parse('https://api.tjara.com/api/media/insert');

  var request = http.MultipartRequest('POST', uri);

  request.headers.addAll({
    'X-Request-From': 'Application',
    'Accept': 'application/json',
  });

  // Add media files
  for (var file in files) {
    var stream = http.ByteStream(file.openRead());
    var length = await file.length();

    var multipartFile = http.MultipartFile(
      'media[]',
      stream,
      length,
      filename: path.basename(file.path),
    );

    request.files.add(multipartFile);
  }

  // Add optional parameters
  if (directory != null) {
    request.fields['directory'] = directory;
  }

  if (width != null) {
    request.fields['width'] = width.toString();
  }

  if (height != null) {
    request.fields['height'] = height.toString();
  }

  // Send request and allow redirects
  var response = await request.send();

  // Handle redirect manually
  if (response.statusCode == 302 || response.statusCode == 301) {
    var redirectUrl = response.headers['location'];
    if (redirectUrl != null) {
      return await uploadMedia(
        files,
        directory: directory,
        width: width,
        height: height,
      );
    }
  }

  if (response.statusCode == 200) {
    var responseBody = await response.stream.bytesToString();
    var jsonData = jsonDecode(responseBody);

    return jsonData['media'][0]['optimized_media_url'];
  } else {
    return 'Failed to upload media. Status code: ${response.statusCode} Response body: ${await response.stream.bytesToString()}';
  }
}
