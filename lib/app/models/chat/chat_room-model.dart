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

  // New fields for enhanced functionality
  final Message? replyTo; // The message being replied to
  final String? deletedBy; // User ID who deleted the message for everyone
  final List<String>?
  deletedFor; // List of user IDs who deleted this message for themselves
  final DateTime? deletedAt; // When the message was deleted

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
    this.replyTo,
    this.deletedBy,
    this.deletedFor,
    this.deletedAt,
  });

  // Create a copy of the message with updated fields
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? imageUrl,
    bool? isOptimistic,
    Message? replyTo,
    String? deletedBy,
    List<String>? deletedFor,
    DateTime? deletedAt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      replyTo: replyTo ?? this.replyTo,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedFor: deletedFor ?? this.deletedFor,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp,
      'status': status.name,
      'imageUrl': imageUrl,
      'replyTo': replyTo?.toReplyFirestore(),
      'deletedBy': deletedBy,
      'deletedFor': deletedFor,
      'deletedAt': deletedAt,
    };
  }

  // Convert reply data to Firestore (simplified version)
  Map<String, dynamic>? toReplyFirestore() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
    };
  }

  // Create Message from Firestore document
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse reply message if exists
    Message? replyTo;
    if (data['replyTo'] != null) {
      final replyData = data['replyTo'] as Map<String, dynamic>;
      replyTo = Message(
        id: replyData['id'] ?? '',
        senderId: replyData['senderId'] ?? '',
        receiverId: '', // Not needed for reply display
        content: replyData['content'] ?? '',
        type: MessageType.values.firstWhere(
          (e) => e.name == replyData['type'],
          orElse: () => MessageType.text,
        ),
        timestamp:
            (replyData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: MessageStatus.sent, // Default status for reply display
        imageUrl: replyData['imageUrl'],
      );
    }

    return Message(
      id: data['id'] ?? doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      imageUrl: data['imageUrl'],
      replyTo: replyTo,
      deletedBy: data['deletedBy'],
      deletedFor:
          data['deletedFor'] != null
              ? List<String>.from(data['deletedFor'])
              : null,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'imageUrl': imageUrl,
      'isOptimistic': isOptimistic,
      'replyTo': replyTo?.toJson(),
      'deletedBy': deletedBy,
      'deletedFor': deletedFor,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // Create Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    Message? replyTo;
    if (json['replyTo'] != null) {
      replyTo = Message.fromJson(json['replyTo']);
    }

    return Message(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      imageUrl: json['imageUrl'],
      isOptimistic: json['isOptimistic'] ?? false,
      replyTo: replyTo,
      deletedBy: json['deletedBy'],
      deletedFor:
          json['deletedFor'] != null
              ? List<String>.from(json['deletedFor'])
              : null,
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, content: $content, type: $type, timestamp: $timestamp, status: $status, replyTo: ${replyTo?.id}, deletedBy: $deletedBy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum MessageType { text, image, video, audio, file }

enum MessageStatus { sending, sent, delivered, read, failed }
