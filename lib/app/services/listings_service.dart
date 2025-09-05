import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/models/modules_models/business_model.dart';
import 'package:dedicated_cowboy/app/models/modules_models/event_model.dart';
import 'package:dedicated_cowboy/app/models/modules_models/item_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';

class FirebaseServices {
  static final FirebaseServices _instance = FirebaseServices._internal();
  factory FirebaseServices() => _instance;
  FirebaseServices._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection names
  static const String itemsCollection = 'items';
  static const String businessesCollection = 'businesses';
  static const String eventsCollection = 'events';
  static const String usersCollection = 'users';

  // ==================== ITEM LISTINGS ====================

  /// Create a new item listing
  Future<String> createItem(ItemListing item) async {
    try {
      // Generate a document reference with an auto ID
      final docRef = _firestore.collection(itemsCollection).doc();

      // Copy item with ID and timestamps
      final updatedItem = item.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save the document
      await docRef.set(updatedItem.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  /// Get item by ID
  Future<ItemListing?> getItem(String id) async {
    try {
      final doc = await _firestore.collection(itemsCollection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return ItemListing.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get item: $e');
    }
  }

  /// Update item
  Future<bool> updateItem(String id, ItemListing item) async {
    try {
      await _firestore
          .collection(itemsCollection)
          .doc(id)
          .update(item.copyWith(updatedAt: DateTime.now()).toFirestore());

      return true; // Success
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  /// Delete item
  Future<void> deleteItem(String id) async {
    try {
      await _firestore.collection(itemsCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  /// Get items by user ID
  Stream<List<ItemListing>> getUserItems(String userId) {
    return _firestore
        .collection(itemsCollection)
        .where('userId', isEqualTo: userId)
        // .where('isActive', isEqualTo: true)
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ItemListing.fromFirestore(doc.data(), doc.id))
                  .toList(),
        );
  }

  /// Search items by category
  Stream<List<ItemListing>> getItemsByCategory(List<String> category) {
    return _firestore
        .collection(itemsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ItemListing.fromFirestore(doc.data(), doc.id))
                  .toList()
                  .where((doc) {
                    String normalizeCategory(String input) {
                      return input
                          .toLowerCase()
                          .replaceAll('&', 'and')
                          .replaceAll(RegExp(r'\s+'), ' ') // normalize spaces
                          .trim();
                    }

                    final docCategories =
                        (doc.category ?? [])
                            .map((c) => normalizeCategory(c.toString()))
                            .toList();

                    final filterCategories =
                        (category ?? [])
                            .map((c) => normalizeCategory(c.toString()))
                            .toList();

                    // Check if ANY filter category exists in doc categories
                    final hasMatch = filterCategories.any(
                      (c) => docCategories.contains(c),
                    );

                    return hasMatch;
                  })
                  .toList(),
        );
  }

  /// Get all active items
  Stream<List<ItemListing>> getAllItems({int? limit}) {
    Query query = _firestore
        .collection(itemsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (doc) => ItemListing.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
    );
  }

  // ==================== BUSINESS LISTINGS ====================

  /// Create a new business listing
  Future<String> createBusiness(BusinessListing business) async {
    try {
      // Generate a document reference with an auto ID
      final docRef = _firestore.collection(businessesCollection).doc();

      // Copy item with ID and timestamps
      final updatedItem = business.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save the document
      await docRef.set(updatedItem.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create business: $e');
    }
  }

  /// Get business by ID
  Future<BusinessListing?> getBusiness(String id) async {
    try {
      final doc =
          await _firestore.collection(businessesCollection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return BusinessListing.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get business: $e');
    }
  }

  /// Update business
  Future<void> updateBusiness(String id, BusinessListing business) async {
    try {
      await _firestore
          .collection(businessesCollection)
          .doc(id)
          .update(business.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw Exception('Failed to update business: $e');
    }
  }

  /// Delete business
  Future<void> deleteBusiness(String id) async {
    try {
      await _firestore.collection(businessesCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete business: $e');
    }
  }

  /// Get businesses by user ID
  Stream<List<BusinessListing>> getUserBusinesses(String userId) {
    return _firestore
        .collection(businessesCollection)
        .where('userId', isEqualTo: userId)
        // .where('isActive', isEqualTo: true)
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => BusinessListing.fromFirestore(doc.data(), doc.id),
                  )
                  .toList(),
        );
  }

  /// Search businesses by category
  Stream<List<BusinessListing>> getBusinessesByCategory(List<String> category) {
    return _firestore
        .collection(businessesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => BusinessListing.fromFirestore(doc.data(), doc.id),
                  )
                  .toList()
                  .where((doc) {
                    String normalizeCategory(String input) {
                      return input
                          .toLowerCase()
                          .replaceAll('&', 'and')
                          .replaceAll(RegExp(r'\s+'), ' ') // normalize spaces
                          .trim();
                    }

                    final docCategories =
                        (doc.businessCategory ?? [])
                            .map((c) => normalizeCategory(c.toString()))
                            .toList();

                    final filterCategories =
                        (category ?? [])
                            .map((c) => normalizeCategory(c.toString()))
                            .toList();

                    // Check if ANY filter category exists in doc categories
                    final hasMatch = filterCategories.any(
                      (c) => docCategories.contains(c),
                    );

                    return hasMatch;
                  })
                  .toList(),
        );
  }

  /// Get all active businesses
  Stream<List<BusinessListing>> getAllBusinesses({int? limit}) {
    Query query = _firestore
        .collection(businessesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (doc) => BusinessListing.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
    );
  }

  /// Get verified businesses
  Stream<List<BusinessListing>> getVerifiedBusinesses({int? limit}) {
    Query query = _firestore
        .collection(businessesCollection)
        .where('isActive', isEqualTo: true)
        .where('isVerified', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (doc) => BusinessListing.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
    );
  }

  // ==================== EVENT LISTINGS ====================

  /// Create a new event listing
  Future<String> createEvent(EventListing event) async {
    try {
      // Generate a document reference with an auto ID
      final docRef = _firestore.collection(eventsCollection).doc();

      // Copy item with ID and timestamps
      final updatedItem = event.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save the document
      await docRef.set(updatedItem.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  /// Get event by ID
  Future<EventListing?> getEvent(String id) async {
    try {
      final doc = await _firestore.collection(eventsCollection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return EventListing.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get event: $e');
    }
  }

  /// Update event
  Future<void> updateEvent(String id, EventListing event) async {
    try {
      await _firestore
          .collection(eventsCollection)
          .doc(id)
          .update(event.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  /// Delete event
  Future<void> deleteEvent(String id) async {
    try {
      await _firestore.collection(eventsCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  /// Get events by user ID
  Stream<List<EventListing>> getUserEvents(String userId) {
    return _firestore
        .collection(eventsCollection)
        .where('userId', isEqualTo: userId)
        // .where('isActive', isEqualTo: true)
        // .orderBy('eventStartDate', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => EventListing.fromFirestore(doc.data(), doc.id))
                  .toList(),
        );
  }

  /// Get upcoming events
  Stream<List<EventListing>> getUpcomingEvents({int? limit}) {
    Query query = _firestore
        .collection(eventsCollection)
        .where('isActive', isEqualTo: true)
        .where('eventStartDate', isGreaterThan: Timestamp.now())
        .orderBy('eventStartDate', descending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (doc) => EventListing.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
    );
  }

  /// Get events by category
  Stream<List<EventListing>> getEventsByCategory(List<String> category) {
    return _firestore
        .collection(eventsCollection)
        // .where('eventCategory', isEqualTo: category)
        // .where('isActive', isEqualTo: true)
        // .where('eventStartDate', isGreaterThan: Timestamp.now())
        // .orderBy('eventStartDate', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) {
                    print(snapshot.docs.length);
                    return EventListing.fromFirestore(doc.data(), doc.id);
                  })
                  .toList()
                  .where((doc) {
                    print(doc.eventName);
                    String normalizeCategory(String input) {
                      return input
                          .toLowerCase()
                          .replaceAll('&', 'and')
                          .replaceAll(RegExp(r'\s+'), ' ') // normalize spaces
                          .trim();
                    }

                    final docCategories =
                        (doc.eventCategory ?? [])
                            .map((c) => normalizeCategory(c.toString()))
                            .toList();

                    final filterCategories =
                        (category ?? [])
                            .map((c) => normalizeCategory(c.toString()))
                            .toList();

                    // Check if ANY filter category exists in doc categories
                    final hasMatch = filterCategories.any(
                      (c) => docCategories.contains(c),
                    );

                    return hasMatch;
                  })
                  .toList(),
        );
  }

  /// Get events happening today
  Stream<List<EventListing>> getTodaysEvents() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection(eventsCollection)
        .where('isActive', isEqualTo: true)
        .where(
          'eventStartDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'eventStartDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        )
        .orderBy('eventStartDate', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => EventListing.fromFirestore(doc.data(), doc.id))
                  .toList(),
        );
  }

  // ==================== FILE UPLOAD ====================

  /// Upload file to Firebase Storage
  Future<String> uploadFile({
    required dynamic file, // Can be File or Uint8List
    required String fileName,
    required String folder,
    String? userId,
  }) async {
    try {
      final String path =
          userId != null ? '$folder/$userId/$fileName' : '$folder/$fileName';

      final ref = _storage.ref().child(path);

      UploadTask uploadTask;
      if (file is File) {
        uploadTask = ref.putFile(file);
      } else if (file is Uint8List) {
        uploadTask = ref.putData(file);
      } else {
        throw Exception('Unsupported file type');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload multiple files
  Future<List<String>> uploadMultipleFiles({
    required List<dynamic> files,
    required List<String> fileNames,
    required String folder,
    String? userId,
  }) async {
    if (files.length != fileNames.length) {
      throw Exception('Files and fileNames lists must have the same length');
    }

    final List<String> downloadUrls = [];

    for (int i = 0; i < files.length; i++) {
      try {
        final url = await uploadFile(
          file: files[i],
          fileName: fileNames[i],
          folder: folder,
          userId: userId,
        );
        downloadUrls.add(url);
      } catch (e) {
        print('Failed to upload file ${fileNames[i]}: $e');
        // Continue with other files
      }
    }

    return downloadUrls;
  }

  /// Delete file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // ==================== SEARCH & FILTERS ====================

  /// Search across all collections
  Future<Map<String, List<dynamic>>> searchAll(String searchTerm) async {
    final results = <String, List<dynamic>>{
      'items': [],
      'businesses': [],
      'events': [],
    };

    try {
      // Search items
      final itemQuery =
          await _firestore
              .collection(itemsCollection)
              .where('isActive', isEqualTo: true)
              .get();

      results['items'] =
          itemQuery.docs
              .map((doc) => ItemListing.fromFirestore(doc.data(), doc.id))
              .where(
                (item) =>
                    item.itemName?.toLowerCase().contains(
                          searchTerm.toLowerCase(),
                        ) ==
                        true ||
                    item.description?.toLowerCase().contains(
                          searchTerm.toLowerCase(),
                        ) ==
                        true,
              )
              .toList();

      // Search businesses
      final businessQuery =
          await _firestore
              .collection(businessesCollection)
              .where('isActive', isEqualTo: true)
              .get();

      results['businesses'] =
          businessQuery.docs
              .map((doc) => BusinessListing.fromFirestore(doc.data(), doc.id))
              .where(
                (business) =>
                    business.businessName?.toLowerCase().contains(
                          searchTerm.toLowerCase(),
                        ) ==
                        true ||
                    business.description?.toLowerCase().contains(
                          searchTerm.toLowerCase(),
                        ) ==
                        true,
              )
              .toList();

      // Search events
      final eventQuery =
          await _firestore
              .collection(eventsCollection)
              .where('isActive', isEqualTo: true)
              .get();

      results['events'] =
          eventQuery.docs
              .map((doc) => EventListing.fromFirestore(doc.data(), doc.id))
              .where(
                (event) =>
                    event.eventName?.toLowerCase().contains(
                          searchTerm.toLowerCase(),
                        ) ==
                        true ||
                    event.description?.toLowerCase().contains(
                          searchTerm.toLowerCase(),
                        ) ==
                        true,
              )
              .toList();
    } catch (e) {
      throw Exception('Failed to search: $e');
    }

    return results;
  }

  // ==================== UTILITY METHODS ====================

  /// Check if user owns the listing
  bool isOwner(String userId, dynamic listing) {
    if (listing is ItemListing) return listing.userId == userId;
    if (listing is BusinessListing) return listing.userId == userId;
    if (listing is EventListing) return listing.userId == userId;
    return false;
  }

  /// Get user's total listings count
  Future<Map<String, int>> getUserListingsCount(String userId) async {
    try {
      final itemCount =
          await _firestore
              .collection(itemsCollection)
              .where('userId', isEqualTo: userId)
              .where('isActive', isEqualTo: true)
              .count()
              .get();

      final businessCount =
          await _firestore
              .collection(businessesCollection)
              .where('userId', isEqualTo: userId)
              .where('isActive', isEqualTo: true)
              .count()
              .get();

      final eventCount =
          await _firestore
              .collection(eventsCollection)
              .where('userId', isEqualTo: userId)
              .where('isActive', isEqualTo: true)
              .count()
              .get();

      return {
        'items': itemCount.count ?? 0,
        'businesses': businessCount.count ?? 0,
        'events': eventCount.count ?? 0,
        'total':
            (itemCount.count ?? 0) +
            (businessCount.count ?? 0) +
            (eventCount.count ?? 0),
      };
    } catch (e) {
      throw Exception('Failed to get user listings count: $e');
    }
  }

  /// Batch delete user's listings
  Future<void> deleteAllUserListings(String userId) async {
    final batch = _firestore.batch();

    try {
      // Get all user's items
      final items =
          await _firestore
              .collection(itemsCollection)
              .where('userId', isEqualTo: userId)
              .get();

      for (final doc in items.docs) {
        batch.delete(doc.reference);
      }

      // Get all user's businesses
      final businesses =
          await _firestore
              .collection(businessesCollection)
              .where('userId', isEqualTo: userId)
              .get();

      for (final doc in businesses.docs) {
        batch.delete(doc.reference);
      }

      // Get all user's events
      final events =
          await _firestore
              .collection(eventsCollection)
              .where('userId', isEqualTo: userId)
              .get();

      for (final doc in events.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user listings: $e');
    }
  }
}
