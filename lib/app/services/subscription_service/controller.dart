// providers/subscription_provider.dart
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
  final SubscriptionService _subscriptionService = SubscriptionService();
  final NotificationService _notificationService = NotificationService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // State management
  final Rx<SubscriptionState> _state = SubscriptionState.initial.obs;
  SubscriptionState get state => _state.value;

  UserSubscription? _currentSubscription;
  List<SubscriptionPlan> _availablePlans = [];
  final List<UserSubscription> _subscriptionHistory = [];
  String? _error;

  // Getters
  UserSubscription? get currentSubscription => _currentSubscription;
  List<SubscriptionPlan> get availablePlans => _availablePlans;
  List<UserSubscription> get subscriptionHistory => _subscriptionHistory;
  bool get isLoading =>
      _state.value == SubscriptionState.loading ||
      _state.value == SubscriptionState.purchasing;
  String? get error => _error;
  bool get hasActiveSubscription => _currentSubscription?.isActive == true;
  bool get canUserList => hasActiveSubscription;

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

  // Initialize provider with comprehensive error handling
  Future<void> initialize(String userId) async {
    try {
      _setState(SubscriptionState.loading);

      // Check internet connectivity
      final hasInternet = await _connectivityService.hasConnection();

      if (hasInternet) {
        await Future.wait([
          loadAvailablePlans(),
          loadCurrentSubscription(userId),
        ]);

        // Check for pending payment updates
        await _checkPendingPayments(userId);
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

  // Load available subscription plans with caching
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

  // Load current subscription with offline support
  Future<void> loadCurrentSubscription(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      final hasInternet = await _connectivityService.hasConnection();

      if (hasInternet || forceRefresh) {
        _currentSubscription = await _subscriptionService
            .getCurrentSubscription(userId, forceRefresh: forceRefresh);
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

  // Enhanced purchase subscription with robust error handling
  Future<PurchaseResult> purchaseSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required String stripePaymentIntentId,
    String? transactionId,
    Map<String, dynamic>? metadata,
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
          stripePaymentIntentId,
          transactionId,
          metadata,
        );
        return PurchaseResult(
          success: false,
          message:
              'No internet connection. Purchase will be processed when connection is restored.',
          isPending: true,
        );
      }

      // Verify payment with Stripe before creating subscription
      final paymentVerified = await _subscriptionService.verifyStripePayment(
        stripePaymentIntentId,
      );
      if (!paymentVerified) {
        _setError('Payment verification failed');
        _setState(SubscriptionState.error);
        return PurchaseResult(
          success: false,
          message: 'Payment verification failed',
        );
      }

      // Create subscription record
      final subscriptionResult = await _subscriptionService.createSubscription(
        userId: userId,
        plan: plan,
        stripePaymentIntentId: stripePaymentIntentId,
        transactionId: transactionId,
        metadata: metadata,
      );

      if (subscriptionResult.success) {
        // Update payment status for user's listings
        await _updateUserListingsPaymentStatus(userId);

        // Reload current subscription
        await loadCurrentSubscription(userId, forceRefresh: true);

        // Show success notification
        await _notificationService.showSubscriptionActivatedNotification(
          plan.name,
        );

        try {
          final authService = Get.find<AuthService>();
          final user = authService.currentUser;

          if (user != null) {
            await EmailTemplates.sendSubscriptionWelcomeEmail(
              recipientEmail: user.email,
              recipientName: user.displayName,
              orderId: plan.name,
              totalAmount: '\$${plan.price}',
              orderDetailsUrl: '',
            );
          }
        } catch (e) {
          print(e);
        }
        _setState(SubscriptionState.purchased);
        return PurchaseResult(
          success: true,
          message: 'Subscription activated successfully',
        );
      } else {
        _setError(
          subscriptionResult.message ?? 'Failed to activate subscription',
        );
        _setState(SubscriptionState.error);
        return PurchaseResult(
          success: false,
          message:
              subscriptionResult.message ?? 'Failed to activate subscription',
        );
      }
    } catch (e) {
      _setError('Error purchasing subscription: $e');
      _setState(SubscriptionState.error);

      // Save as pending if it might be a connectivity issue
      await _savePendingPurchase(
        userId,
        plan,
        stripePaymentIntentId,
        transactionId,
        metadata,
      );

      return PurchaseResult(
        success: false,
        message: 'Error processing purchase: $e',
        isPending: true,
      );
    }
  }

  // Update payment status for user's listings
  Future<void> _updateUserListingsPaymentStatus(String userId) async {
    try {
      await _subscriptionService.updateUserListingsPaymentStatus(userId);
    } catch (e) {
      print('Error updating listing payment status: $e');
      // Don't fail the subscription process for this
    }
  }

  // Cancel subscription with proper state management
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

      final success = await _subscriptionService.cancelSubscription(userId);

      if (success) {
        _currentSubscription = null;
        await _clearSubscriptionCache();
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

  // Check for pending payments and process them
  Future<void> _checkPendingPayments(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingPayments =
          prefs.getStringList('pending_payments_$userId') ?? [];

      for (final paymentData in pendingPayments) {
        final payment = jsonDecode(paymentData);
        final stripeIntentId = payment['stripePaymentIntentId'];

        // Verify if payment was actually processed
        final isProcessed = await _subscriptionService.verifyStripePayment(
          stripeIntentId,
        );
        if (isProcessed) {
          // Check if subscription already exists
          final existingSubscription = await _subscriptionService
              .getSubscriptionByStripeIntent(stripeIntentId);
          if (existingSubscription == null) {
            // Create the subscription that was missed
            final plan = SubscriptionPlan.fromMap(payment['plan']);
            await _subscriptionService.createSubscription(
              userId: userId,
              plan: plan,
              stripePaymentIntentId: stripeIntentId,
              transactionId: payment['transactionId'],
              metadata: Map<String, dynamic>.from(payment['metadata'] ?? {}),
            );

            // Update listing payment status
            await _updateUserListingsPaymentStatus(userId);
          }
        }
      }

      // Clear processed pending payments
      await prefs.remove('pending_payments_$userId');
    } catch (e) {
      print('Error checking pending payments: $e');
    }
  }

  // Save pending purchase for later processing
  Future<void> _savePendingPurchase(
    String userId,
    SubscriptionPlan plan,
    String stripePaymentIntentId,
    String? transactionId,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingPayments =
          prefs.getStringList('pending_payments_$userId') ?? [];

      final pendingPayment = {
        'userId': userId,
        'plan': plan.toMap(),
        'stripePaymentIntentId': stripePaymentIntentId,
        'transactionId': transactionId,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      };

      pendingPayments.add(jsonEncode(pendingPayment));
      await prefs.setStringList('pending_payments_$userId', pendingPayments);
    } catch (e) {
      print('Error saving pending purchase: $e');
    }
  }

  // Process any pending operations when connectivity is restored
  Future<void> _processPendingOperations() async {
    // This will be called when internet connection is restored
    // Re-check pending payments and process them
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');
      if (userId != null) {
        await _checkPendingPayments(userId);
        await loadCurrentSubscription(userId, forceRefresh: true);
      }
    } catch (e) {
      print('Error processing pending operations: $e');
    }
  }

  // Caching methods
  Future<void> _cachePlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plansJson = _availablePlans.map((plan) => plan.toMap()).toList();
      await prefs.setString('cached_plans', jsonEncode(plansJson));
    } catch (e) {
      print('Error caching plans: $e');
    }
  }

  Future<void> _loadPlansFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPlansString = prefs.getString('cached_plans');
      if (cachedPlansString != null) {
        final List<dynamic> plansJson = jsonDecode(cachedPlansString);
        _availablePlans =
            plansJson.map((json) => SubscriptionPlan.fromMap(json)).toList();
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
          jsonEncode(_currentSubscription!.toFirestore()),
        );
      }
    } catch (e) {
      print('Error caching subscription: $e');
    }
  }

  Future<void> _loadSubscriptionFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSubString = prefs.getString('cached_subscription');
      if (cachedSubString != null) {
        final subData = jsonDecode(cachedSubString);
        _currentSubscription = UserSubscription.fromFirestore(subData);
      }
    } catch (e) {
      print('Error loading subscription from cache: $e');
    }
  }

  Future<void> _clearSubscriptionCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_subscription');
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

  // Get subscription analytics
  int get daysRemaining => _currentSubscription?.daysRemaining ?? 0;
  int get hoursRemaining => _currentSubscription?.hoursRemaining ?? 0;
  bool get isExpiringSoon => daysRemaining <= 3 && daysRemaining > 0;
  SubscriptionType? get subscriptionType => _currentSubscription?.plan.type;

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

class SubscriptionResult {
  final bool success;
  final String? message;
  final UserSubscription? subscription;

  SubscriptionResult({required this.success, this.message, this.subscription});
}
