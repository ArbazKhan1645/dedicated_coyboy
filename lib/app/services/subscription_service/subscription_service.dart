// services/subscription_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/models/subscription/subscription_model.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/controller.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'user_subscriptions';
  final String _plansCollection = 'subscription_plans';
  final String _paymentsCollection = 'payment_records';
  
  UserSubscription? _cachedSubscription;
  DateTime? _lastCacheUpdate;
  static const int _cacheValidityMinutes = 5;
  
  // Stripe configuration
  static const String _stripeSecretKey = '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';

  // Initialize subscription plans in Firestore
  Future<void> initializeSubscriptionPlans() async {
    try {
      final snapshot = await _firestore.collection(_plansCollection).limit(1).get();

      if (snapshot.docs.isEmpty) {
        final plans = SubscriptionPlan.getDefaultPlans();
        final batch = _firestore.batch();

        for (final plan in plans) {
          final docRef = _firestore.collection(_plansCollection).doc(plan.id);
          batch.set(docRef, plan.toMap());
        }

        await batch.commit();
        print('Subscription plans initialized successfully');
      } else {
        print('Subscription plans already exist. Skipping initialization.');
      }
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

  // Verify Stripe payment before creating subscription
  Future<bool> verifyStripePayment(String paymentIntentId) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];
        return status == 'succeeded';
      } else {
        print('Error verifying payment: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error verifying Stripe payment: $e');
      return false;
    }
  }

  // Create a new subscription with enhanced tracking
  Future<SubscriptionResult> createSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required String stripePaymentIntentId,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if subscription with this Stripe intent already exists
      final existingSubscription = await getSubscriptionByStripeIntent(stripePaymentIntentId);
      if (existingSubscription != null) {
        return SubscriptionResult(
          success: true,
          message: 'Subscription already exists for this payment',
          subscription: existingSubscription,
        );
      }

      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: plan.duration));
      final subscriptionId = _firestore.collection(_collection).doc().id;
      
      final subscription = UserSubscription(
        id: subscriptionId,
        userId: userId,
        plan: plan,
        purchaseDate: now,
        expiryDate: expiryDate,
        status: SubscriptionStatus.active,
        transactionId: transactionId,
        metadata: metadata ?? {},
      );

      // Create payment record for tracking
      final paymentRecord = PaymentRecord(
        id: _firestore.collection(_paymentsCollection).doc().id,
        userId: userId,
        subscriptionId: subscriptionId,
        stripePaymentIntentId: stripePaymentIntentId,
        amount: plan.price,
        currency: 'GBP',
        status: 'completed',
        createdAt: now,
        metadata: metadata ?? {},
      );

      // Use batch to ensure atomicity
      final batch = _firestore.batch();

      // Cancel any existing active subscriptions first
      await _cancelExistingSubscriptions(userId, batch);

      // Add new subscription
      batch.set(
        _firestore.collection(_collection).doc(subscriptionId),
        subscription.toFirestore(),
      );

      // Add payment record
      batch.set(
        _firestore.collection(_paymentsCollection).doc(paymentRecord.id),
        paymentRecord.toMap(),
      );

      await batch.commit();

      // Update cache
      _cachedSubscription = subscription;
      _lastCacheUpdate = DateTime.now();
      await _saveCacheToLocal();

      // Schedule notifications
      await _scheduleExpiryNotifications(subscription);

      return SubscriptionResult(
        success: true,
        message: 'Subscription created successfully',
        subscription: subscription,
      );
    } catch (e) {
      print('Error creating subscription: $e');
      return SubscriptionResult(
        success: false,
        message: 'Error creating subscription: $e',
      );
    }
  }

  // Get subscription by Stripe payment intent
  Future<UserSubscription?> getSubscriptionByStripeIntent(String stripeIntentId) async {
    try {
      final paymentQuery = await _firestore
          .collection(_paymentsCollection)
          .where('stripePaymentIntentId', isEqualTo: stripeIntentId)
          .limit(1)
          .get();

      if (paymentQuery.docs.isEmpty) return null;

      final paymentRecord = paymentQuery.docs.first.data();
      final subscriptionId = paymentRecord['subscriptionId'];

      final subscriptionDoc = await _firestore
          .collection(_collection)
          .doc(subscriptionId)
          .get();

      if (!subscriptionDoc.exists) return null;

      return UserSubscription.fromFirestore(subscriptionDoc);
    } catch (e) {
      print('Error getting subscription by Stripe intent: $e');
      return null;
    }
  }

  // Update payment status for user's listings
  Future<void> updateUserListingsPaymentStatus(String userId) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Collections to update
      final collections = ['events', 'businesses', 'items'];

      for (final collectionName in collections) {
        final query = await _firestore
            .collection(collectionName)
            .where('userId', isEqualTo: userId)
            .where('paymentStatus', isEqualTo: 'pending')
            .where('createdAt', isLessThan: Timestamp.fromDate(now))
            .get();

        for (final doc in query.docs) {
          batch.update(doc.reference, {
            'paymentStatus': 'paid',
            'paymentUpdatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      print('Updated payment status for user listings: $userId');
    } catch (e) {
      print('Error updating user listings payment status: $e');
      rethrow;
    }
  }

  // Check and update payment status on app initialization
  Future<void> initializeAndUpdatePaymentStatus(String userId) async {
    try {
      // Check if user has active subscription
      final hasActiveSubscription = await this.hasActiveSubscription(userId);
      
      if (hasActiveSubscription) {
        // Update payment status for all pending listings
        await updateUserListingsPaymentStatus(userId);
      }

      // Check for any missed payments that were completed in Stripe
      await _checkMissedPayments(userId);
    } catch (e) {
      print('Error initializing payment status: $e');
    }
  }

  // Check for missed payments in Stripe
  Future<void> _checkMissedPayments(String userId) async {
    try {
      // Get all payment records for this user
      final paymentQuery = await _firestore
          .collection(_paymentsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10) // Check last 10 payments
          .get();

      for (final paymentDoc in paymentQuery.docs) {
        final paymentData = paymentDoc.data();
        final stripeIntentId = paymentData['stripePaymentIntentId'];
        final localStatus = paymentData['status'];

        // If local status is not completed, verify with Stripe
        if (localStatus != 'completed') {
          final isVerified = await verifyStripePayment(stripeIntentId);
          if (isVerified) {
            // Update local payment record
            await _firestore.collection(_paymentsCollection).doc(paymentDoc.id).update({
              'status': 'completed',
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // Check if subscription exists, if not create it
            final subscription = await getSubscriptionByStripeIntent(stripeIntentId);
            if (subscription == null) {
              // Recreation logic would go here if needed
              print('Found verified payment without subscription: $stripeIntentId');
            }
          }
        }
      }
    } catch (e) {
      print('Error checking missed payments: $e');
    }
  }

  // Get user's current active subscription with enhanced caching
  Future<UserSubscription?> getCurrentSubscription(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh && _isCacheValid() && _cachedSubscription?.userId == userId) {
        return _cachedSubscription;
      }

      final query = await _firestore
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
      final query = await _firestore
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
  Future<void> _cancelExistingSubscriptions(String userId, [WriteBatch? batch]) async {
    final query = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();

    final batchToUse = batch ?? _firestore.batch();
    for (final doc in query.docs) {
      batchToUse.update(doc.reference, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    if (batch == null) {
      await batchToUse.commit();
    }
  }

  Future<void> _expireSubscription(String subscriptionId) async {
    await _firestore.collection(_collection).doc(subscriptionId).update({
      'status': 'expired',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!).inMinutes < _cacheValidityMinutes;
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

  Future<void> _scheduleExpiryNotifications(UserSubscription subscription) async {
    final notificationService = NotificationService();

    final notifications = [
      {
        'days': 7,
        'title': 'Subscription Expiring Soon',
        'body': 'Your subscription expires in 7 days. Renew now to continue listing.',
      },
      {
        'days': 3,
        'title': 'Subscription Expiring Soon',
        'body': 'Your subscription expires in 3 days. Don\'t miss out on listings!',
      },
      {
        'days': 1,
        'title': 'Subscription Expires Tomorrow',
        'body': 'Your subscription expires tomorrow. Renew now to avoid interruption.',
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
      final query = await _firestore
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

// Payment Record Model for tracking
class PaymentRecord {
  final String id;
  final String userId;
  final String subscriptionId;
  final String stripePaymentIntentId;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  PaymentRecord({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.stripePaymentIntentId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subscriptionId': subscriptionId,
      'stripePaymentIntentId': stripePaymentIntentId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      subscriptionId: map['subscriptionId'] ?? '',
      stripePaymentIntentId: map['stripePaymentIntentId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'GBP',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}