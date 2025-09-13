// firebase_notification_service.dart
// ignore_for_file: avoid_print, unnecessary_import, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dedicated_cowboy/app/models/notification_model/notification_model.dart';
import 'package:dedicated_cowboy/app/models/user_model.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase Notification Service
class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Static avatar paths
  static const List<String> staticAvatars = [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    'assets/avatars/avatar4.png',
  ];

  // Collections
  static const String usersCollection = 'users';
  static const String notificationsCollection = 'notifications';
  static const String chatsCollection = 'chats';

  // Notification channels
  static const String chatChannelId = 'chat_notifications';
  static const String generalChannelId = 'general_notifications';

  String? _currentUserToken;
  String? _currentUserId;
  final authService = Get.find<AuthService>();

  // Initialize Firebase Messaging
  Future<void> initialize() async {
    final user = authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    _currentUserId = user.id;

    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get and save FCM token
    await _initializeFCMToken();

    // Setup message handlers
    _setupMessageHandlers();

    // Update user status
    await _updateUserOnlineStatus(true);

    print('Firebase Notification Service initialized successfully');
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      chatChannelId,
      'Chat Notifications',
      description: 'Notifications for chat messages',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
          generalChannelId,
          'General Notifications',
          description: 'General app notifications',
          importance: Importance.defaultImportance,
        );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(generalChannel);
  }

  // Initialize FCM token
  Future<void> _initializeFCMToken() async {
    try {
      _currentUserToken = await _firebaseMessaging.getToken();
      if (_currentUserToken != null && _currentUserId != null) {
        await _saveTokenToFirestore(_currentUserToken!, _currentUserId!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) async {
        _currentUserToken = token;
        if (_currentUserId != null) {
          await _saveTokenToFirestore(token, _currentUserId!);
        }
      });
    } catch (e) {
      print('Error initializing FCM token: $e');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token, String userId) async {
    try {
      final user = authService.currentUser;

      if (user == null) return;

      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      }

      // 🔍 Step 1: Check if token already exists for another user
      final existing =
          await _firestore
              .collection(usersCollection)
              .where('fcmToken', isEqualTo: token)
              .get();

      for (var doc in existing.docs) {
        if (doc.id != userId) {
          // Remove token from that user
          await _firestore.collection(usersCollection).doc(doc.id).update({
            'fcmToken': FieldValue.delete(),
            'deviceId': FieldValue.delete(),
            'deviceType': FieldValue.delete(),
          });
        }
      }

      // 🔄 Step 2: Save token for current user
      await _firestore.collection(usersCollection).doc(userId).set({
        'fcmToken': token,
        'deviceId': deviceId,
        'deviceType': Platform.isAndroid ? 'android' : 'ios',
        'lastSeen': DateTime.now().toIso8601String(),
        'isOnline': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Cache token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      print('✅ FCM token updated successfully');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // Get user avatar (randomly assign if not set)
  Future<String> _getUserAvatar(String userId) async {
    try {
      final doc =
          await _firestore.collection(usersCollection).doc(userId).get();
      if (doc.exists && doc.data()?['avatar'] != null) {
        return doc.data()!['avatar'];
      }

      // Assign random avatar
      return staticAvatars[userId.hashCode % staticAvatars.length];
    } catch (e) {
      return staticAvatars[0];
    }
  }

  // Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Handle terminated app message taps
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleBackgroundMessageTap(message);
      }
    });
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Save notification to Firestore
    await _saveNotificationToFirestore(message);
    // Show local notification
    await _showLocalNotification(message);
  }

  // Handle background message tap
  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    print('Message tapped: ${message.messageId}');

    // Navigate to appropriate screen based on message data
    if (message.data['type'] == 'chat') {
      // Navigate to chat screen
      // You can use a navigation service or global navigator key
      _navigateToChat(message.data['senderId'], message.data['chatId']);
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    try {
      // Get sender avatar

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            chatChannelId,
            'Chat Notifications',
            channelDescription: 'Notifications for chat messages',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',

            styleInformation: BigTextStyleInformation(
              notification.body ?? '',
              contentTitle: notification.title,
              summaryText: 'New message',
            ),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            // actions: [
            //   const AndroidNotificationAction(
            //     'reply',
            //     'Reply',
            //     inputs: [
            //       AndroidNotificationActionInput(label: 'Type a message...'),
            //     ],
            //   ),
            //   const AndroidNotificationAction('mark_read', 'Mark as Read'),
            // ],
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav',
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(data),
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);

      if (response.actionId == 'reply') {
        // Handle reply action
        _handleQuickReply(data, response.input);
      } else if (response.actionId == 'mark_read') {
        // Mark as read
        _markNotificationAsRead(data['notificationId']);
      } else {
        // Navigate to chat
        _navigateToChat(data['senderId'], data['chatId']);
      }
    }
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final data = message.data;
      final notification = NotificationModel(
        id:
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: data['senderId'] ?? '',
        senderName: data['senderName'] ?? 'Unknown',
        receiverId: _currentUserId ?? '',
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        senderAvatar: data['avatar'] ?? staticAvatars[0],
        type: data['type'] ?? 'general',
        data: data,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _firestore
          .collection(notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());

      print('Notification saved to Firestore');
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  // UPDATED: Send notification to specific user with proper validation
  Future<bool> sendNotificationToUser({
    required String receiverId,
    required String title,
    required String body,
    required String type,
    String? senderId,
    Map<String, dynamic>? data,
    String? chatId,
  }) async {
    try {
      final user = authService.currentUser;

      // Get current user ID
      final currentUserId = user?.id;

      // Use provided senderId or fallback to current user
      final actualSenderId = senderId ?? currentUserId;

      // CRITICAL: Prevent sending notification to self
      if (receiverId == actualSenderId || receiverId == currentUserId) {
        print(
          'BLOCKED: Not sending notification to self. Receiver: $receiverId, Sender: $actualSenderId, Current: $currentUserId',
        );
        return false;
      }

      // Double validation that receiverId and senderId are different
      if (receiverId == actualSenderId) {
        print('BLOCKED: Receiver and sender are the same: $receiverId');
        return false;
      }

      print(
        'VALIDATION PASSED: Sending notification from $actualSenderId to $receiverId',
      );

      // Check for duplicate recent notifications (within last 10 seconds)
      final tenSecondsAgo = DateTime.now().subtract(
        const Duration(seconds: 10),
      );
      final recentNotifications =
          await _firestore
              .collection(notificationsCollection)
              .where('receiverId', isEqualTo: receiverId)
              .where('senderId', isEqualTo: actualSenderId)
              .where('type', isEqualTo: type)
              .where('timestamp', isGreaterThan: tenSecondsAgo)
              .limit(1)
              .get();

      if (recentNotifications.docs.isNotEmpty) {
        print('BLOCKED: Duplicate notification detected within 10 seconds');
        return false;
      }

      // Get receiver's data
      final receiverDoc =
          await _firestore.collection(usersCollection).doc(receiverId).get();

      if (!receiverDoc.exists) {
        print('BLOCKED: Receiver not found: $receiverId');
        return false;
      }

      final receiverData = UserModel.fromJson(receiverDoc.data()!);

      // Get sender data
      final senderData = await _getCurrentUserData();
      if (senderData == null) {
        print('BLOCKED: Sender data not found');
        return false;
      }

      // Final validation - ensure sender and receiver are different users
      if (senderData.uid == receiverData.uid) {
        print('BLOCKED: Sender and receiver are the same user');
        return false;
      }

      // Create unique notification ID to prevent duplicates
      final notificationId =
          '${actualSenderId}_${receiverId}_${type}_${DateTime.now().millisecondsSinceEpoch}';

      // Prepare notification data
      final notificationData = {
        'senderId': senderData.uid,
        'senderName': senderData.displayName,
        'receiverId': receiverId,
        'type': type,
        'avatar': senderData.avatar,
        'chatId': chatId,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'notificationId': notificationId,
        ...?data,
      };

      // Send FCM message only if receiver has a valid token
      bool fcmSuccess = false;
      if (receiverData.fcmToken != null && receiverData.fcmToken!.isNotEmpty) {
        fcmSuccess = await _sendFCMMessage(
          token: receiverData.fcmToken!,
          title: title,
          body: body,
          data: notificationData,
        );
        print('FCM sent: $fcmSuccess');
      } else {
        print('WARNING: Receiver has no FCM token');
      }

      // Always save notification to Firestore for offline users and history
      final notification = NotificationModel(
        id: notificationId,
        senderId: senderData.uid,
        senderName: senderData.displayName ?? '',
        receiverId: receiverId,
        title: title,
        body: body,
        senderAvatar: senderData.avatar ?? staticAvatars[0],
        type: type,
        data: notificationData,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _firestore
          .collection(notificationsCollection)
          .doc(notificationId)
          .set(notification.toMap());

      print('Notification saved to Firestore with ID: $notificationId');
      print('Final result - FCM: $fcmSuccess, Firestore: true');

      return true; // Return true if at least Firestore save was successful
    } catch (e) {
      print('ERROR in sendNotificationToUser: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Send FCM message using HTTP API
  Future<bool> _sendFCMMessage({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get access token using service account credentials
      final accessToken = await _getAccessToken();

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/cowboy-9bf1f/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {'title': title, 'body': body},
            'data': data.map(
              (key, value) => MapEntry(key, value.toString()),
            ), // Convert all values to strings
          },
        }),
      );

      if (response.statusCode == 200) {
        print('FCM message sent successfully');
        return true;
      } else {
        print(
          'FCM failed with status: ${response.statusCode}, body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error sending FCM message: $e');
      return false;
    }
  }

  Future<String> _getAccessToken() async {
    final credentials = ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": "cowboy-9bf1f",
      "private_key_id": "681896a830757f06602ef42b0878932eb1082320",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQChoZHedpsJtkX9\nmR2ErgS+eeHYxeDM45+cR0GpyoNhoaLEwyx5z8vnAJMydn8eMcu7QqVTCrzqENp/\nUUQV/PBZmAQDvrgOky7vChG56yFgHVYrbikdrq7c87Oiyw8iIQ1rLrC1d2b3i1ne\n+pMRyYBPcPqJ1BFX28ROHBb5sWkfAXC1oKEkkXBtqvAtQxb5JLB1GVrX+Hs5oHEq\ncktphryTTb0uC20hDujH32UWXpUu4BlHN7gDE+/llvbNVG/53ugAi3ky/IhO5zO0\nVgixxuyEWLdzji69uhiHe3hRRc3BSG7xRyf0Nd6r1CpMphVKi2cUTb5WkgIFTCDM\n0IiVBGG5AgMBAAECggEAQb8pyV7gmPZCiTJX7gklV9/XTSjM1TtAST85CBqfD79C\nqRwlQtWSgUBcH/pQohUqZN1qx5lGGEZLwt9pPTJ7CE7MT0Ostg0L2eN0K3boSCMW\n0qrIYdEVQz6Ek1NbMAxW24MOEXrk8QwHviqaWXFoVqhD2X3goib8trM5a09NzfTP\n0IQwNb8eGd35N1cOjzF0I9YhYmLH5mYVEFLyCVLS6zlUAu0BferNLT4st7idJILx\nrj8JnYJusmJZ6myXzYILCVxOeVgeOOIrietsN59Asz+YD25WbYxxOJNFsXXLw+GE\nWCDboIhjZLY4aGReUSQ7TiUh/+YHvlWX3e+KV0UhuwKBgQDWP6NKF/Hr6ayHj/M6\nTwMjPkNw5LqKFPuqJuHG3Nu1S2+hbSkSz3uMgZP+bexkd2dyaD8dy3C9mhhLLmp5\n/MKNerwHFGWsPtZ0SYnJZiSzPjt2ROuFuKXk7RRmWnmoz4Ofjm8gGvNffXTTA1RY\nICVKkXKviR8FFaCUKAXkZPJK2wKBgQDBIPhOUOlJ9P7kjoBpHWKrtxSNPkNq7kMr\nLaT/VIGx7yOMwO1feyEpT7TzvZflxi1n+YVpYswlbvtlMyKdtnQsDNkwhnB9jPPk\nQgxSUYVEjDe8j33burDj4lfWWzravaQtWXguZpYJza3oAaZfWERQeBO1f+tnGlK5\nnS/ajAsH+wKBgQCrG/YYtdkDtgOR3Ri/h90Up6SLJFIK98kq0pTdEwTx3QaRoTH9\nkPG2fMKqoDX84xQeXj2SWSl4c/pVCQQG2ySyg8RpzxOIpkL2asj9rXNAKEKrKU4E\n5TyxAduaB0ZE2T7hDouX045txC+qW21gWIQP8uvqX5QDposx6GkUSL7towKBgQCk\nlqCGvdXTPYPs7LTq4CwzAzf0l1eFTcDYj3HKWA6fwZmeXtztPlYoitE/2BgXrikM\nL05PXe91B3wf5tBdcBzZXanK/QfpN7KymMc/cFIO9SCbBf7Qv+34h/ErsVwbBvtf\n2pvdj3fWqv7GdoF/SA4QNgU17OqFV52gqiEaM7dC+QKBgQCvHSRsDiplzw8Vfvad\nGX/64nNVIP8D1RGzMomAwM+eYDSz8jeMYgz+nkarNN3QT/WGfuk4faBs9KyWZPmo\nEJ4EcqKrm5h/WvH8VjiBOWaaP+/Bpfgg3ucoQrTujGcLMHhg3o0B5vJoK/D9YQ+g\nYs4gH/rdJI4xySIe2KhHdEbBMg==\n-----END PRIVATE KEY-----\n",
      "client_email": "fcm-server@cowboy-9bf1f.iam.gserviceaccount.com",
      "client_id": "112460209134554040265",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/fcm-server%40cowboy-9bf1f.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com",
    });

    final client = await clientViaServiceAccount(credentials, [
      'https://www.googleapis.com/auth/firebase.messaging',
    ]);

    return client.credentials.accessToken.data;
  }

  // Get current user data
  Future<UserModel?> _getCurrentUserData() async {
    try {
      if (_currentUserId == null) return null;

      final doc =
          await _firestore
              .collection(usersCollection)
              .doc(_currentUserId!)
              .get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }

  // Get user notifications stream
  Stream<List<NotificationModel>> getUserNotifications() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(notificationsCollection)
        .where('receiverId', isEqualTo: _currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  // Mark notification as read
  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Update user online status
  Future<void> _updateUserOnlineStatus(bool isOnline) async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection(usersCollection).doc(_currentUserId!).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Handle quick reply
  Future<void> _handleQuickReply(
    Map<String, dynamic> data,
    String? reply,
  ) async {
    if (reply == null || reply.isEmpty) return;

    // Send reply message
    await sendNotificationToUser(
      receiverId: data['senderId'],
      title: 'New message',
      body: reply,
      type: 'chat',
      chatId: data['chatId'],
    );
  }

  // Navigate to chat (implement based on your navigation)
  void _navigateToChat(String? senderId, String? chatId) {
    // Implement navigation to chat screen
    // Get.to(() => NotificationScreen());
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get unread notifications count
  Future<int> getUnreadNotificationsCount() async {
    if (_currentUserId == null) return 0;

    try {
      final snapshot =
          await _firestore
              .collection(notificationsCollection)
              .where('receiverId', isEqualTo: _currentUserId)
              .where('isRead', isEqualTo: false)
              .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Clean up duplicate notifications
  Future<void> cleanupDuplicateNotifications() async {
    try {
      final user = authService.currentUser;
      if (user == null) {
        return;
      }
      final currentUserId = user.id;

      // Get all notifications for current user
      final notifications =
          await _firestore
              .collection(notificationsCollection)
              .where('receiverId', isEqualTo: currentUserId)
              .orderBy('timestamp', descending: true)
              .get();

      final Map<String, List<QueryDocumentSnapshot>> grouped = {};

      // Group by sender + type + approximate time (within 10 seconds)
      for (final doc in notifications.docs) {
        final data = doc.data();
        final senderId = data['senderId'] as String? ?? '';
        final type = data['type'] as String? ?? '';
        final timestamp = data['timestamp'] as Timestamp?;
        final timeInMillis = timestamp?.millisecondsSinceEpoch ?? 0;
        final timeGroup = (timeInMillis / 10000).floor(); // 10 second groups

        final key = '${senderId}_${type}_$timeGroup';
        grouped[key] = grouped[key] ?? [];
        grouped[key]!.add(doc);
      }

      // Delete duplicates (keep only the first one in each group)
      final batch = _firestore.batch();
      int deletedCount = 0;

      for (final group in grouped.values) {
        if (group.length > 1) {
          // Keep the first, delete the rest
          for (int i = 1; i < group.length; i++) {
            batch.delete(group[i].reference);
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        print('Cleaned up $deletedCount duplicate notifications');
      }
    } catch (e) {
      print('Error cleaning up duplicate notifications: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _updateUserOnlineStatus(false);
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}
