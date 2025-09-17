// Chat Message Screen with enhanced features
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedicated_cowboy/app/models/api_user_model.dart';
import 'package:dedicated_cowboy/app/models/chat/chat_room-model.dart';
import 'package:dedicated_cowboy/app/services/chat_room_service/chat_room_service.dart';
import 'package:dedicated_cowboy/views/chats/controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            child: WillPopScope(
              onWillPop: () async {
                if (controller.showEmojiPicker.value) {
                  controller.showEmojiPicker.value = false;
                  return false;
                }
                return true;
              },
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
                                      backgroundColor: Colors.orange[100],
                                      child: Stack(
                                        children: [
                                          if (user?.avatarUrls != null)
                                            ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl: user!.avatarUrls['24']?? '',
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
                                   
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                  // Reply preview
                  Obx(() {
                    final replyMessage = controller.replyingTo.value;
                    if (replyMessage == null) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF364C63),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  replyMessage.senderId ==
                                          controller.currentUserId
                                      ? 'You'
                                      : controller
                                              .otherUser
                                              .value
                                              ?.displayName ??
                                          'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Color(0xFF364C63),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  replyMessage.type == MessageType.image
                                      ? '📷 Photo'
                                      : replyMessage.content,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: controller.clearReply,
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    );
                  }),

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
                        itemCount: messages.length + 1,
                        separatorBuilder:
                            (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return _buildDateSeparator(DateTime.now());
                          }

                          final message = messages[index];
                          final isMe =
                              message.senderId == controller.currentUserId;
                          final showAvatar =
                              index == messages.length - 1 ||
                              messages[index + 1].senderId != message.senderId;

                          return _buildSwipeableMessage(
                            message: message,
                            isMe: isMe,
                            showAvatar: showAvatar && !isMe,
                            controller: controller,
                            context: context,
                          );
                        },
                      );
                    }),
                  ),

                  // Message Input
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Input row
                        Padding(
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
                                  child: Obx(
                                    () => IconButton(
                                      onPressed: controller.toggleEmojiPicker,
                                      icon: Icon(
                                        controller.showEmojiPicker.value
                                            ? Icons.keyboard
                                            : Icons.sentiment_satisfied_alt,
                                        color:
                                            controller.showEmojiPicker.value
                                                ? const Color(0xFF364C63)
                                                : Colors.grey,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Text Input
                                Expanded(
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 120,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: controller.messageController,
                                      focusNode: controller.messageFocusNode,
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
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      _showAttachmentOptions(
                                        context,
                                        controller,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.attach_file,
                                      color: Colors.grey,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Send Button
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: controller.messageController,
                                  builder: (context, value, child) {
                                    final hasText =
                                        value.text.trim().isNotEmpty;
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            hasText
                                                ? const Color(0xFF364C63)
                                                : Colors.grey[400],
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed:
                                            hasText
                                                ? controller.sendTextMessage
                                                : null,
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

                        // Emoji Picker
                        Obx(() {
                          if (!controller.showEmojiPicker.value) {
                            return const SizedBox.shrink();
                          }

                          return _buildEmojiPicker(controller);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialsAvatar(ApiUserModel? user) {
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
          color: Colors.orange,
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

  Widget _buildSwipeableMessage({
    required Message message,
    required bool isMe,
    required bool showAvatar,
    required ChatController controller,
    required BuildContext context,
  }) {
    return Dismissible(
      key: Key(message.id),
      direction:
          isMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
      background: Container(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        padding: EdgeInsets.only(left: isMe ? 0 : 20, right: isMe ? 20 : 0),
        child: Icon(Icons.reply, color: Colors.grey[600], size: 24),
      ),
      onDismissed: (direction) {
        // Reset the dismissible
        controller.setReplyMessage(message);
      },
      confirmDismiss: (direction) async {
        controller.setReplyMessage(message);
        return false; // Don't actually dismiss
      },
      child: GestureDetector(
        onLongPress: () {
          _showMessageOptions(context, message, controller);
        },
        child: _buildMessageBubble(
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
          controller: controller,
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
            backgroundColor: Colors.orange[100],
            child: Stack(
              children: [
                if (controller.otherUser.value?.avatarUrls != null)
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: controller.otherUser.value?.avatarUrls['24'] ?? '',
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
              // Reply preview in bubble
              if (message.replyTo != null)
                Container(
                  constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isMe
                              ? const Color.fromARGB(255, 194, 1, 1)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: isMe ? Colors.white : const Color(0xFF364C63),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.replyTo!.senderId == controller.currentUserId
                              ? 'You'
                              : controller.otherUser.value?.displayName ??
                                  'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color:
                                isMe
                                    ? Colors.white.withOpacity(0.8)
                                    : const Color(0xFF364C63),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message.replyTo!.type == MessageType.image
                              ? '📷 Photo'
                              : message.replyTo!.content,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isMe
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

              // Main message
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
                    color: _getMessageBubbleColor(message, isMe),
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
                  child: _getMessageContent(message, isMe),
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

  Color _getMessageBubbleColor(Message message, bool isMe) {
    if (message.deletedBy != null) {
      return Colors.grey[100]!;
    }

    if (isMe) {
      return message.status == MessageStatus.failed
          ? Colors.red[100]!
          : Color(0xffF4F3EF);
    }

    return Colors.white;
  }

  Widget _getMessageContent(Message message, bool isMe) {
    // Check if message is deleted
    if (message.deletedBy != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            message.deletedBy != FirebaseAuth.instance.currentUser?.uid
                ? 'This message was deleted'
                : 'deleted this message',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    if (message.type == MessageType.image) {
      return _buildImageMessage(message, isMe);
    }

    return _buildTextMessage(message, isMe);
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
                        : Colors.black)
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

  Widget _buildEmojiPicker(ChatController controller) {
    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Emoji categories tabs
          // Container(
          //   height: 40,
          //   padding: const EdgeInsets.symmetric(horizontal: 16),
          //   child: Row(
          //     children: [
          //       _buildEmojiCategoryTab('😀', true),
          //       _buildEmojiCategoryTab('❤️', false),
          //       _buildEmojiCategoryTab('🎉', false),
          //       _buildEmojiCategoryTab('⚽', false),
          //       _buildEmojiCategoryTab('🍕', false),
          //       _buildEmojiCategoryTab('🏠', false),
          //       _buildEmojiCategoryTab('🔢', false),
          //       const Spacer(),
          //       GestureDetector(
          //         onTap: controller.backspaceEmoji,
          //         child: Container(
          //           padding: const EdgeInsets.all(8),
          //           child: Icon(
          //             Icons.backspace_outlined,
          //             size: 20,
          //             color: Colors.grey[600],
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // Emoji grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _commonEmojis.length,
              itemBuilder: (context, index) {
                final emoji = _commonEmojis[index];
                return GestureDetector(
                  onTap: () => controller.addEmoji(emoji),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiCategoryTab(String emoji, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            isSelected
                ? const Color(0xFF364C63).withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 18)),
    );
  }

  void _showMessageOptions(
    BuildContext context,
    Message message,
    ChatController controller,
  ) {
    final isMyMessage = message.senderId == controller.currentUserId;
    final isDeletedMessage = message.deletedBy != null;

    if (isDeletedMessage) return; // Don't show options for deleted messages

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
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Reply option
                ListTile(
                  leading: const Icon(Icons.reply, color: Colors.blue),
                  title: const Text('Reply'),
                  onTap: () {
                    Get.back();
                    controller.setReplyMessage(message);
                  },
                ),

                // Delete options (only for own messages)
                if (isMyMessage) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text('Delete for me'),
                    onTap: () {
                      Get.back();
                      _showDeleteConfirmation(
                        context,
                        message,
                        controller,
                        false,
                      );
                    },
                  ),

                  // Only show "Delete for everyone" if message is recent (within 1 hour)
                  if (DateTime.now().difference(message.timestamp).inHours < 1)
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      title: const Text('Delete for everyone'),
                      onTap: () {
                        Get.back();
                        _showDeleteConfirmation(
                          context,
                          message,
                          controller,
                          true,
                        );
                      },
                    ),
                ] else ...[
                  // Delete for me option for other's messages
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text('Delete for me'),
                    onTap: () {
                      Get.back();
                      _showDeleteConfirmation(
                        context,
                        message,
                        controller,
                        false,
                      );
                    },
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Message message,
    ChatController controller,
    bool deleteForEveryone,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              deleteForEveryone ? 'Delete for everyone?' : 'Delete message?',
            ),
            content: Text(
              deleteForEveryone
                  ? 'This message will be deleted for everyone in this chat.'
                  : 'This message will be deleted for you only.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  if (deleteForEveryone) {
                    controller.deleteMessageForEveryone(message);
                  } else {
                    controller.deleteMessageForMe(message);
                  }
                },
                child: Text('Delete', style: TextStyle(color: Colors.red[600])),
              ),
            ],
          ),
    );
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
      Get.snackbar(
        'Error',
        'Failed to capture image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
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
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
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
