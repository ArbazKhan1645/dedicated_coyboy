// models/subscription_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionType { daily, monthly, yearly }

enum SubscriptionStatus { active, expired, cancelled, pending }

class SubscriptionPlan {
  final String id;
  final String name;
  final SubscriptionType type;
  final double price;
  final int duration; // in days
  final List<String> features;
  final bool isPopular;
  final String description;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.duration,
    required this.features,
    this.isPopular = false,
    required this.description,
  });

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: SubscriptionType.values.firstWhere(
        (e) => e.toString() == 'SubscriptionType.${map['type']}',
        orElse: () => SubscriptionType.monthly,
      ),
      price: (map['price'] ?? 0.0).toDouble(),
      duration: map['duration'] ?? 30,
      features: List<String>.from(map['features'] ?? []),
      isPopular: map['isPopular'] ?? false,
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'price': price,
      'duration': duration,
      'features': features,
      'isPopular': isPopular,
      'description': description,
    };
  }

  static List<SubscriptionPlan> getDefaultPlans() {
    return [
      SubscriptionPlan(
        id: 'daily_plan',
        name: 'Daily Listing',
        type: SubscriptionType.daily,
        price: 1.99,
        duration: 1,
        features: ['Post Account Number', 'Basic Listing', 'Phone Number'],
        description: 'Perfect for one-time events or short-term needs',
      ),
      SubscriptionPlan(
        id: 'monthly_plan',
        name: 'Monthly Listing',
        type: SubscriptionType.monthly,
        price: 5.00,
        duration: 30,
        features: ['Post Account Number', 'Watchbox', 'Phone Number', 'Priority Support'],
        isPopular: true,
        description: 'Most popular choice for regular users',
      ),
      SubscriptionPlan(
        id: 'yearly_plan',
        name: 'Yearly Listing',
        type: SubscriptionType.yearly,
        price: 50.00,
        duration: 365,
        features: ['Post Account Number', 'Watchbox', 'Phone Number', 'Premium Features', 'Analytics Dashboard'],
        description: 'Best value with significant savings',
      ),
    ];
  }
}

class UserSubscription {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final SubscriptionStatus status;
  final String? transactionId;
  final Map<String, dynamic> metadata;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.purchaseDate,
    required this.expiryDate,
    required this.status,
    this.transactionId,
    this.metadata = const {},
  });

  factory UserSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSubscription(
      id: doc.id,
      userId: data['userId'] ?? '',
      plan: SubscriptionPlan.fromMap(data['plan'] ?? {}),
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString() == 'SubscriptionStatus.${data['status']}',
        orElse: () => SubscriptionStatus.pending,
      ),
      transactionId: data['transactionId'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'plan': plan.toMap(),
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status.toString().split('.').last,
      'transactionId': transactionId,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isActive => status == SubscriptionStatus.active && !isExpired;
  bool get isExpired => DateTime.now().isAfter(expiryDate);
  int get daysRemaining => isExpired ? 0 : expiryDate.difference(DateTime.now()).inDays;
  int get hoursRemaining => isExpired ? 0 : expiryDate.difference(DateTime.now()).inHours;

  UserSubscription copyWith({
    String? id,
    String? userId,
    SubscriptionPlan? plan,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    SubscriptionStatus? status,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      metadata: metadata ?? this.metadata,
    );
  }
}