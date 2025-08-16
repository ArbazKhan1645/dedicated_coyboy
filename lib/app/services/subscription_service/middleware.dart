// middleware/listing_middleware.dart
import 'package:dedicated_cowboy/app/services/subscription_service/listing_guards.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/subcriptions_view.dart';
import 'package:flutter/material.dart';

class ListingMiddleware {
  static final ListingMiddleware _instance = ListingMiddleware._internal();
  factory ListingMiddleware() => _instance;
  ListingMiddleware._internal();

  final ListingGuardService _guardService = ListingGuardService();

  /// Middleware for event creation
  Future<bool> checkEventCreationPermission({
    required BuildContext context,
    required String userId,
    required VoidCallback onSuccess,
  }) async {
    return await _checkPermissionAndProceed(
      context: context,
      userId: userId,
      listingType: 'event',
      onSuccess: onSuccess,
    );
  }

  /// Middleware for business creation
  Future<bool> checkBusinessCreationPermission({
    required BuildContext context,
    required String userId,
    required VoidCallback onSuccess,
  }) async {
    return await _checkPermissionAndProceed(
      context: context,
      userId: userId,
      listingType: 'business',
      onSuccess: onSuccess,
    );
  }

  /// Middleware for item creation
  Future<bool> checkItemCreationPermission({
    required BuildContext context,
    required String userId,
    required VoidCallback onSuccess,
  }) async {
    return await _checkPermissionAndProceed(
      context: context,
      userId: userId,
      listingType: 'item',
      onSuccess: onSuccess,
    );
  }

  /// Generic permission check
  Future<bool> _checkPermissionAndProceed({
    required BuildContext context,
    required String userId,
    required String listingType,
    required VoidCallback onSuccess,
  }) async {
    try {
      final permission = await _guardService.checkListingPermission(userId);

      if (permission.canList) {
        // Show warning if subscription is expiring soon
        if (permission.isExpiringSoon) {
          _showExpiryWarningDialog(
            context: context,
            hoursRemaining: permission.hoursRemaining,
            planName: permission.planName ?? 'subscription',
            onProceed: onSuccess,
          );
        } else {
          onSuccess();
        }
        return true;
      } else {
        // Show subscription required dialog
        _showSubscriptionRequiredDialog(
          context: context,
          userId: userId,
          listingType: listingType,
        );
        return false;
      }
    } catch (e) {
      _showErrorDialog(context, 'Unable to verify subscription status: $e');
      return false;
    }
  }

  void _showSubscriptionRequiredDialog({
    required BuildContext context,
    required String userId,
    required String listingType,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.orange.shade600,
                  size: 40,
                ),
              ),
              const SizedBox(height: 25),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SubscriptionManagementScreen(
                              userId: userId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBB040),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'View Subscriptions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExpiryWarningDialog({
    required BuildContext context,
    required int hoursRemaining,
    required String planName,
    required VoidCallback onProceed,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_outlined,
                  color: Colors.orange.shade600,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Subscription Expiring Soon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your $planName subscription expires in $hoursRemaining hours. Consider renewing to avoid interruption.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onProceed();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBB040),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Continue Anyway',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Renew Subscription',
                        style: TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}