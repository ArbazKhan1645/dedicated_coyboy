// providers/subscription_provider.dart
import 'package:dedicated_cowboy/app/models/subscription/subscription_model.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/notifications.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/subscription_service.dart';
import 'package:get/get.dart';

class SubscriptionProvider extends GetxController {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final NotificationService _notificationService = NotificationService();

  UserSubscription? _currentSubscription;
  List<SubscriptionPlan> _availablePlans = [];
  List<UserSubscription> _subscriptionHistory = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  UserSubscription? get currentSubscription => _currentSubscription;
  List<SubscriptionPlan> get availablePlans => _availablePlans;
  List<UserSubscription> get subscriptionHistory => _subscriptionHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSubscription => _currentSubscription?.isActive == true;
  bool get canUserList => hasActiveSubscription;

  // Initialize provider
  Future<void> initialize(String userId) async {
    await loadAvailablePlans();
    await loadCurrentSubscription(userId);
  }

  // Load available subscription plans
  Future<void> loadAvailablePlans() async {
    try {
      _setLoading(true);
      _availablePlans = await _subscriptionService.getSubscriptionPlans();
      _clearError();
    } catch (e) {
      _setError('Failed to load subscription plans: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load current subscription
  Future<void> loadCurrentSubscription(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      _setLoading(true);
      _currentSubscription = await _subscriptionService.getCurrentSubscription(
        userId,
        forceRefresh: forceRefresh,
      );
      _clearError();
    } catch (e) {
      _setError('Failed to load current subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load subscription history
  Future<void> loadSubscriptionHistory(String userId) async {
    try {
      _setLoading(true);
      _subscriptionHistory = await _subscriptionService.getSubscriptionHistory(
        userId,
      );
      _clearError();
    } catch (e) {
      _setError('Failed to load subscription history: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Purchase subscription
  Future<bool> purchaseSubscription({
    required String userId,
    required SubscriptionPlan plan,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _subscriptionService.createSubscription(
        userId: userId,
        plan: plan,
        transactionId: transactionId,
        metadata: metadata,
      );

      if (success) {
        // Reload current subscription
        await loadCurrentSubscription(userId, forceRefresh: true);

        // Show success notification
        await _notificationService.showSubscriptionActivatedNotification(
          plan.name,
        );

        return true;
      } else {
        _setError('Failed to activate subscription');
        return false;
      }
    } catch (e) {
      _setError('Error purchasing subscription: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _subscriptionService.cancelSubscription(userId);

      if (success) {
        _currentSubscription = null;
        update();
        return true;
      } else {
        _setError('Failed to cancel subscription');
        return false;
      }
    } catch (e) {
      _setError('Error cancelling subscription: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get subscription status
  Future<Map<String, dynamic>> getSubscriptionStatus(String userId) async {
    return await _subscriptionService.getSubscriptionStatus(userId);
  }

  // Check if user can create listings
  Future<bool> checkListingPermission(String userId) async {
    return await _subscriptionService.canUserList(userId);
  }

  // Get days remaining
  int get daysRemaining => _currentSubscription?.daysRemaining ?? 0;

  // Get hours remaining
  int get hoursRemaining => _currentSubscription?.hoursRemaining ?? 0;

  // Check if subscription is expiring soon (within 3 days)
  bool get isExpiringSoon => daysRemaining <= 3 && daysRemaining > 0;

  // Get subscription type
  SubscriptionType? get subscriptionType => _currentSubscription?.plan.type;

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
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
    await Future.wait([
      loadAvailablePlans(),
      loadCurrentSubscription(userId, forceRefresh: true),
      loadSubscriptionHistory(userId),
    ]);
  }
}
