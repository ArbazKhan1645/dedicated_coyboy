// providers/existing_subscription_provider.dart
import 'package:dedicated_cowboy/app/models/subscription/subscription_model.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/connectivity.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/notifications.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/subscription_service.dart';

import 'package:dedicated_cowboy/views/mails/mail_structure.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum SubscriptionState {
  initial,
  loading,
  loaded,
  error,
  purchasing,
  purchased,
  cancelled,
}

class SubscriptionProvider extends GetxController {
  final WordPressExistingSubscriptionService _subscriptionService =
      WordPressExistingSubscriptionService();
  final NotificationService _notificationService = NotificationService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // State management
  final Rx<SubscriptionState> _state = SubscriptionState.initial.obs;
  SubscriptionState get state => _state.value;

  List<PricingPlan> _availablePlans = [];
  PricingPlan? _currentSubscription;
  Map<String, dynamic> _subscriptionStatus = {};

  String? _error;

  // Getters
  List<PricingPlan> get availablePlans => _availablePlans;
  PricingPlan? get currentSubscription => _currentSubscription;
  Map<String, dynamic> get subscriptionStatus => _subscriptionStatus;

  bool get isLoading =>
      _state.value == SubscriptionState.loading ||
      _state.value == SubscriptionState.purchasing;

  String? get error => _error;

  bool get hasActiveSubscription => _subscriptionStatus['isActive'] == true;
  bool get canUserList => _subscriptionStatus['canList'] == true;
  int get daysRemaining => _subscriptionStatus['daysRemaining'] ?? 0;
  bool get isExpiringSoon => daysRemaining <= 7 && daysRemaining > 0;
  String? get stripeCustomerId => _subscriptionStatus['stripeCustomerId'];

  @override
  void onInit() {
    super.onInit();
    _initializeConnectivityListener();
  }

