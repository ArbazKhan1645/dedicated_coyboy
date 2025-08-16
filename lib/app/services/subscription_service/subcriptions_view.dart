// screens/subscription_management_screen.dart
import 'package:dedicated_cowboy/app/models/subscription/subscription_model.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  final String userId;

  const SubscriptionManagementScreen({super.key, required this.userId});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  var controller = Get.put(SubscriptionProvider());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialize(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF5),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Subscription Management',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
           controller.refreshstate(widget.userId);
            },
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_vert, color: Colors.black),
          ),
        ],
      ),
      body: GetBuilder<SubscriptionProvider>(
        init: SubscriptionProvider(),
        builder: (subscriptionProvider) {
          if (subscriptionProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFBB040)),
            );
          }

          if (subscriptionProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${subscriptionProvider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      subscriptionProvider.refreshstate(widget.userId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Current Subscription Status
                    if (subscriptionProvider.hasActiveSubscription)
                      _buildCurrentSubscriptionCard(subscriptionProvider),

                    // Available Plans
                    ...subscriptionProvider.availablePlans.map(
                      (plan) => _buildSubscriptionCard(
                        plan,
                        subscriptionProvider,
                        isCurrentPlan:
                            subscriptionProvider.currentSubscription?.plan.id ==
                            plan.id,
                      ),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
                  subscription.plan.name,
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
                const SizedBox(height: 8),
                Text(
                  'Expiry Date: ${_formatDate(subscription.expiryDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(
    SubscriptionPlan plan,
    SubscriptionProvider provider, {
    bool isCurrentPlan = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              plan.isPopular
                  ? const Color(0xFFFBB040)
                  : const Color(0xFF4A5568),
          width: plan.isPopular ? 2 : 1,
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color:
                  plan.isPopular
                      ? const Color(0xFFFBB040)
                      : const Color(0xFF4A5568),
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
                Text(
                  plan.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (plan.isPopular) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Colors.white, size: 16),
                ],
                if (isCurrentPlan) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  '\$${plan.price.toStringAsFixed(2)}/${_getPlanDurationText(plan.type)}',
                  style: const TextStyle(
                    color: Color(0xFFFBB040),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PER ${plan.type.toString().split('.').last.toUpperCase()}',
                  style: TextStyle(
                    color:
                        plan.isPopular ? const Color(0xFFFBB040) : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  plan.description,
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Column(
                  children:
                      plan.features
                          .map((feature) => _buildFeatureItem(feature))
                          .toList(),
                ),
                const SizedBox(height: 20),
                if (!isCurrentPlan) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          provider.isLoading
                              ? null
                              : () => _handleContinuePressed(plan, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBB040),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          provider.isLoading
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
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: const Text(
                      'Current Plan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if (isCurrentPlan) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _showCancelDialog(context, provider);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel Membership',
                        style: TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFF364C63),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 10),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.black, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPlanDurationText(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.daily:
        return 'Day';
      case SubscriptionType.monthly:
        return 'Month';
      case SubscriptionType.yearly:
        return 'Year';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleContinuePressed(
    SubscriptionPlan plan,
    SubscriptionProvider provider,
  ) async {
    // TODO: Integrate with in-app purchase here
    // For now, we'll simulate the purchase

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing subscription...'),
              ],
            ),
          ),
    );

    // Simulate purchase process
    await Future.delayed(const Duration(seconds: 2));

    final success = await provider.purchaseSubscription(
      userId: widget.userId,
      plan: plan,
      transactionId: 'simulated_${DateTime.now().millisecondsSinceEpoch}',
      metadata: {'platform': 'flutter', 'purchase_method': 'simulated'},
    );

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully subscribed to ${plan.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to subscribe: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelDialog(BuildContext context, SubscriptionProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(10),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
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
                                success ? Colors.green : Colors.red,
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
