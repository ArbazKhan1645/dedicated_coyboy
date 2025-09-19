// screens/final_subscription_management_screen.dart
import 'package:dedicated_cowboy/app/models/subscription/subscription_model.dart';
import 'package:dedicated_cowboy/app/services/auth_service.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/controller.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinalSubscriptionManagementScreen extends StatefulWidget {
  final String userId;

  const FinalSubscriptionManagementScreen({super.key, required this.userId});

  @override
  State<FinalSubscriptionManagementScreen> createState() =>
      _FinalSubscriptionManagementScreenState();
}

class _FinalSubscriptionManagementScreenState
    extends State<FinalSubscriptionManagementScreen> {
  late SubscriptionProvider controller;
  late WordPressExistingSubscriptionService subscriptionService;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SubscriptionProvider());
    subscriptionService = WordPressExistingSubscriptionService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', widget.userId);
    await controller.initialize(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF5),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Subscriptions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final hasInternet = await controller.checkInternetConnection();
              if (!hasInternet) {
                _showNoInternetDialog();
                return;
              }
              controller.refreshstate(widget.userId);
            },
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      body: GetBuilder<SubscriptionProvider>(
        builder: (subscriptionProvider) {
          return _buildBody(subscriptionProvider);
        },
      ),
    );
  }

  Widget _buildBody(SubscriptionProvider provider) {
    switch (provider.state) {
      case SubscriptionState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFBB040)),
              SizedBox(height: 16),
              Text('Loading subscription data...'),
            ],
          ),
        );

      case SubscriptionState.error:
        return _buildErrorState(provider);

      case SubscriptionState.purchasing:
        return _buildPurchasingState();

      default:
        return _buildLoadedState(provider);
    }
  }

  Widget _buildErrorState(SubscriptionProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              provider.error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.refreshstate(widget.userId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2B342),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFF2B342)),
          SizedBox(height: 16),
          Text('Processing your subscription...'),
          SizedBox(height: 8),
          Text(
            'Please don\'t close the app',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(SubscriptionProvider provider) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildConnectionStatusIndicator(),

              // // Current Subscription Card (if active)
              // if (provider.hasActiveSubscription &&
              //     provider.currentSubscription != null)
              //   _buildCurrentSubscriptionCard(provider),

              // Available Plans
              ...provider.availablePlans.map(
                (plan) => _buildSubscriptionCard(
                  plan.title.rendered,
                  double.tryParse(plan.fmPrice) ?? 0.0,
                  "365 days",
                  plan.fmDescription,
                  _extractFeatures(plan),
                  isactive: provider.currentSubscription?.id == plan.id,
                  onContinuePressed:
                      () => _handleContinuePressed(plan, provider),
                  oncancel: () => _showCancelDialog(context, provider),
                  isLoading: provider.isLoading,
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _extractFeatures(PricingPlan plan) {
    List<String> features = [];

    if (plan.listingContent == 'true' || plan.listingContent == '1') {
      features.add('Create listings');
    }
    if (plan.pricing == 'true' || plan.pricing == '1') {
      features.add('Set custom pricing');
    }
    if (plan.location == 'true' || plan.location == '1') {
      features.add('Location support');
    }
    if (plan.category == 'true' || plan.category == '1') {
      features.add('Category management');
    }
    if (plan.phone == 'true' || plan.phone == '1') {
      features.add('Phone contact');
    }
    if (plan.email == 'true' || plan.email == '1') {
      features.add('Email contact');
    }

    if (features.isEmpty) {
      features = [
        'Unlimited listings',
        'Priority support',
        'Advanced features',
        'Analytics dashboard',
      ];
    }

    return features;
  }

  Widget _buildConnectionStatusIndicator() {
    return FutureBuilder<bool>(
      future: controller.checkInternetConnection(),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;
        if (isConnected) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Offline mode - Some features may be limited',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentSubscriptionCard(SubscriptionProvider provider) {
    final subscription = provider.currentSubscription!;
    final isExpiringSoon = provider.isExpiringSoon;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(
          color: isExpiringSoon ? Colors.orange : const Color(0xFF4A5568),
          width: 2,
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isExpiringSoon ? Colors.orange : const Color(0xFF10B981),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isExpiringSoon ? Icons.warning : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isExpiringSoon ? 'Expiring Soon' : 'Active Subscription',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  subscription.title.rendered,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Expires in ${provider.daysRemaining} days',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isExpiringSoon ? Colors.orange : Colors.grey.shade600,
                    fontWeight:
                        isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (provider.subscriptionStatus['expiryDate'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Expiry Date: ${_formatDate(DateTime.parse(provider.subscriptionStatus['expiryDate']))}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(
    String title,
    double price,
    String duration,
    String description,
    List<String> features, {
    VoidCallback? onContinuePressed,
    VoidCallback? oncancel,
    bool isLoading = false,
    bool isactive = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF4A5568),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'popins',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '£',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      price.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '/ $duration',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Per Package',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Column(
                  children:
                      features
                          .map((feature) => _buildFeatureItem(feature))
                          .toList(),
                ),
                const SizedBox(height: 24),
                if (!isactive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onContinuePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3B340),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                if (isactive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : oncancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Cancel Membership',
                                style: TextStyle(color: Colors.black),
                              ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            child: const Icon(Icons.check, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleContinuePressed(
    PricingPlan plan,
    SubscriptionProvider provider,
  ) async {
    final hasInternet = await controller.checkInternetConnection();
    if (!hasInternet) {
      _showNoInternetDialog();
      return;
    }

    await _processPayment(plan, provider);
  }

  Future<void> _processPayment(
    PricingPlan plan,
    SubscriptionProvider provider,
  ) async {
    try {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => WillPopScope(
              onWillPop: () async => false,
              child: const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFF2B342)),
                    SizedBox(height: 16),
                    Text('Initializing payment...'),
                    SizedBox(height: 8),
                    Text(
                      'Please wait',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
      );

      final authService = Get.find<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        if (mounted) {
          Navigator.of(context).pop();
          _showErrorDialog('Authentication Error', 'User not authenticated');
        }
        return;
      }

      // Simulate payment processing - replace with actual Stripe integration
      await Future.delayed(Duration(seconds: 2));

      final mockTransactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
      final mockListingId = '${DateTime.now().millisecondsSinceEpoch}';

      if (mounted) {
        Navigator.of(context).pop();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFF2B342)),
                    SizedBox(height: 16),
                    Text('Activating subscription...'),
                  ],
                ),
              ),
        );
      }

      final subscriptionResult = await provider.purchaseSubscription(
        userId: widget.userId,
        plan: plan,
        stripeTransactionId: mockTransactionId,
        listingId: mockListingId,
        metadata: 'Flutter app purchase',
      );

      if (mounted) {
        Navigator.of(context).pop();

        if (subscriptionResult.success) {
          _showSuccessDialog(plan.title.rendered);
        } else {
          _showErrorDialog('Subscription Error', subscriptionResult.message);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(
          'Unexpected Error',
          'An unexpected error occurred: $e',
        );
      }
    }
  }

  void _showSuccessDialog(String planName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Subscription Activated!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your $planName subscription is now active. You can start creating listings!',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2B342),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Great!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String title, String? message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message ?? 'An error occurred'),
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

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('No Internet Connection'),
            ],
          ),
          content: const Text(
            'An internet connection is required to process payments. Please check your connection and try again.',
          ),
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

  void _showCancelDialog(BuildContext context, SubscriptionProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(10),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1D5DB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFFEF4444),
                  size: 40,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Are You Sure You Want To',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              const Text(
                'Cancel Membership',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                'This action will cancel your current subscription\nand remove associated benefits',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      Navigator.of(context).pop();

                      final hasInternet =
                          await controller.checkInternetConnection();
                      if (!hasInternet) {
                        _showNoInternetDialog();
                        return;
                      }

                      final success = await provider.cancelSubscription(
                        widget.userId,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Subscription cancelled successfully'
                                  : 'Failed to cancel subscription: ${provider.error}',
                            ),
                            backgroundColor:
                                success ? const Color(0xFFF2B342) : Colors.red,
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: const Color(0xFFFBC65F),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            offset: Offset(0, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Yes, Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9FAFB),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Keep Subscription',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
