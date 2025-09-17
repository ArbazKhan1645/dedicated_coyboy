import 'dart:async';

import 'package:dedicated_cowboy/app/models/api_user_model.dart';
import 'package:dedicated_cowboy/app/models/chat/chat_room-model.dart';
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
  final Rx<ApiUserModel?> otherUser = Rx<ApiUserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isTyping = false.obs;
  final RxBool showEmojiPicker = false.obs;
  final Rx<Message?> replyingTo = Rx<Message?>(null);

  // Controllers
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode messageFocusNode = FocusNode();

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

    // Listen to focus changes to hide emoji picker
    messageFocusNode.addListener(() {
      if (messageFocusNode.hasFocus) {
        showEmojiPicker.value = false;
      }
    });
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    _typingTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    messageFocusNode.dispose();
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
              Get.snackbar(
                'Error',
                'Failed to load messages',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Color(0xFFF2B342),
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
            },
          );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to initialize chat',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Combined messages (optimistic + real)
  List<Message> get combinedMessages {
    final List<Message> combined = [];

    // Add optimistic messages first (only those that are still sending)
    combined.addAll(
      optimisticMessages.where(
        (msg) => msg.isOptimistic && msg.status == MessageStatus.sending,
      ),
    );

    // Add real messages, filtering out deleted messages for current user
    for (final message in messages) {
      // Skip deleted messages that are deleted for current user
      if (message.deletedFor?.contains(currentUserId) == true) {
        continue;
      }

      // Check if there's a matching optimistic message
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

    final replyToMessage = replyingTo.value;

    // Clear input and reply immediately
    messageController.clear();
    clearReply();

    // Create optimistic message with unique ID to prevent duplicates
    final optimisticId = '${const Uuid().v4()}_optimistic';
    final optimisticMessage = Message(
      id: optimisticId,
      senderId: currentUserId,
      receiverId: otherUserId,
      content: content,
      type: MessageType.text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      isOptimistic: true,
      replyTo: replyToMessage,
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
        replyTo: replyToMessage,
      );

      // Remove optimistic message immediately after sending
      optimisticMessages.removeWhere((msg) => msg.id == optimisticId);

      try {
        FirebaseNotificationService notificationService =
            FirebaseNotificationService();
        var currentUser = await _chatService.getUserProfile(currentUserId);
        if (currentUser != null) {
          await notificationService.sendNotificationToUser(
            receiverId: otherUserId,
            title: '${currentUser.displayName ?? 'Someone'} sent you a message',
            body: content,
            type: 'chat',
            data: {'chatRoomId': chatRoomId, 'messageType': 'message'},
          );
        }
      } on Exception catch (e) {
        print('Failed to send notification: $e');
      }
    } catch (e) {
      // Update optimistic message to failed status
      final index = optimisticMessages.indexWhere(
        (msg) => msg.id == optimisticId,
      );
      if (index != -1) {
        optimisticMessages[index] = optimisticMessage.copyWith(
          status: MessageStatus.failed,
        );
      }

      Get.snackbar(
        'Error',
        'Failed to send message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
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
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to clear chat',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void sendImageMessage() async {
    // Create optimistic image message with unique ID
    final optimisticId = '${const Uuid().v4()}_image_optimistic';
    final optimisticMessage = Message(
      id: optimisticId,
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

      // Remove optimistic message immediately after sending
      optimisticMessages.removeWhere((msg) => msg.id == optimisticId);
    } catch (e) {
      // Update optimistic message to failed
      final index = optimisticMessages.indexWhere(
        (msg) => msg.id == optimisticId,
      );
      if (index != -1) {
        optimisticMessages[index] = optimisticMessage.copyWith(
          status: MessageStatus.failed,
        );
      }
      print(e.toString());

      Get.snackbar('Error', 'Failed to send image $e',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),);
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
          replyTo: message.replyTo,
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

  // Reply functionality
  void setReplyMessage(Message message) {
    replyingTo.value = message;
    messageFocusNode.requestFocus();
    showEmojiPicker.value = false;
  }

  void clearReply() {
    replyingTo.value = null;
  }

  // Delete functionality
  void deleteMessageForMe(Message message) async {
    try {
      await _chatService.deleteMessageForUser(
        chatRoomId: chatRoomId,
        messageId: message.id,
        userId: currentUserId,
      );

      Get.snackbar('Success', 'Message deleted',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete message',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),);
    }
  }

  void deleteMessageForEveryone(Message message) async {
    try {
      await _chatService.deleteMessageForEveryone(
        chatRoomId: chatRoomId,
        messageId: message.id,
      );

      Get.snackbar('Success', 'Message deleted for everyone',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete message',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),);
    }
  }

  // Emoji functionality
  void toggleEmojiPicker() {
    showEmojiPicker.value = !showEmojiPicker.value;
    if (showEmojiPicker.value) {
      messageFocusNode.unfocus();
    } else {
      messageFocusNode.requestFocus();
    }
  }

  void addEmoji(String emoji) {
    final currentText = messageController.text;
    final selection = messageController.selection;

    if (selection.baseOffset == -1) {
      messageController.text = currentText + emoji;
      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: messageController.text.length),
      );
    } else {
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        emoji,
      );
      messageController.text = newText;
      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: selection.baseOffset + emoji.length),
      );
    }
  }

  void backspaceEmoji() {
    final currentText = messageController.text;
    final selection = messageController.selection;

    if (currentText.isEmpty) return;

    if (selection.baseOffset == -1 || selection.baseOffset == 0) return;

    final newText =
        currentText.substring(0, selection.baseOffset - 1) +
        currentText.substring(selection.baseOffset);

    messageController.text = newText;
    messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: selection.baseOffset - 1),
    );
  }
}