  void _initializeConnectivityListener() {
    _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        _processPendingOperations();
      }
    });
  }

  // Initialize provider using your existing WordPress system
  Future<void> initialize(String userId) async {
    try {
      _setState(SubscriptionState.loading);

      // Check internet connectivity
      final hasInternet = await _connectivityService.hasConnection();

      if (hasInternet) {
        await Future.wait([
          loadAvailablePlans(),
          loadCurrentSubscription(userId),
          loadSubscriptionStatus(),
        ]);
      } else {
        // Load from cache when offline
        await _loadFromCache();
      }

      _setState(SubscriptionState.loaded);
    } catch (e) {
      _setError('Failed to initialize: $e');
      _setState(SubscriptionState.error);
    }
  }

  // Load available subscription plans from WordPress
  Future<void> loadAvailablePlans() async {
    try {
      final hasInternet = await _connectivityService.hasConnection();

      if (hasInternet) {
        _availablePlans = await _subscriptionService.getSubscriptionPlans();
        await _cachePlans();
      } else {
        await _loadPlansFromCache();
      }

      _clearError();
    } catch (e) {
      _setError('Failed to load subscription plans: $e');
      await _loadPlansFromCache(); // Fallback to cache
    }
  }

  // Load current subscription from WordPress
  Future<void> loadCurrentSubscription(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      final hasInternet = await _connectivityService.hasConnection();

      if (hasInternet || forceRefresh) {
        // First refresh user data to get latest meta
        await _subscriptionService.refreshUserData();
        _currentSubscription = await _subscriptionService.getCurrentUserPlan();
        await _cacheSubscription();
      } else {
        await _loadSubscriptionFromCache();
      }

      _clearError();
    } catch (e) {
      _setError('Failed to load current subscription: $e');
      await _loadSubscriptionFromCache(); // Fallback to cache
    }
  }

  // Load subscription status from WordPress user meta
  Future<void> loadSubscriptionStatus() async {
    try {
      _subscriptionStatus = await _subscriptionService.getSubscriptionStatus();
    } catch (e) {
      _setError('Failed to load subscription status: $e');
    }
  }

  // Process Stripe payment using your existing system
  Future<PurchaseResult> purchaseSubscription({
    required String userId,
    required PricingPlan plan,
    required String stripeTransactionId,
    String? listingId,
    String? metadata,
  }) async {
    try {
      _setState(SubscriptionState.purchasing);
      _clearError();

      // Check internet connectivity
      final hasInternet = await _connectivityService.hasConnection();
      if (!hasInternet) {
        // Save pending purchase for later processing
        await _savePendingPurchase(
          userId,
          plan,
          stripeTransactionId,
          listingId,
          metadata,
        );
        return PurchaseResult(
          success: false,
          message:
              'No internet connection. Purchase will be processed when connection is restored.',
          isPending: true,
        );
      }

      // Create subscription order in your existing WordPress system
      final subscriptionResult = await _subscriptionService
          .createSubscriptionOrder(
            planId: plan.id.toString(),
            amount: plan.fmPrice,
            transactionId: stripeTransactionId,
            listingId:
                listingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          );

      if (subscriptionResult.success) {
        // Reload current subscription and status
        await loadCurrentSubscription(userId, forceRefresh: true);
        await loadSubscriptionStatus();

        // Show success notification
        await _notificationService.showSubscriptionActivatedNotification(
          plan.title.rendered,
        );

        // Send welcome email
        try {
          final authService = Get.find<AuthService>();
          final currentUser = authService.currentUser;

          if (currentUser != null) {
            await EmailTemplates.sendSubscriptionWelcomeEmail(
              recipientEmail: currentUser.email ?? '',
              recipientName: currentUser.displayName ?? 'User',
              orderId: stripeTransactionId,
              totalAmount: '£${plan.fmPrice}',
              orderDetailsUrl: '',
            );
          }
        } catch (e) {
          print('Error sending welcome email: $e');
        }

        _setState(SubscriptionState.purchased);
        return PurchaseResult(
          success: true,
          message: 'Subscription activated successfully',
          subscriptionId: plan.id.toString(),
        );
      } else {
        _setError(subscriptionResult.message);
        _setState(SubscriptionState.error);
        return PurchaseResult(
          success: false,
          message: subscriptionResult.message,
        );
      }
    } catch (e) {
      _setError('Error purchasing subscription: $e');
      _setState(SubscriptionState.error);

      // Save as pending if it might be a connectivity issue
      await _savePendingPurchase(
        userId,
        plan,
        stripeTransactionId,
        listingId,
        metadata,
      );

      return PurchaseResult(
        success: false,
        message: 'Error processing purchase: $e',
        isPending: true,
      );
    }
  }

  // Cancel subscription using your existing system
  Future<bool> cancelSubscription(String userId) async {
    try {
      _setState(SubscriptionState.loading);
      _clearError();

      final hasInternet = await _connectivityService.hasConnection();
      if (!hasInternet) {
        _setError('No internet connection');
        _setState(SubscriptionState.error);
        return false;
      }

      final success = await _subscriptionService.cancelSubscription();

      if (success) {
        await _clearSubscriptionCache();
        await loadCurrentSubscription(userId, forceRefresh: true);
        await loadSubscriptionStatus();
        _setState(SubscriptionState.cancelled);
        return true;
      } else {
        _setError('Failed to cancel subscription');
        _setState(SubscriptionState.error);
        return false;
      }
    } catch (e) {
      _setError('Error cancelling subscription: $e');
      _setState(SubscriptionState.error);
      return false;
    }
  }

  // Get subscription history from your existing orders
  Future<List<Map<String, dynamic>>> getSubscriptionHistory() async {
    try {
      return await _subscriptionService.getSubscriptionHistory();
    } catch (e) {
      print('Error getting subscription history: $e');
      return [];
    }
  }

  // Check if user needs to renew subscription
  Future<bool> needsRenewal() async {
    try {
      return await _subscriptionService.needsRenewal();
    } catch (e) {
      print('Error checking renewal status: $e');
      return false;
    }
  }

  // Save pending purchase for later processing
  Future<void> _savePendingPurchase(
    String userId,
    PricingPlan plan,
    String transactionId,
    String? listingId,
    String? metadata,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingPayments =
          prefs.getStringList('pending_payments_$userId') ?? [];

      final pendingPayment = {
        'userId': userId,
        'planId': plan.id.toString(),
        'planData': plan.toJson(),
        'transactionId': transactionId,
        'listingId': listingId,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      };

      pendingPayments.add(jsonEncode(pendingPayment));
      await prefs.setStringList('pending_payments_$userId', pendingPayments);
    } catch (e) {
      print('Error saving pending purchase: $e');
    }
  }

  // Process pending operations when connectivity is restored
  Future<void> _processPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        final userId = currentUser.id.toString();
        final pendingPayments =
            prefs.getStringList('pending_payments_$userId') ?? [];

        for (final paymentData in pendingPayments) {
          final payment = jsonDecode(paymentData);

          try {
            final result = await _subscriptionService.createSubscriptionOrder(
              planId: payment['planId'],
              amount: payment['planData']['fmPrice'],
              transactionId: payment['transactionId'],
              listingId:
                  payment['listingId'] ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
            );

            if (result.success) {
              print(
                'Successfully processed pending payment: ${payment['transactionId']}',
              );
            }
          } catch (e) {
            print('Error processing pending payment: $e');
          }
        }

        // Clear processed pending payments
        await prefs.remove('pending_payments_$userId');

        // Refresh subscription data
        await loadCurrentSubscription(userId, forceRefresh: true);
        await loadSubscriptionStatus();
      }
    } catch (e) {
      print('Error processing pending operations: $e');
    }
  }

  // Caching methods
  Future<void> _cachePlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plansJson = _availablePlans.map((plan) => plan.toJson()).toList();
      await prefs.setString('cached_plans', jsonEncode(plansJson));
      await prefs.setString(
        'plans_cache_time',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error caching plans: $e');
    }
  }

  Future<void> _loadPlansFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPlansString = prefs.getString('cached_plans');
      final cacheTimeString = prefs.getString('plans_cache_time');

      if (cachedPlansString != null && cacheTimeString != null) {
        final cacheTime = DateTime.parse(cacheTimeString);
        final cacheAge = DateTime.now().difference(cacheTime);

        // Use cache if it's less than 1 hour old
        if (cacheAge.inHours < 1) {
          final List<dynamic> plansJson = jsonDecode(cachedPlansString);
          _availablePlans =
              plansJson.map((json) => PricingPlan.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('Error loading plans from cache: $e');
    }
  }

  Future<void> _cacheSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentSubscription != null) {
        await prefs.setString(
          'cached_subscription',
          jsonEncode(_currentSubscription!.toJson()),
        );
        await prefs.setString(
          'subscription_cache_time',
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('Error caching subscription: $e');
    }
  }

  Future<void> _loadSubscriptionFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSubscriptionString = prefs.getString('cached_subscription');
      final cacheTimeString = prefs.getString('subscription_cache_time');

      if (cachedSubscriptionString != null && cacheTimeString != null) {
        final cacheTime = DateTime.parse(cacheTimeString);
        final cacheAge = DateTime.now().difference(cacheTime);

        // Use cache if it's less than 30 minutes old
        if (cacheAge.inMinutes < 30) {
          final subscriptionJson = jsonDecode(cachedSubscriptionString);
          _currentSubscription = PricingPlan.fromJson(subscriptionJson);
        }
      }
    } catch (e) {
      print('Error loading subscription from cache: $e');
    }
  }

  Future<void> _clearSubscriptionCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_subscription');
      await prefs.remove('subscription_cache_time');
      _currentSubscription = null;
    } catch (e) {
      print('Error clearing subscription cache: $e');
    }
  }

  Future<void> _loadFromCache() async {
    await Future.wait([_loadPlansFromCache(), _loadSubscriptionFromCache()]);
  }

  // State management helpers
  void _setState(SubscriptionState newState) {
    _state.value = newState;
    update();
  }

  void _setError(String error) {
    _error = error;
    update();
  }

  void _clearError() {
    _error = null;
    update();
  }

  // Refresh all data
  Future<void> refreshstate(String userId) async {
    await initialize(userId);
  }

  // Check internet before operations
  Future<bool> checkInternetConnection() async {
    return await _connectivityService.hasConnection();
  }
}

// Result classes for better error handling
class PurchaseResult {
  final bool success;
  final String message;
  final bool isPending;
  final String? subscriptionId;

  PurchaseResult({
    required this.success,
    required this.message,
    this.isPending = false,
    this.subscriptionId,
  });
}
