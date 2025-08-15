// notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String receiverId;
  final String title;
  final String body;
  final String type; // 'message', 'like', 'comment', 'follow', 'system'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? chatId;
  final String? postId;
  final String? actionType; // 'reply', 'like', 'comment', 'share'

  NotificationModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.receiverId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.chatId,
    this.postId,
    this.actionType,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'receiverId': receiverId,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'data': data,
      'chatId': chatId,
      'postId': postId,
      'actionType': actionType,
    };
  }

  // Create from Firestore document
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown User',
      senderAvatar: map['senderAvatar'] ?? map['avatar'] ?? '',
      receiverId: map['receiverId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      data: map['data'],
      chatId: map['chatId'],
      postId: map['postId'],
      actionType: map['actionType'],
    );
  }

  // Copy with method for updates
  NotificationModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? receiverId,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? chatId,
    String? postId,
    String? actionType,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      receiverId: receiverId ?? this.receiverId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      chatId: chatId ?? this.chatId,
      postId: postId ?? this.postId,
      actionType: actionType ?? this.actionType,
    );
  }

  // Get relative time (e.g., "2 hours ago", "1 day ago")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else {
      return '${(difference.inDays / 30).floor()}mo';
    }
  }

  // Get notification icon based on type
  String get notificationIcon {
    switch (type) {
      case 'message':
        return 'assets/icons/message_icon.png';
      case 'like':
        return 'assets/icons/like_icon.png';
      case 'comment':
        return 'assets/icons/comment_icon.png';
      case 'follow':
        return 'assets/icons/follow_icon.png';
      case 'system':
        return 'assets/icons/system_icon.png';
      default:
        return 'assets/icons/notification_icon.png';
    }
  }

  // Get priority for sorting
  int get priority {
    switch (type) {
      case 'message':
        return 5;
      case 'like':
        return 3;
      case 'comment':
        return 4;
      case 'follow':
        return 2;
      case 'system':
        return 1;
      default:
        return 0;
    }
  }
}