// services/wordpress_existing_subscription_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dedicated_cowboy/app/models/subscription/subscription_model.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:get/get.dart';

class WordPressExistingSubscriptionService {
  static final WordPressExistingSubscriptionService _instance =
      WordPressExistingSubscriptionService._internal();
  factory WordPressExistingSubscriptionService() => _instance;
  WordPressExistingSubscriptionService._internal();

  static const String baseUrl = 'https://dedicatedcowboy.com/wp-json';
  static const String plansEndpoint = '/wp/v2/atbdp_pricing_plans';
  static const String ordersEndpoint = '/wp/v2/atbdp_orders';
  static const String usersEndpoint = '/wp/v2/users';

  // Your existing WordPress credentials (you'll need to set these up)
  static const String wpUsername = '18XLegend';
  static const String wpPassword = 'O9px KmDk isTg PgaW wysH FqL6';

  // Get authorization headers for WordPress API
  Map<String, String> get _authHeaders {
    String basicAuth =
        'Basic ${base64Encode(utf8.encode('$wpUsername:$wpPassword'))}';
    return {'Authorization': basicAuth, 'Content-Type': 'application/json'};
  }

  // Get all available subscription plans from your existing WordPress setup
  Future<List<PricingPlan>> getSubscriptionPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$plansEndpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PricingPlan.fromJson(json)).toList();
      } else {
        print('Error fetching plans: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching subscription plans: $e');
      return [];
    }
  }

  // Get current user's active plan using your existing user meta system
  Future<PricingPlan?> getCurrentUserPlan() async {
    try {
      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) return null;

      // Get the plan ID from user meta as you're already doing
      final planId = currentUser.meta?['_plan_to_active'].toString();
      if (planId == null || planId.isEmpty) return null;

      // Fetch the specific plan
      final response = await http.get(
        Uri.parse('$baseUrl$plansEndpoint/$planId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PricingPlan.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error fetching current user plan: $e');
      return null;
    }
  }

  // Check if user has active subscription using your existing system
  Future<bool> hasActiveSubscription() async {
    try {
      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) return false;

      // Check user meta for active plan
      final planId = currentUser.meta?['_plan_to_active'].toString();
      final subscriptionStatus =
          currentUser.meta?['_subscription_status'].toString();
      final expiryDate = currentUser.meta?['_subscription_expiry'].toString();

      if (planId == null || planId.isEmpty) return false;
      if (subscriptionStatus != 'active') return false;

      // Check expiry date if it exists
      if (expiryDate != null && expiryDate.isNotEmpty) {
        final expiry = DateTime.parse(expiryDate);
        return DateTime.now().isBefore(expiry);
      }

      // If no expiry date, check if plan exists
      return planId.isNotEmpty;
    } catch (e) {
      print('Error checking active subscription: $e');
      return false;
    }
  }

  // Get subscription status details using your existing meta structure
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        return _getEmptyStatus();
      }

      final planId = currentUser.meta?['_plan_to_active'].toString();
      final subscriptionStatus =
          currentUser.meta?['_subscription_status'].toString();
      final expiryDate = currentUser.meta?['_subscription_expiry'].toString();
      final stripeCustomerId =
          currentUser.meta?['_stripe_customer_key'].toString();

      if (planId == null || planId.isEmpty) {
        return _getEmptyStatus();
      }

      // Get plan details
      final plan = await getCurrentUserPlan();
      final hasActive = await hasActiveSubscription();

      int daysRemaining = 0;
      DateTime? expiryDateTime;

      if (expiryDate != null && expiryDate.isNotEmpty) {
        try {
          expiryDateTime = DateTime.parse(expiryDate);
          daysRemaining = expiryDateTime.difference(DateTime.now()).inDays;
          if (daysRemaining < 0) daysRemaining = 0;
        } catch (e) {
          print('Error parsing expiry date: $e');
        }
      }

      return {
        'hasSubscription': true,
        'isActive': hasActive,
        'canList': hasActive,
        'plan':
            plan != null
                ? {
                  'id': plan.id,
                  'name': plan.title.rendered,
                  'price': plan.fmPrice,
                  'description': plan.fmDescription,
                }
                : null,
        'daysRemaining': daysRemaining,
        'expiryDate': expiryDateTime?.toIso8601String(),
        'subscriptionStatus': subscriptionStatus ?? 'inactive',
        'stripeCustomerId': stripeCustomerId ?? '',
      };
    } catch (e) {
      print('Error getting subscription status: $e');
      return _getEmptyStatus();
    }
  }

  Map<String, dynamic> _getEmptyStatus() {
    return {
      'hasSubscription': false,
      'isActive': false,
      'canList': false,
      'plan': null,
      'daysRemaining': 0,
      'expiryDate': null,
      'subscriptionStatus': 'inactive',
      'stripeCustomerId': '',
    };
  }

  // Get user's subscription history from your existing orders system
  Future<List<Map<String, dynamic>>> getSubscriptionHistory() async {
    try {
      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) return [];

      final userId = currentUser.id;

      // Fetch user's orders from your existing system
      final response = await http.get(
        Uri.parse('$baseUrl$ordersEndpoint?author=$userId&per_page=100'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> orders = jsonDecode(response.body);
        return orders.map((order) {
          final orderData = order as Map<String, dynamic>;
          return {
            'id': orderData['id'],
            'title': orderData['title']?['rendered'] ?? 'Subscription Order',
            'date': orderData['date'],
            'status':
                orderData['_payment_status'] ??
                orderData['status'] ??
                'unknown',
            'amount': orderData['_amount'] ?? '0',
            'plan_ordered': orderData['_fm_plan_ordered'] ?? '',
            'transaction_id': orderData['_transaction_id'] ?? '',
            'payment_gateway': orderData['_payment_gateway'] ?? '',
            'listing_id': orderData['_listing_id'] ?? '',
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching subscription history: $e');
      return [];
    }
  }

  // Create a new subscription order (for when processing payments)
  Future<SubscriptionResult> createSubscriptionOrder({
    required String planId,
    required String amount,
    required String transactionId,
    required String listingId,
  }) async {
    try {
      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        return SubscriptionResult(
          success: false,
          message: 'User not authenticated',
        );
      }

      final userId = currentUser.id;
      final plan = await _getPlanById(planId);

      if (plan == null) {
        return SubscriptionResult(success: false, message: 'Plan not found');
      }

      // Create order using your existing structure
      final response = await http.post(
        Uri.parse(
          'https://dedicatedcowboy.com/wp-json/cowboy/v1/create-atbdp-order',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.currentToken}',
        },
        body: jsonEncode({
          "status": "publish",

          "title": "Order for the listing ID #17538",
          "author": 247,

          "order_meta": {
            "plan_ordered": "14753",
            "listing_id": "175387",
            "amount": "5",
            "payment_gateway": "stripe_gateway",
            "payment_status": "completed",
            "transaction_id": "sub_1S5ptp059qvy9eXzzV2LhOkX",
            "order_status": "",
          },
          "_fm_plan_ordered": "14753",
          "_listing_id": "175387",
          "_amount": "5",
          "_payment_gateway": "stripe_gateway",
          "_payment_status": "completed",
          "_transaction_id": "sub_1S5ptp059qvy9eXzzV2LhOkX",
          "_order_status": "",
        }),
      );

      if (response.statusCode == 200) {
        // Update user meta with subscription details
        await _updateUserSubscription(userId.toString(), planId, transactionId);

        return SubscriptionResult(
          success: true,
          message: 'Subscription created successfully',
          data: {'order_id': jsonDecode(response.body)['id']},
        );
      } else {
        return SubscriptionResult(
          success: false,
          message: 'Failed to create subscription order: ${response.body}',
        );
      }
    } catch (e) {
      return SubscriptionResult(
        success: false,
        message: 'Error creating subscription: $e',
      );
    }
  }

  // Update user subscription meta data
  Future<void> _updateUserSubscription(
    String userId,
    String planId,
    String transactionId,
  ) async {
    try {
      final authService = Get.find<AuthService>();
      // Calculate expiry date (1 year from now by default)
      final expiryDate =
          DateTime.now().add(Duration(days: 365)).toIso8601String();

      final response = await http.post(
        Uri.parse('$baseUrl$usersEndpoint/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.currentToken}',
        },
        body: jsonEncode({
          'meta': {
            '_stripe_customer_key': "cus_SlRBgEoKxFFNE6",
            "wp_user_level": 0,
            'wp_capabilities': ['Subscriber'],
            '_plan_to_active': "14753",
            '_subscription_expiry': expiryDate,
            '_subscription_status': 'active',
            '_subscription_activated_at': DateTime.now().toIso8601String(),
            '_stripe_transaction_id': transactionId,
          },
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to update user subscription meta: ${response.body}');
      }
    } catch (e) {
      print('Error updating user subscription: $e');
    }
  }

  // Helper method to get plan by ID
  Future<PricingPlan?> _getPlanById(String planId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$plansEndpoint/$planId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PricingPlan.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching plan by ID: $e');
      return null;
    }
  }

  // Cancel subscription (update user meta)
  Future<bool> cancelSubscription() async {
    try {
      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) return false;

      final userId = currentUser.id.toString();

      final response = await http.post(
        Uri.parse('$baseUrl$usersEndpoint/$userId'),
        headers: _authHeaders,
        body: jsonEncode({
          'meta': {
            '_subscription_status': null,
            '_subscription_cancelled_at': null,
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }

  // Get user's Stripe customer ID from your existing meta
  String? getStripeCustomerId() {
    try {
      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) return null;

      return currentUser.meta?['_stripe_customer_key'].toString();
    } catch (e) {
      print('Error getting Stripe customer ID: $e');
      return null;
    }
  }

  // Check if user needs to renew subscription based on expiry
  Future<bool> needsRenewal() async {
    try {
      final status = await getSubscriptionStatus();
      final daysRemaining = status['daysRemaining'] as int;

      // Consider renewal needed if less than 7 days remaining
      return daysRemaining <= 7 && daysRemaining >= 0;
    } catch (e) {
      print('Error checking renewal status: $e');
      return false;
    }
  }

  // Refresh user data to get latest subscription info
  Future<void> refreshUserData() async {
    try {
      final authService = Get.find<AuthService>();
      await authService.refreshUser();
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }
}

// Result classes
class SubscriptionResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  SubscriptionResult({required this.success, required this.message, this.data});
}
