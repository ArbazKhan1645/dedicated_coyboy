import 'dart:async';

import 'package:dedicated_cowboy/app/models/chat/chat_room-model.dart';
import 'package:dedicated_cowboy/app/models/user_model.dart';
import 'package:dedicated_cowboy/app/services/chat_room_service/chat_room_service.dart';
import 'package:dedicated_cowboy/app/services/firebase_notifications/firebase_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  final ChatService _chatService = ChatService.instance;

  // Observable variables
  final RxList<Message> messages = <Message>[].obs;
  final RxList<Message> optimisticMessages = <Message>[].obs;
  final Rx<UserModel?> otherUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isTyping = false.obs;

  // Controllers
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Variables
  late String chatRoomId;
  late String currentUserId;
  late String otherUserId;
  StreamSubscription<List<Message>>? _messagesSubscription;
  Timer? _typingTimer;

  @override
  void onInit() {
    super.onInit();
    // Get arguments from navigation
    final args = Get.arguments as Map<String, dynamic>;
    currentUserId = args['currentUserId'];
    otherUserId = args['otherUserId'];
    chatRoomId = args['chatRoomId'];

    _initializeChat();
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    _typingTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _initializeChat() async {
    try {
      isLoading.value = true;

      // Get other user profile
      otherUser.value = await _chatService.getUserProfile(otherUserId);

      // Mark messages as read
      await _chatService.markMessagesAsRead(chatRoomId, currentUserId);

      // Listen to messages
      _messagesSubscription = _chatService
          .getMessages(chatRoomId)
          .listen(
            (messagesList) {
              messages.value = messagesList;
              _scrollToBottom();
            },
            onError: (error) {
              Get.snackbar('Error', 'Failed to load messages');
            },
          );
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize chat');
    } finally {
      isLoading.value = false;
    }
  }

  // Combined messages (optimistic + real)
  List<Message> get combinedMessages {
    final List<Message> combined = [];

    // Add optimistic messages first
    combined.addAll(optimisticMessages.where((msg) => msg.isOptimistic));

    // Add real messages, filtering out any that match optimistic ones
    for (final message in messages) {
      final hasOptimistic = optimisticMessages.any(
        (opt) =>
            opt.content == message.content &&
            opt.senderId == message.senderId &&
            opt.timestamp.difference(message.timestamp).abs().inSeconds < 5,
      );

      if (!hasOptimistic) {
        combined.add(message);
      }
    }

    // Sort by timestamp
    combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return combined;
  }

  void sendTextMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty) return;

    // Clear input immediately
    messageController.clear();

    // Create optimistic message
    final optimisticMessage = Message(
      id: const Uuid().v4(),
      senderId: currentUserId,
      receiverId: otherUserId,
      content: content,
      type: MessageType.text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      isOptimistic: true,
    );

    // Add to optimistic messages
    optimisticMessages.insert(0, optimisticMessage);
    _scrollToBottom();

    try {
      // Send to Firebase
      await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: currentUserId,
        receiverId: otherUserId,
        content: content,
      );

      // Update optimistic message status
      final index = optimisticMessages.indexWhere(
        (msg) => msg.id == optimisticMessage.id,
      );
      if (index != -1) {
        optimisticMessages[index] = optimisticMessage.copyWith(
          status: MessageStatus.sent,
        );
      }

      // Remove optimistic message after a delay (real message will replace it)
      Timer(const Duration(seconds: 2), () {
        optimisticMessages.removeWhere((msg) => msg.id == optimisticMessage.id);
      });
      try {
        FirebaseNotificationService notificationService =
            FirebaseNotificationService();
        var currentUser = await _chatService.getUserProfile(currentUserId);
        if (currentUser != null) {
          await notificationService.sendNotificationToUser(
            receiverId: otherUserId,
            title:
                currentUser.displayName ??
                'Someone'
                    'has sent you a message',
            body: content,
            type: 'chat',
            data: {'chatRoomId': chatRoomId, 'messageType': 'message'},
          );
        }
      } on Exception catch (e) {
        print('failed to send the notification to the user');
      }
    } catch (e) {
      // Update optimistic message to failed status
      final index = optimisticMessages.indexWhere(
        (msg) => msg.id == optimisticMessage.id,
      );
      if (index != -1) {
        optimisticMessages[index] = optimisticMessage.copyWith(
          status: MessageStatus.failed,
        );
      }

      Get.snackbar('Error', 'Failed to send message');
    }
  }

  void clearChat() async {
    try {
      isLoading.value = true;

      // Clear messages from Firebase
      await _chatService.clearChatMessages(chatRoomId);

      // Clear local messages
      messages.clear();
      optimisticMessages.clear();

      // Show success message
      Get.snackbar(
        'Success',
        'Chat cleared successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to clear chat',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void sendImageMessage() async {
    // Create optimistic image message
    final optimisticMessage = Message(
      id: const Uuid().v4(),
      senderId: currentUserId,
      receiverId: otherUserId,
      content: 'Sending image...',
      type: MessageType.image,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      isOptimistic: true,
    );

    try {
      optimisticMessages.insert(0, optimisticMessage);
      _scrollToBottom();

      await _chatService.pickAndSendImage(
        chatRoomId: chatRoomId,
        senderId: currentUserId,
        receiverId: otherUserId,
      );

      // Remove optimistic message
      optimisticMessages.removeWhere((msg) => msg.id == optimisticMessage.id);
    } catch (e) {
      // Update optimistic message to failed
      final index = optimisticMessages.indexWhere(
        (msg) => msg.id == optimisticMessage.id,
      );
      if (index != -1) {
        optimisticMessages[index] = optimisticMessage.copyWith(
          status: MessageStatus.failed,
        );
      }

      Get.snackbar('Error', 'Failed to send image');
    }
  }

  void onTyping() {
    isTyping.value = true;
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      isTyping.value = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void retryFailedMessage(Message message) async {
    if (message.type == MessageType.text) {
      // Update message status to sending
      final index = optimisticMessages.indexWhere(
        (msg) => msg.id == message.id,
      );
      if (index != -1) {
        optimisticMessages[index] = message.copyWith(
          status: MessageStatus.sending,
        );
      }

      try {
        await _chatService.sendMessage(
          chatRoomId: chatRoomId,
          senderId: currentUserId,
          receiverId: otherUserId,
          content: message.content,
        );

        // Remove optimistic message
        optimisticMessages.removeWhere((msg) => msg.id == message.id);
      } catch (e) {
        // Update back to failed
        final retryIndex = optimisticMessages.indexWhere(
          (msg) => msg.id == message.id,
        );
        if (retryIndex != -1) {
          optimisticMessages[retryIndex] = message.copyWith(
            status: MessageStatus.failed,
          );
        }
      }
    }
  }
}
