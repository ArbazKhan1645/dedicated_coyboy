// services/subscription_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/models/subscription/subscription_model.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'user_subscriptions';
  final String _plansCollection = 'subscription_plans';

  UserSubscription? _cachedSubscription;
  DateTime? _lastCacheUpdate;
  static const int _cacheValidityMinutes = 5;

  // Initialize subscription plans in Firestore (call this once during app setup)
  Future<void> initializeSubscriptionPlans() async {
    try {
      final plans = SubscriptionPlan.getDefaultPlans();
      final batch = _firestore.batch();

      for (final plan in plans) {
        final docRef = _firestore.collection(_plansCollection).doc(plan.id);
        batch.set(docRef, plan.toMap());
      }

      await batch.commit();
      print('Subscription plans initialized successfully');
    } catch (e) {
      print('Error initializing subscription plans: $e');
    }
  }

  // Get all available subscription plans
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final snapshot = await _firestore.collection(_plansCollection).get();
      return snapshot.docs
          .map((doc) => SubscriptionPlan.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching subscription plans: $e');
      return SubscriptionPlan.getDefaultPlans();
    }
  }

  // Create a new subscription
  Future<bool> createSubscription({
    required String userId,
    required SubscriptionPlan plan,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: plan.duration));
      final subscription = UserSubscription(
        id: '', // Will be set by Firestore
        userId: userId,
        plan: plan,
        purchaseDate: now,
        expiryDate: expiryDate,
        status: SubscriptionStatus.active,
        transactionId: transactionId,
        metadata: metadata ?? {},
      );

      // Cancel any existing active subscriptions first
      await _cancelExistingSubscriptions(userId);

      final docRef = await _firestore
          .collection(_collection)
          .add(subscription.toFirestore());

      // Update cache
      _cachedSubscription = subscription.copyWith(id: docRef.id);
      _lastCacheUpdate = DateTime.now();
      await _saveCacheToLocal();

      // Schedule notifications
      await _scheduleExpiryNotifications(subscription.copyWith(id: docRef.id));

      return true;
    } catch (e) {
      print('Error creating subscription: $e');
      return false;
    }
  }

  // Get user's current active subscription
  Future<UserSubscription?> getCurrentSubscription(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh &&
          _isCacheValid() &&
          _cachedSubscription?.userId == userId) {
        return _cachedSubscription;
      }

      final query =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .orderBy('expiryDate', descending: true)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        _cachedSubscription = null;
        await _clearCache();
        return null;
      }

      final subscription = UserSubscription.fromFirestore(query.docs.first);

      // Check if subscription is actually expired
      if (subscription.isExpired) {
        await _expireSubscription(subscription.id);
        _cachedSubscription = null;
        await _clearCache();
        return null;
      }

      // Update cache
      _cachedSubscription = subscription;
      _lastCacheUpdate = DateTime.now();
      await _saveCacheToLocal();

      return subscription;
    } catch (e) {
      print('Error getting current subscription: $e');
      // Try to load from local cache as fallback
      return await _loadCacheFromLocal();
    }
  }

  // Check if user has an active subscription
  Future<bool> hasActiveSubscription(String userId) async {
    final subscription = await getCurrentSubscription(userId);
    return subscription?.isActive == true;
  }

  // Check if user can create listings
  Future<bool> canUserList(String userId) async {
    return await hasActiveSubscription(userId);
  }

  // Get subscription status details
  Future<Map<String, dynamic>> getSubscriptionStatus(String userId) async {
    final subscription = await getCurrentSubscription(userId);

    if (subscription == null) {
      return {
        'hasSubscription': false,
        'isActive': false,
        'canList': false,
        'plan': null,
        'daysRemaining': 0,
        'hoursRemaining': 0,
        'expiryDate': null,
      };
    }

    return {
      'hasSubscription': true,
      'isActive': subscription.isActive,
      'canList': subscription.isActive,
      'plan': subscription.plan.toMap(),
      'daysRemaining': subscription.daysRemaining,
      'hoursRemaining': subscription.hoursRemaining,
      'expiryDate': subscription.expiryDate.toIso8601String(),
    };
  }

  // Cancel subscription
  Future<bool> cancelSubscription(String userId) async {
    try {
      final subscription = await getCurrentSubscription(userId);
      if (subscription == null) return false;

      await _firestore.collection(_collection).doc(subscription.id).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear cache
      _cachedSubscription = null;
      await _clearCache();

      // Cancel scheduled notifications
      await NotificationService().cancelNotification(subscription.id.hashCode);

      return true;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }

  // Get subscription history
  Future<List<UserSubscription>> getSubscriptionHistory(String userId) async {
    try {
      final query =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .orderBy('purchaseDate', descending: true)
              .get();

      return query.docs
          .map((doc) => UserSubscription.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting subscription history: $e');
      return [];
    }
  }

  // Private methods
  Future<void> _cancelExistingSubscriptions(String userId) async {
    final query =
        await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'active')
            .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> _expireSubscription(String subscriptionId) async {
    await _firestore.collection(_collection).doc(subscriptionId).update({
      'status': 'expired',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!).inMinutes <
        _cacheValidityMinutes;
  }

  Future<void> _saveCacheToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cachedSubscription != null) {
        final cacheData = {
          'subscription': _cachedSubscription!.toFirestore(),
          'lastUpdate': _lastCacheUpdate!.toIso8601String(),
        };
        await prefs.setString('cached_subscription', jsonEncode(cacheData));
      }
    } catch (e) {
      print('Error saving cache to local: $e');
    }
  }

  Future<UserSubscription?> _loadCacheFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('cached_subscription');
      if (cacheString == null) return null;

      final cacheData = jsonDecode(cacheString);
      _lastCacheUpdate = DateTime.parse(cacheData['lastUpdate']);

      if (_isCacheValid()) {
        // Reconstruct UserSubscription from cache
        final data = Map<String, dynamic>.from(cacheData['subscription']);
        _cachedSubscription = UserSubscription(
          id: data['id'] ?? '',
          userId: data['userId'] ?? '',
          plan: SubscriptionPlan.fromMap(data['plan']),
          purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
          expiryDate: (data['expiryDate'] as Timestamp).toDate(),
          status: SubscriptionStatus.values.firstWhere(
            (e) => e.toString() == 'SubscriptionStatus.${data['status']}',
            orElse: () => SubscriptionStatus.pending,
          ),
          transactionId: data['transactionId'],
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        );
        return _cachedSubscription;
      }
    } catch (e) {
      print('Error loading cache from local: $e');
    }
    return null;
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_subscription');
      _cachedSubscription = null;
      _lastCacheUpdate = null;
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<void> _scheduleExpiryNotifications(
    UserSubscription subscription,
  ) async {
    final notificationService = NotificationService();

    // Schedule notifications at different intervals before expiry
    final notifications = [
      {
        'days': 7,
        'title': 'Subscription Expiring Soon',
        'body':
            'Your subscription expires in 7 days. Renew now to continue listing.',
      },
      {
        'days': 3,
        'title': 'Subscription Expiring Soon',
        'body':
            'Your subscription expires in 3 days. Don\'t miss out on listings!',
      },
      {
        'days': 1,
        'title': 'Subscription Expires Tomorrow',
        'body':
            'Your subscription expires tomorrow. Renew now to avoid interruption.',
      },
    ];

    for (final notification in notifications) {
      final notificationDate = subscription.expiryDate.subtract(
        Duration(days: notification['days'] as int),
      );
      if (notificationDate.isAfter(DateTime.now())) {
        await notificationService.scheduleNotification(
          id: '${subscription.id}_${notification['days']}'.hashCode,
          title: notification['title'] as String,
          body: notification['body'] as String,
          scheduledDate: notificationDate,
        );
      }
    }
  }

  // Periodic cleanup of expired subscriptions
  Future<void> cleanupExpiredSubscriptions() async {
    try {
      final query =
          await _firestore
              .collection(_collection)
              .where('status', isEqualTo: 'active')
              .where('expiryDate', isLessThan: Timestamp.now())
              .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'status': 'expired',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error cleaning up expired subscriptions: $e');
    }
  }
}
