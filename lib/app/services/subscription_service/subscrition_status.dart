// widgets/subscription_status_widget.dart
import 'package:dedicated_cowboy/app/services/subscription_service/controller.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/subcriptions_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

class SubscriptionStatusWidget extends StatelessWidget {
  final String userId;
  final bool showDetails;

  const SubscriptionStatusWidget({
    super.key,
    required this.userId,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionProvider>(
      init: SubscriptionProvider(),
      builder: (provider) {
        if (provider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading subscription status...'),
                ],
              ),
            ),
          );
        }

        if (!provider.hasActiveSubscription) {
          return _buildNoSubscriptionCard(context);
        }

        return _buildActiveSubscriptionCard(context, provider);
      },
    );
  }

  Widget _buildNoSubscriptionCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No Active Subscription',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (showDetails) ...[
              const SizedBox(height: 8),
              Text(
                'You need an active subscription to create listings.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                SubscriptionManagementScreen(userId: userId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBB040),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Subscribe Now',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(
    BuildContext context,
    SubscriptionProvider provider,
  ) {
    final subscription = provider.currentSubscription!;
    final isExpiringSoon = provider.isExpiringSoon;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isExpiringSoon ? Colors.orange.shade300 : Colors.green.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isExpiringSoon
                      ? Icons.warning_outlined
                      : Icons.check_circle_outlined,
                  color:
                      isExpiringSoon
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subscription.plan.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showDetails)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  SubscriptionManagementScreen(userId: userId),
                        ),
                      );
                    },
                    child: const Text('Manage'),
                  ),
              ],
            ),
            if (showDetails) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires in ${provider.daysRemaining} days',
                    style: TextStyle(
                      color:
                          isExpiringSoon
                              ? Colors.orange.shade700
                              : Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight:
                          isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (isExpiringSoon) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Renew soon to avoid interruption',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// Compact version for navigation bars or headers
class CompactSubscriptionStatus extends StatelessWidget {
  final String userId;

  const CompactSubscriptionStatus({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionProvider>(
      init: SubscriptionProvider(),
      builder: (provider) {
        if (provider.isLoading) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => SubscriptionManagementScreen(userId: userId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  provider.hasActiveSubscription
                      ? (provider.isExpiringSoon
                          ? Colors.orange.shade100
                          : Colors.green.shade100)
                      : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  provider.hasActiveSubscription
                      ? (provider.isExpiringSoon
                          ? Icons.warning
                          : Icons.check_circle)
                      : Icons.error,
                  size: 14,
                  color:
                      provider.hasActiveSubscription
                          ? (provider.isExpiringSoon
                              ? Colors.orange.shade700
                              : Colors.green.shade700)
                          : Colors.red.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  provider.hasActiveSubscription
                      ? (provider.isExpiringSoon
                          ? '${provider.daysRemaining}d'
                          : 'Active')
                      : 'Subscribe',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        provider.hasActiveSubscription
                            ? (provider.isExpiringSoon
                                ? Colors.orange.shade700
                                : Colors.green.shade700)
                            : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
