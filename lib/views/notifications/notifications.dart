import 'package:dedicated_cowboy/app/services/firebase_notifications/firebase_notification_service.dart';
import 'package:dedicated_cowboy/consts/appcolors.dart';
import 'package:dedicated_cowboy/views/chats/chats_view.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// notifications_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/models/notification_model/notification_model.dart';
import 'package:get/get.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  final FirebaseNotificationService _notificationService =
      FirebaseNotificationService();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  // Cache the stream to prevent recreation
  late Stream<List<NotificationModel>> _notificationsStream;

  bool _isLoading = false;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );

    // Cache the stream once
    _notificationsStream = _notificationService.getUserNotifications();

    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUnreadNotifications();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final count = await _notificationService.getUnreadNotificationsCount();
      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          _hasUnreadNotifications = count > 0;
        });
      }
    } catch (e) {
      print('Error checking unread notifications: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isLoading) return; // Prevent multiple simultaneous calls

    setState(() => _isLoading = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        final batch = FirebaseFirestore.instance.batch();

        final unreadNotifications =
            await FirebaseFirestore.instance
                .collection('notifications')
                .where('receiverId', isEqualTo: currentUserId)
                .where('isRead', isEqualTo: false)
                .get();

        for (var doc in unreadNotifications.docs) {
          batch.update(doc.reference, {'isRead': true});
        }

        await batch.commit();

        if (mounted) {
          setState(() {
            _hasUnreadNotifications = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All notifications marked as read'),
              backgroundColor: Color(0xFFF2B342),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notifications as read'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification.id)
            .update({'isRead': true});

        // Don't call _checkUnreadNotifications() here as the StreamBuilder
        // will automatically update when Firestore data changes
      } catch (e) {
        print('Error marking notification as read: $e');
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notification'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onNotificationTap(NotificationModel notification) {
    _markAsRead(notification);

    // Navigate based on notification type
    switch (notification.type) {
      case 'message':
      case 'chat':
        if (notification.data?['chatRoomId'] != null) {
          Get.to(
            () => const ChatMessageScreen(),
            arguments: {
              'chatRoomId': notification.data?['chatRoomId'] ?? '',
              'currentUserId': FirebaseAuth.instance.currentUser!.uid,
              'otherUserId': notification.receiverId,
            },
          );
        }
        break;
      case 'like':
      case 'comment':
        if (notification.postId != null) {
          print('Navigate to post: ${notification.postId}');
        }
        break;
      case 'follow':
        print('Navigate to profile: ${notification.senderId}');
        break;
      default:
        print('Handle notification: ${notification.type}');
    }
  }

  Future<void> _refreshNotifications() async {
    _refreshController.forward();

    // Recreate the stream to force refresh
    setState(() {
      _notificationsStream = _notificationService.getUserNotifications();
    });

    await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.reset();

    // Check unread notifications after refresh
    await _checkUnreadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_hasUnreadNotifications) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_hasUnreadNotifications)
            IconButton(
              icon: Icon(Icons.done_all, color: Colors.blue),
              onPressed: _isLoading ? null : _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) async {
              switch (value) {
                case 'mark_all_read':
                  await _markAllAsRead();
                  break;
                case 'refresh':
                  await _refreshNotifications();
                  break;
                case 'cleanup':
                  await _notificationService.cleanupDuplicateNotifications();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notifications cleaned up')),
                    );
                  }
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20),
                        SizedBox(width: 8),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'cleanup',
                    child: Row(
                      children: [
                        Icon(Icons.cleaning_services, size: 20),
                        SizedBox(width: 8),
                        Text('Clean duplicates'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: StreamBuilder<List<NotificationModel>>(
          stream: _notificationsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error loading notifications',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _refreshNotifications,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            // Update unread notifications count based on stream data
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final hasUnread = notifications.any((n) => !n.isRead);
              if (_hasUnreadNotifications != hasUnread) {
                setState(() {
                  _hasUnreadNotifications = hasUnread;
                });
              }
            });

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _refreshAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_refreshAnimation.value * 0.1),
                          child: Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When you get notifications, they\'ll show up here',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // Group notifications by read/unread
            final unreadNotifications =
                notifications.where((n) => !n.isRead).toList()
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            final readNotifications =
                notifications.where((n) => n.isRead).toList()
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return ListView(
              controller: _scrollController,
              children: [
                // Unread Section
                if (unreadNotifications.isNotEmpty) ...[
                  _buildSectionHeader('Unread', unreadNotifications.length),
                  ...unreadNotifications.map(
                    (notification) =>
                        _buildNotificationItem(notification, isUnread: true),
                  ),
                ],

                // Read Section
                if (readNotifications.isNotEmpty) ...[
                  _buildSectionHeader('Read', readNotifications.length),
                  ...readNotifications.map(
                    (notification) =>
                        _buildNotificationItem(notification, isUnread: false),
                  ),
                ],

                SizedBox(height: 80), // Bottom padding
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: title == 'Unread' ? Colors.red : Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification, {
    required bool isUnread,
  }) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('Delete Notification'),
                    content: Text(
                      'Are you sure you want to delete this notification?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        _deleteNotification(notification);
      },
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isUnread ? Colors.blue.withOpacity(0.05) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isUnread ? Colors.blue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                      image:
                          notification.senderAvatar.isNotEmpty
                              ? DecorationImage(
                                image: NetworkImage(notification.senderAvatar),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        notification.senderAvatar.isEmpty
                            ? Icon(
                              _getNotificationIcon(notification.type),
                              color: Colors.grey[600],
                              size: 20,
                            )
                            : null,
                  ),
                  // Notification type indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notification.type),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Color(0xff364C63),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: notification.senderName,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: ' ${notification.body}',
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      notification.relativeTime,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
      case 'chat':
        return Icons.message;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
      case 'chat':
        return Colors.blue;
      case 'like':
        return Colors.red;
      case 'comment':
        return Color(0xFFF2B342);
      case 'follow':
        return Colors.purple;
      case 'system':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Contact Us',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You can get touch with us through below platforms,\nour team will reach out to you as soon as possible',
              style: TextStyle(color: Colors.black, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 32),

            // Customer Support Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Support',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Phone contact
                  InkWell(
                    onTap: () => _launchPhone('1-877-332-3248'),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Contact Number',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '1-877-332-3248 (DC4U)',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email contact
                  InkWell(
                    onTap: () => _launchEmail('info@dedicatedcowboy.com'),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.email_outlined,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'info@dedicatedcowboy.com',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
            const SizedBox(height: 24),

            // Social Media Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Social media',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSocialMediaItem(
                    'Instagram',
                    'dedicatedcowboy',
                    const Color(0xFFE4405F),
                    FontAwesomeIcons.instagram,
                    () => _launchURL(
                      'https://www.instagram.com/dedicatedcowboy/?igsh=MWpqMTEwdTlqanFqYg%3D%3D',
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSocialMediaItem(
                    'Facebook',
                    'dedicatedcowboy',
                    const Color(0xFF1877F2),
                    FontAwesomeIcons.facebook,
                    () => _launchURL(
                      'https://www.facebook.com/people/Dedicated-Cowboy/100090563776256/?mibextid=uzlsIk',
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSocialMediaItem(
                    'YouTube',
                    'dedicatedcowboy',
                    const Color(0xFFFF0000),
                    FontAwesomeIcons.youtube,
                    () => _launchURL(
                      'https://www.youtube.com/watch?v=gH3h6Z4XWDE&feature=youtu.be',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaItem(
    String platform,
    String username,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platform,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                username,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
