import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final Map<String, ChatParticipant> participantData; // New field
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSender;
  final Map<String, int> unreadCount;
  final String? productId;
  final String? productTitle;
  final String? productImage;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.participantData,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSender,
    required this.unreadCount,
    this.productId,
    this.productTitle,
    this.productImage,
    required this.createdAt,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantData:
          (data['participantData'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, ChatParticipant.fromMap(value)),
          ) ??
          {},
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime']?.toDate(),
      lastMessageSender: data['lastMessageSender'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      productId: data['productId'],
      productTitle: data['productTitle'],
      productImage: data['productImage'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantData': participantData.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastMessageSender': lastMessageSender,
      'unreadCount': unreadCount,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'createdAt': createdAt,
    };
  }
}

class ChatParticipant {
  final String userId;
  final String displayName;
  final String? avatar;
  final bool isOnline;

  ChatParticipant({
    required this.userId,
    required this.displayName,
    this.avatar,
    this.isOnline = false,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      userId: map['userId'],
      displayName: map['displayName'] ?? 'Unknown',
      avatar: map['avatar'],
      isOnline: map['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatar': avatar,
      'isOnline': isOnline,
    };
  }
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? imageUrl;
  final bool isOptimistic;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
    this.imageUrl,
    this.isOptimistic = false,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values[data['type'] ?? 0],
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      status: MessageStatus.values[data['status'] ?? 0],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.index,
      'timestamp': timestamp,
      'status': status.index,
      'imageUrl': imageUrl,
    };
  }

  Message copyWith({
    MessageStatus? status,
    String? imageUrl,
    bool? isOptimistic,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      timestamp: timestamp,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }
}

enum MessageType { text, image }

enum MessageStatus { sending, sent, delivered, read, failed }
