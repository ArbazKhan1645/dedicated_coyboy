// services/listing_guard_service.dart
import 'package:dedicated_cowboy/app/models/subscription/subscription_model.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/notifications.dart';
import 'subscription_service.dart';


class ListingGuardService {
  static final ListingGuardService _instance = ListingGuardService._internal();
  factory ListingGuardService() => _instance;
  ListingGuardService._internal();

  final SubscriptionService _subscriptionService = SubscriptionService();
  final NotificationService _notificationService = NotificationService();

  /// Check if user can create a listing before proceeding with listing creation
  Future<ListingPermissionResult> checkListingPermission(String userId) async {
    try {
      final hasActiveSubscription = await _subscriptionService.hasActiveSubscription(userId);
      
      if (!hasActiveSubscription) {
        // Show notification about blocked listing
        await _notificationService.showListingBlockedNotification();
        
        return ListingPermissionResult(
          canList: false,
          reason: 'No active subscription found',
          requiresSubscription: true,
        );
      }

      final subscription = await _subscriptionService.getCurrentSubscription(userId);
      if (subscription == null) {
        return ListingPermissionResult(
          canList: false,
          reason: 'Unable to verify subscription',
          requiresSubscription: true,
        );
      }

      // Check if subscription is about to expire (within 24 hours)
      if (subscription.hoursRemaining <= 24 && subscription.hoursRemaining > 0) {
        return ListingPermissionResult(
          canList: true,
          reason: 'Subscription expires soon',
          isExpiringSoon: true,
          hoursRemaining: subscription.hoursRemaining,
          planName: subscription.plan.name,
        );
      }

      return ListingPermissionResult(
        canList: true,
        reason: 'Active subscription found',
        planName: subscription.plan.name,
        daysRemaining: subscription.daysRemaining,
      );

    } catch (e) {
      print('Error checking listing permission: $e');
      return ListingPermissionResult(
        canList: false,
        reason: 'Error verifying subscription: $e',
        requiresSubscription: true,
      );
    }
  }

  /// Get user's current listing capabilities
  Future<ListingCapabilities> getListingCapabilities(String userId) async {
    final subscription = await _subscriptionService.getCurrentSubscription(userId);
    
    if (subscription == null) {
      return ListingCapabilities(
        canCreateEvents: false,
        canCreateBusinesses: false,
        canCreateItems: false,
        maxListingsPerDay: 0,
        features: [],
      );
    }

    // Define capabilities based on subscription plan
    switch (subscription.plan.type) {
      case SubscriptionType.daily:
        return ListingCapabilities(
          canCreateEvents: true,
          canCreateBusinesses: true,
          canCreateItems: true,
          maxListingsPerDay: 3,
          features: subscription.plan.features,
        );
      case SubscriptionType.monthly:
        return ListingCapabilities(
          canCreateEvents: true,
          canCreateBusinesses: true,
          canCreateItems: true,
          maxListingsPerDay: 10,
          features: subscription.plan.features,
        );
      case SubscriptionType.yearly:
        return ListingCapabilities(
          canCreateEvents: true,
          canCreateBusinesses: true,
          canCreateItems: true,
          maxListingsPerDay: -1, // unlimited
          features: subscription.plan.features,
        );
    }
  }

  /// Show subscription requirement dialog
  Future<void> showSubscriptionRequiredDialog(Function() onSubscribePressed) async {
    // This would typically show a dialog in your UI
    // For now, we'll just print the message
    print('Subscription required to create listings');
    // You can implement this in your UI layer
  }

  /// Middleware function to wrap listing creation
  Future<T?> guardedListingAction<T>({
    required String userId,
    required Future<T> Function() listingAction,
    required Function() onSubscriptionRequired,
  }) async {
    final permission = await checkListingPermission(userId);
    
    if (!permission.canList) {
      onSubscriptionRequired();
      return null;
    }

    // Show warning if subscription is expiring soon
    if (permission.isExpiringSoon) {
      await _notificationService.showImmediateNotification(
        id: 996,
        title: 'Subscription Expiring Soon',
        body: 'Your ${permission.planName} subscription expires in ${permission.hoursRemaining} hours.',
      );
    }

    return await listingAction();
  }
}

class ListingPermissionResult {
  final bool canList;
  final String reason;
  final bool requiresSubscription;
  final bool isExpiringSoon;
  final int hoursRemaining;
  final int daysRemaining;
  final String? planName;

  ListingPermissionResult({
    required this.canList,
    required this.reason,
    this.requiresSubscription = false,
    this.isExpiringSoon = false,
    this.hoursRemaining = 0,
    this.daysRemaining = 0,
    this.planName,
  });
}

class ListingCapabilities {
  final bool canCreateEvents;
  final bool canCreateBusinesses;
  final bool canCreateItems;
  final int maxListingsPerDay; // -1 for unlimited
  final List<String> features;

  ListingCapabilities({
    required this.canCreateEvents,
    required this.canCreateBusinesses,
    required this.canCreateItems,
    required this.maxListingsPerDay,
    required this.features,
  });

  bool get hasUnlimitedListings => maxListingsPerDay == -1;
}