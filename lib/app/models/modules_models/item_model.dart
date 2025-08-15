import 'package:cloud_firestore/cloud_firestore.dart';

class ItemListing {
  final String? id; // Firebase document ID
  final String? itemName;
  final String? description;
  final String? category;
  final String? subcategory;
  final String? location;
  final String? cityState;
  final double? latitude;
  final double? longitude;
  final String? linkWebsite;
  final List<String>? photoUrls;
  final List<String>? videoUrls;
  final List<String>? attachmentUrls;
  final String? sizeDimensions;
  final String? condition;
  final String? brand;
  final double? price;
  final String? shippingInfo;
  final String? email;
  final String? preferredContactMethod; // 'text', 'messenger', 'email'
  final String? paymentMethod; // 'paypal', 'venmo', 'cash', 'credit_card'
  final String? otherPaymentOptions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userId; // Reference to user who created the listing
  final bool? isActive;

  const ItemListing({
    this.id,
    this.itemName,
    this.description,
    this.category,
    this.subcategory,
    this.location,
    this.cityState,
    this.latitude,
    this.longitude,
    this.linkWebsite,
    this.photoUrls,
    this.videoUrls,
    this.attachmentUrls,
    this.sizeDimensions,
    this.condition,
    this.brand,
    this.price,
    this.shippingInfo,
    this.email,
    this.preferredContactMethod,
    this.paymentMethod,
    this.otherPaymentOptions,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.isActive,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'itemName': itemName,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'location': location,
      'cityState': cityState,
      'latitude': latitude,
      'longitude': longitude,
      'linkWebsite': linkWebsite,
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'attachmentUrls': attachmentUrls,
      'sizeDimensions': sizeDimensions,
      'condition': condition,
      'brand': brand,
      'price': price,
      'shippingInfo': shippingInfo,
      'email': email,
      'preferredContactMethod': preferredContactMethod,
      'paymentMethod': paymentMethod,
      'otherPaymentOptions': otherPaymentOptions,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
      'isActive': isActive ?? true,
    };
  }

  // Create from Firebase document
  factory ItemListing.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return ItemListing(
      id: documentId,
      itemName: data['itemName'] as String?,
      description: data['description'] as String?,
      category: data['category'] as String?,
      subcategory: data['subcategory'] as String?,
      location: data['location'] as String?,
      cityState: data['cityState'] as String?,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      linkWebsite: data['linkWebsite'] as String?,
      photoUrls: data['photoUrls'] != null 
          ? List<String>.from(data['photoUrls']) 
          : null,
      videoUrls: data['videoUrls'] != null 
          ? List<String>.from(data['videoUrls']) 
          : null,
      attachmentUrls: data['attachmentUrls'] != null 
          ? List<String>.from(data['attachmentUrls']) 
          : null,
      sizeDimensions: data['sizeDimensions'] as String?,
      condition: data['condition'] as String?,
      brand: data['brand'] as String?,
      price: data['price']?.toDouble(),
      shippingInfo: data['shippingInfo'] as String?,
      email: data['email'] as String?,
      preferredContactMethod: data['preferredContactMethod'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      otherPaymentOptions: data['otherPaymentOptions'] as String?,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      userId: data['userId'] as String?,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  // Copy with method for updates
  ItemListing copyWith({
    String? id,
    String? itemName,
    String? description,
    String? category,
    String? subcategory,
    String? location,
    String? cityState,
    double? latitude,
    double? longitude,
    String? linkWebsite,
    List<String>? photoUrls,
    List<String>? videoUrls,
    List<String>? attachmentUrls,
    String? sizeDimensions,
    String? condition,
    String? brand,
    double? price,
    String? shippingInfo,
    String? email,
    String? preferredContactMethod,
    String? paymentMethod,
    String? otherPaymentOptions,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    bool? isActive,
  }) {
    return ItemListing(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      location: location ?? this.location,
      cityState: cityState ?? this.cityState,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      linkWebsite: linkWebsite ?? this.linkWebsite,
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      sizeDimensions: sizeDimensions ?? this.sizeDimensions,
      condition: condition ?? this.condition,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      email: email ?? this.email,
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      otherPaymentOptions: otherPaymentOptions ?? this.otherPaymentOptions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'ItemListing(id: $id, itemName: $itemName, category: $category, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemListing && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Import statement needed for Timestamp
// import 'package:cloud_firestore/cloud_firestore.dart';