// Chat Rooms Controller
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedicated_cowboy/app/models/chat/chat_room-model.dart';
import 'package:dedicated_cowboy/app/models/user_model.dart';
import 'package:dedicated_cowboy/app/services/chat_room_service/chat_room_service.dart';
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/views/chats/chats_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatRoomsController extends GetxController {
  final ChatService _chatService = ChatService.instance;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Observable variables
  final RxList<ChatRoom> chatRooms = <ChatRoom>[].obs;
  final RxList<ChatRoom> filteredChatRooms = <ChatRoom>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Controllers
  final TextEditingController searchController = TextEditingController();
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  Timer? _searchTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeChatRooms();
    _setupSearch();
  }

  @override
  void onClose() {
    _chatRoomsSubscription?.cancel();
    _searchTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void _initializeChatRooms() {
    isLoading.value = true;

    _chatRoomsSubscription = _chatService
        .getChatRooms(currentUserId)
        .listen(
          (rooms) {
            chatRooms.value = rooms;
            _filterChatRooms();
            isLoading.value = false;
          },
          onError: (error) {
            isLoading.value = false;
            Get.snackbar('Error', 'Failed to load chats',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),);
          },
        );
  }

  void _setupSearch() {
    searchController.addListener(() {
      _searchTimer?.cancel();
      _searchTimer = Timer(const Duration(milliseconds: 300), () {
        searchQuery.value = searchController.text;
        _filterChatRooms();
      });
    });
  }

  void _filterChatRooms() {
    if (searchQuery.value.isEmpty) {
      filteredChatRooms.value = chatRooms;
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredChatRooms.value =
          chatRooms.where((room) {
            final otherUserId = room.participants.firstWhere(
              (id) => id != currentUserId,
            );
            final participant = room.participantData[otherUserId];
            final userName = participant?.displayName.toLowerCase() ?? '';
            final lastMessage = room.lastMessage?.toLowerCase() ?? '';

            return userName.contains(query) || lastMessage.contains(query);
          }).toList();
    }
  }

  ChatParticipant? getOtherParticipant(ChatRoom room) {
    final otherUserId = room.participants.firstWhere(
      (id) => id != currentUserId,
    );
    return room.participantData[otherUserId];
  }

  void navigateToChat(ChatRoom chatRoom) {
    final otherUserId = chatRoom.participants.firstWhere(
      (id) => id != currentUserId,
    );

    Get.to(
      () => const ChatMessageScreen(),
      arguments: {
        'chatRoomId': chatRoom.id,
        'currentUserId': currentUserId,
        'otherUserId': otherUserId,
      },
    );

    // Mark messages as read
    _chatService.markMessagesAsRead(chatRoom.id, currentUserId);
  }

  Future<void> createNewChat({
    required String otherUserId,
    required UserModel otherUser,
    String? productId,
    String? productTitle,
    String? productImage,
  }) async {
    try {
      final currentUser = await _chatService.getUserProfile(otherUserId);
      if (currentUser == null) throw Exception('Current user not found');

      final chatRoomId = await _chatService.createOrGetChatRoom(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        currentUser: currentUser,
        otherUser: otherUser,
        productId: productId,
        productTitle: productTitle,
        productImage: productImage,
      );

      Get.to(
        () => const ChatMessageScreen(),
        arguments: {
          'chatRoomId': chatRoomId,
          'currentUserId': currentUserId,
          'otherUserId': otherUserId,
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to create chat',    snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFF2B342),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),);
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _filterChatRooms();
  }
}

// Main Chat Screen (WhatsApp Home Screen Style)
class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatRoomsController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAFAF5),
          body: SafeArea(
            child: Column(
              children: [
                // Header with title and menu
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chats',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: appColors.grey.withOpacity(.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search chats',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 22,
                      ),
                      suffixIcon: Obx(
                        () =>
                            controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                  onPressed: controller.clearSearch,
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                )
                                : const SizedBox.shrink(),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Chat List
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    if (controller.filteredChatRooms.isEmpty) {
                      return _buildEmptyState(
                        controller.searchQuery.value.isNotEmpty,
                      );
                    }

                    return ListView.builder(
                      itemCount: controller.filteredChatRooms.length,
                      itemBuilder: (context, index) {
                        final chatRoom = controller.filteredChatRooms[index];

                        return _buildChatTile(
                          chatRoom: chatRoom,

                          currentUserId: controller.currentUserId,
                          onTap: () => controller.navigateToChat(chatRoom),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No chats found' : 'No chats yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try searching for something else'
                : 'Start a conversation with someone',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          // if (!isSearching)
          //   Padding(
          //     padding: const EdgeInsets.only(top: 24),
          //     child: ElevatedButton.icon(
          //       onPressed: () {
          //         ChatService.instance.createOrGetChatRoom(
          //           currentUserId: FirebaseAuth.instance.currentUser!.uid,
          //           otherUserId: '13124313523456345345',
          //         );
          //         // Navigate to contacts or user selection
          //       },
          //       icon: const Icon(Icons.add_comment),
          //       label: const Text('Start New Chat'),
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: const Color(0xFF25D366),
          //         foregroundColor: Colors.white,
          //         padding: const EdgeInsets.symmetric(
          //           horizontal: 24,
          //           vertical: 12,
          //         ),
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(25),
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildChatTile({
    required ChatRoom chatRoom,
    required String currentUserId,
    required VoidCallback onTap,
  }) {
    final unreadCount = chatRoom.unreadCount[currentUserId] ?? 0;
    final isLastMessageFromMe = chatRoom.lastMessageSender == currentUserId;
    final hasLastMessage = chatRoom.lastMessage != null;

    final otherParticipant =
        chatRoom.participantData[chatRoom.participants.firstWhere(
          (id) => id != currentUserId,
        )];

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Profile Avatar with Online Status
            Stack(
              children: [
                // Avatar with fallback
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Colors
                          .orange[100], // Light orange background for initials
                  child: Stack(
                    children: [
                      if (otherParticipant?.avatar != null)
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: otherParticipant!.avatar!,
                            placeholder:
                                (context, url) =>
                                    _buildInitialsAvatar(otherParticipant),
                            errorWidget:
                                (context, url, error) =>
                                    _buildInitialsAvatar(otherParticipant),
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
                          ),
                        ),
                      if (otherParticipant?.avatar == null)
                        _buildInitialsAvatar(otherParticipant),
                    ],
                  ),
                ),

                // Online status indicator
                if (otherParticipant?.isOnline == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Chat Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Time Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherParticipant?.displayName ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                      if (hasLastMessage)
                        Text(
                          _formatChatTime(chatRoom.lastMessageTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Last Message
                  Row(
                    children: [
                      if (hasLastMessage && isLastMessageFromMe)
                        const Icon(
                          Icons.done_all,
                          size: 16,
                          color: Colors.grey,
                        ),
                      if (hasLastMessage && isLastMessageFromMe)
                        const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hasLastMessage
                              ? chatRoom.lastMessage!
                              : 'Start chatting',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(ChatParticipant? user) {
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

  void _showChatOptions(ChatRoom chatRoom, UserModel? user) {
    Get.bottomSheet(
      Container(
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

            // User info
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    user?.avatar != null
                        ? CachedNetworkImageProvider(user!.avatar!)
                        : null,
                child:
                    user?.avatar == null
                        ? Text(
                          (user?.displayName ?? '?')
                              .substring(0, 1)
                              .toUpperCase(),
                        )
                        : null,
              ),
              title: Text(user?.displayName ?? 'Unknown User'),
              subtitle: Text(user?.isOnline == true ? 'Online' : 'Offline'),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Chat',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Get.back();
                _showDeleteChatDialog(chatRoom, user);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteChatDialog(ChatRoom chatRoom, UserModel? user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Chat'),
        content: Text(
          'Are you sure you want to delete your chat with ${user?.displayName ?? 'this user'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              // Implement delete chat
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today - show time
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
    } else if (messageDate == yesterday) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      // Older - show date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
