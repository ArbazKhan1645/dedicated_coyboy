// Chat Message Screen
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedicated_cowboy/app/models/chat/chat_room-model.dart';
import 'package:dedicated_cowboy/app/models/user_model.dart';
import 'package:dedicated_cowboy/app/services/chat_room_service/chat_room_service.dart';
import 'package:dedicated_cowboy/views/chats/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ChatMessageScreen extends StatelessWidget {
  const ChatMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      init: ChatController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Obx(() {
                        final user = controller.otherUser.value;
                        return Expanded(
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        Colors
                                            .orange[100], // Light orange background for initials
                                    child: Stack(
                                      children: [
                                        if (user?.avatar != null)
                                          ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: user!.avatar!,
                                              placeholder:
                                                  (context, url) =>
                                                      _buildInitialsAvatar(
                                                        user,
                                                      ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      _buildInitialsAvatar(
                                                        user,
                                                      ),
                                              fit: BoxFit.cover,
                                              width: 48,
                                              height: 48,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (user?.isOnline == true)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.displayName ?? 'Loading...',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Obx(
                                      () => Text(
                                        user?.isOnline == true
                                            ? 'Online'
                                            : user?.lastSeen != null
                                            ? 'Last seen ${_formatLastSeen(user!.lastSeen!)}'
                                            : 'Offline',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              controller.isTyping.value
                                                  ? Colors.blue
                                                  : user?.isOnline == true
                                                  ? Color(0xffF3B340)
                                                  : Colors.grey,
                                          fontStyle:
                                              controller.isTyping.value
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.grey,
                          size: 22,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'clear':
                              _showClearChatDialog(context, controller);
                              break;
                            case 'block':
                              _showBlockUserDialog(context, controller);
                              break;
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'clear',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.clear_all,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Clear Chat'),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                ),

                // Messages Area
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    final messages = controller.combinedMessages;

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start your conversation',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: controller.scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + 1, // +1 for date separator
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          // Date separator at the beginning
                          return _buildDateSeparator(DateTime.now());
                        }

                        final message = messages[index];
                        final isMe =
                            message.senderId == controller.currentUserId;
                        final showAvatar =
                            index == messages.length - 1 ||
                            messages[index + 1].senderId != message.senderId;

                        return _buildMessageBubble(
                          message: message,
                          isMe: isMe,
                          showAvatar: showAvatar && !isMe,
                          controller: controller,
                        );
                      },
                    );
                  }),
                ),

                // Message Input
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Emoji Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Implement emoji picker
                              _showEmojiPicker(context, controller);
                            },
                            icon: const Icon(
                              Icons.sentiment_satisfied_alt,
                              color: Colors.grey,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Text Input
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 120),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: TextField(
                              controller: controller.messageController,
                              maxLines: null,
                              textInputAction: TextInputAction.newline,
                              onChanged: (value) {
                                controller.onTyping();
                              },
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  controller.sendTextMessage();
                                }
                              },
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Attachment Button
                        // Container(
                        //   decoration: BoxDecoration(
                        //     color: Colors.grey[100],
                        //     shape: BoxShape.circle,
                        //   ),
                        //   child: IconButton(
                        //     onPressed: () {
                        //       _showAttachmentOptions(context, controller);
                        //     },
                        //     icon: const Icon(
                        //       Icons.attach_file,
                        //       color: Colors.grey,
                        //       size: 22,
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(width: 4),

                        // Send Button
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: controller.messageController,
                          builder: (context, value, child) {
                            final hasText = value.text.trim().isNotEmpty;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color:
                                    hasText
                                        ? const Color(0xFF364C63)
                                        : Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed:
                                    hasText ? controller.sendTextMessage : null,
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialsAvatar(UserModel? user) {
    final displayName = user?.displayName ?? '?';
    final initials =
        displayName.isNotEmpty
            ? displayName.substring(0, 1).toUpperCase()
            : '?';

    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.orange, // Darker orange for contrast
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDateSeparator(date),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required Message message,
    required bool isMe,
    required bool showAvatar,
    required ChatController controller,
  }) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe && showAvatar) ...[
          CircleAvatar(
            radius: 12,
            backgroundColor:
                Colors.orange[100], // Light orange background for initials
            child: Stack(
              children: [
                if (controller.otherUser.value?.avatar != null)
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: controller.otherUser.value?.avatar ?? '',
                      placeholder:
                          (context, url) =>
                              _buildInitialsAvatar(controller.otherUser.value),
                      errorWidget:
                          (context, url, error) =>
                              _buildInitialsAvatar(controller.otherUser.value),
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ] else if (!isMe) ...[
          const SizedBox(width: 30),
        ],

        Flexible(
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (message.status == MessageStatus.failed) {
                    controller.retryFailedMessage(message);
                  }
                },
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: Get.width * 0.75,
                    minWidth: 60,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isMe
                            ? (message.status == MessageStatus.failed
                                ? Colors.red[100]
                                : const Color(0xFF364C63))
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child:
                      message.type == MessageType.image
                          ? _buildImageMessage(message, isMe)
                          : _buildTextMessage(message, isMe),
                ),
              ),

              const SizedBox(height: 4),

              // Message status and time
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildMessageStatusIcon(message.status),
                  ],
                ],
              ),
            ],
          ),
        ),

        if (isMe) const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTextMessage(Message message, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.content,
          style: TextStyle(
            fontSize: 15,
            color:
                isMe
                    ? (message.status == MessageStatus.failed
                        ? Colors.red[800]
                        : Colors.white)
                    : Colors.black87,
            height: 1.3,
          ),
        ),
        if (message.status == MessageStatus.failed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red[600]),
                const SizedBox(width: 4),
                Text(
                  'Tap to retry',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImageMessage(Message message, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: message.imageUrl!,
              width: 200,
              height: 150,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.grey),
                  ),
            ),
          )
        else
          Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (message.status == MessageStatus.sending)
                  const CircularProgressIndicator(strokeWidth: 2)
                else if (message.status == MessageStatus.failed)
                  Icon(Icons.error_outline, color: Colors.red[600])
                else
                  const Icon(Icons.image, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  message.status == MessageStatus.sending
                      ? 'Uploading...'
                      : message.status == MessageStatus.failed
                      ? 'Failed to upload'
                      : 'Image',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

        if (message.status == MessageStatus.failed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red[600]),
                const SizedBox(width: 4),
                Text(
                  'Tap to retry',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.grey[400],
          ),
        );
      case MessageStatus.sent:
        return Icon(Icons.done, size: 16, color: Colors.grey[400]);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 16, color: Colors.grey[400]);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 16, color: Color(0xFF4FC3F7));
      case MessageStatus.failed:
        return Icon(Icons.error_outline, size: 16, color: Colors.red[400]);
    }
  }

  void _showAttachmentOptions(BuildContext context, ChatController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      color: Colors.pink,
                      onTap: () {
                        Get.back();
                        _pickImageFromCamera(controller);
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      color: Colors.purple,
                      onTap: () {
                        Get.back();
                        controller.sendImageMessage();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.insert_drive_file,
                      label: 'Document',
                      color: Colors.indigo,
                      onTap: () {
                        Get.back();
                        // Implement document picker
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _pickImageFromCamera(ChatController controller) async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        await ChatService.instance.sendImageMessage(
          chatRoomId: controller.chatRoomId,
          senderId: controller.currentUserId,
          receiverId: controller.otherUserId,
          imageFile: File(image.path),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture image');
    }
  }

  void _showEmojiPicker(BuildContext context, ChatController controller) {
    // Simple emoji selection - you can implement a full emoji picker
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: 250,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          childAspectRatio: 1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _commonEmojis.length,
                    itemBuilder: (context, index) {
                      final emoji = _commonEmojis[index];
                      return GestureDetector(
                        onTap: () {
                          controller.messageController.text += emoji;
                          controller
                              .messageController
                              .selection = TextSelection.fromPosition(
                            TextPosition(
                              offset: controller.messageController.text.length,
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showClearChatDialog(BuildContext context, ChatController controller) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Chat'),
            content: const Text(
              'Are you sure you want to clear this chat? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  controller.clearChat();
                  // Implement clear chat functionality
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showBlockUserDialog(BuildContext context, ChatController controller) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Block User'),
            content: Text(
              'Are you sure you want to block ${controller.otherUser.value?.displayName ?? 'this user'}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  // Implement block user functionality
                },
                child: const Text('Block', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour =
        hour == 0
            ? 12
            : hour > 12
            ? hour - 12
            : hour;

    return '$displayHour:$minute $period';
  }

  // Common emojis for quick access
  static const List<String> _commonEmojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '🤣',
    '😂',
    '🙂',
    '🙃',
    '😉',
    '😊',
    '😇',
    '🥰',
    '😍',
    '🤩',
    '😘',
    '😗',
    '😚',
    '😙',
    '😋',
    '😛',
    '😜',
    '🤪',
    '😝',
    '🤑',
    '🤗',
    '🤭',
    '🤫',
    '🤔',
    '🤐',
    '🤨',
    '😐',
    '😑',
    '😶',
    '😏',
    '😒',
    '🙄',
    '😬',
    '🤥',
    '😔',
    '😕',
    '🙁',
    '😖',
    '😗',
    '😢',
    '😭',
    '😤',
    '😠',
    '😡',
    '🤬',
    '🤯',
    '😳',
    '🥵',
    '🥶',
    '😱',
    '😨',
    '😰',
    '😥',
    '😓',
    '🤗',
    '🤔',
    '🤭',
    '🤫',
  ];
}
