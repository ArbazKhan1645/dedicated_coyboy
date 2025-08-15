import 'package:dedicated_cowboy/app/models/chat/chat_room-model.dart';
import 'package:dedicated_cowboy/app/models/user_model.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:async';

class ChatService extends GetxService {
  Future<ChatService> init() async {
    return this;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  static ChatService get instance => Get.find<ChatService>();

  // Create or get existing chat room
  Future<String> createOrGetChatRoom({
    required String currentUserId,
    required String otherUserId,
    required UserModel currentUser,
    required UserModel otherUser,
    String? productId,
    String? productTitle,
    String? productImage,
  }) async {
    try {
      // Check if chat room already exists
      final existingRoom =
          await _firestore
              .collection('chatRooms')
              .where('participants', arrayContains: currentUserId)
              .get();

      for (var doc in existingRoom.docs) {
        final room = ChatRoom.fromFirestore(doc);
        if (room.participants.contains(otherUserId)) {
          return room.id;
        }
      }

      // Create new chat room with participant data
      final roomId = _uuid.v4();
      final chatRoom = ChatRoom(
        id: roomId,
        participants: [currentUserId, otherUserId],
        participantData: {
          currentUserId: ChatParticipant(
            userId: currentUserId,
            displayName: currentUser.displayName.toString(),
            avatar: currentUser.avatar,
            isOnline: currentUser.isOnline ?? false,
          ),
          otherUserId: ChatParticipant(
            userId: otherUserId,
            displayName: otherUser.displayName.toString(),
            avatar: otherUser.avatar,
            isOnline: otherUser.isOnline ?? false,
          ),
        },
        unreadCount: {currentUserId: 0, otherUserId: 0},
        productId: productId,
        productTitle: productTitle,
        productImage: productImage,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .set(chatRoom.toFirestore());

      return roomId;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updateParticipantData(
    String roomId,
    String userId,
    UserModel user,
  ) async {
    await _firestore.collection('chatRooms').doc(roomId).update({
      'participantData.$userId': {
        'userId': userId,
        'displayName': user.displayName,
        'avatar': user.avatar,
        'isOnline': user.isOnline,
      },
    });
  }

  // Get chat rooms for user

  // Get messages for chat room
  Stream<List<Message>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }

  Future<void> clearChatMessages(String chatRoomId) async {
    try {
      // Get reference to the messages collection
      final messagesRef = FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages');

      // Get all messages
      final QuerySnapshot snapshot = await messagesRef.get();

      // Delete all messages in batches (Firestore has a limit of 500 operations per batch)
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();

      // Optionally, update the chat room's last message
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .update({'lastMessage': '', 'lastMessageSenderId': ''});
    } catch (e) {
      throw Exception('Failed to clear chat messages: $e');
    }
  }

  // Send text message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      final messageId = _uuid.v4();
      final message = Message(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );

      // Add message to collection
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Update chat room last message
      await _updateChatRoomLastMessage(
        chatRoomId,
        content,
        senderId,
        receiverId,
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Send image message
  Future<String?> sendImageMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required File imageFile,
  }) async {
    try {
      final messageId = _uuid.v4();

      // Upload image to Firebase Storage
      final ref = _storage.ref().child('chat_images').child('$messageId.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Create message
      final message = Message(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        content: 'Image',
        type: MessageType.image,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        imageUrl: imageUrl,
      );

      // Add message to collection
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Update chat room last message
      await _updateChatRoomLastMessage(
        chatRoomId,
        'Image',
        senderId,
        receiverId,
      );

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to send image: $e');
    }
  }

  // Pick and send image
  Future<void> pickAndSendImage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        await sendImageMessage(
          chatRoomId: chatRoomId,
          senderId: senderId,
          receiverId: receiverId,
          imageFile: File(image.path),
        );
      }
    } catch (e) {
      throw Exception('Failed to pick and send image: $e');
    }
  }

  // Update chat room last message
  Future<void> _updateChatRoomLastMessage(
    String chatRoomId,
    String lastMessage,
    String senderId,
    String receiverId,
  ) async {
    final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    final chatRoomDoc = await chatRoomRef.get();

    if (chatRoomDoc.exists) {
      final chatRoom = ChatRoom.fromFirestore(chatRoomDoc);
      final updatedUnreadCount = Map<String, int>.from(chatRoom.unreadCount);
      updatedUnreadCount[receiverId] =
          (updatedUnreadCount[receiverId] ?? 0) + 1;

      await chatRoomRef.update({
        'lastMessage': lastMessage,
        'lastMessageTime': DateTime.now(),
        'lastMessageSender': senderId,
        'unreadCount': updatedUnreadCount,
      });
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    final chatRoomDoc = await chatRoomRef.get();

    if (chatRoomDoc.exists) {
      final chatRoom = ChatRoom.fromFirestore(chatRoomDoc);
      final updatedUnreadCount = Map<String, int>.from(chatRoom.unreadCount);
      updatedUnreadCount[userId] = 0;

      await chatRoomRef.update({'unreadCount': updatedUnreadCount});
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      print(userId);
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!..['id'] = doc.id);
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Update user online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now(),
      });
    } catch (e) {
      // Handle error
    }
  }
}
