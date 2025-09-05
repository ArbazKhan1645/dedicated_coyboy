import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference for favorites
  CollectionReference get _favoritesCollection =>
      _firestore.collection('favorites');

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Add a listing to favorites
  Future<bool> addToFavorites({
    required String listingId,
    required String listingType, // 'Item', 'Business', 'Event'
    required String listingName,
    required String? listingImage,
    required List<String>? category,
    required double? price, // For items only
    required String ownerId,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final favoriteDoc = _favoritesCollection
          .doc(_currentUserId)
          .collection('userFavorites')
          .doc(listingId);

      final favoriteData = {
        'listingId': listingId,
        'listingType': listingType,
        'listingName': listingName,
        'listingImage': listingImage,
        'category': category,
        'price': price,
        'ownerId': ownerId,
        'addedAt': FieldValue.serverTimestamp(),
        'userId': _currentUserId,
      };

      await favoriteDoc.set(favoriteData);

      // Update favorites count in user's main document
      await _updateFavoritesCount(1);

      debugPrint('Added to favorites: $listingName');
      return true;
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      return false;
    }
  }

  /// Remove a listing from favorites
  Future<bool> removeFromFavorites(String listingId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _favoritesCollection
          .doc(_currentUserId)
          .collection('userFavorites')
          .doc(listingId)
          .delete();

      // Update favorites count in user's main document
      await _updateFavoritesCount(-1);

      debugPrint('Removed from favorites: $listingId');
      return true;
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      return false;
    }
  }

  /// Check if a listing is in favorites
  Future<bool> isFavorite(String listingId) async {
    try {
      if (_currentUserId == null) return false;

      final doc =
          await _favoritesCollection
              .doc(_currentUserId)
              .collection('userFavorites')
              .doc(listingId)
              .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite({
    required String listingId,
    required String listingType,
    required String listingName,
    required String? listingImage,
    required List<String>? category,
    required double? price,
    required String ownerId,
  }) async {
    try {
      final isCurrentlyFavorite = await isFavorite(listingId);

      if (isCurrentlyFavorite) {
        await removeFromFavorites(listingId);
        return false; // No longer favorite
      } else {
        await addToFavorites(
          listingId: listingId,
          listingType: listingType,
          listingName: listingName,
          listingImage: listingImage,
          category: category,
          price: price,
          ownerId: ownerId,
        );
        return true; // Now favorite
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  /// Get all favorites for current user
  Stream<List<FavoriteItem>> getUserFavorites() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _favoritesCollection
        .doc(_currentUserId)
        .collection('userFavorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return FavoriteItem.fromMap(data);
          }).toList();
        });
  }

  /// Get favorites by type
  Stream<List<FavoriteItem>> getFavoritesByType(String listingType) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _favoritesCollection
        .doc(_currentUserId)
        .collection('userFavorites')
        .where('listingType', isEqualTo: listingType)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return FavoriteItem.fromMap(data);
          }).toList();
        });
  }

  /// Get favorites by category
  Stream<List<FavoriteItem>> getFavoritesByCategory(String category) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _favoritesCollection
        .doc(_currentUserId)
        .collection('userFavorites')
        .where('category', isEqualTo: category)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return FavoriteItem.fromMap(data);
          }).toList();
        });
  }

  /// Get favorites count for current user
  Future<int> getFavoritesCount() async {
    try {
      if (_currentUserId == null) return 0;

      final snapshot =
          await _favoritesCollection
              .doc(_currentUserId)
              .collection('userFavorites')
              .count()
              .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting favorites count: $e');
      return 0;
    }
  }

  /// Clear all favorites for current user
  Future<bool> clearAllFavorites() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      final snapshot =
          await _favoritesCollection
              .doc(_currentUserId)
              .collection('userFavorites')
              .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Reset favorites count
      await _resetFavoritesCount();

      debugPrint('Cleared all favorites');
      return true;
    } catch (e) {
      debugPrint('Error clearing all favorites: $e');
      return false;
    }
  }

  /// Update favorites count in user document
  Future<void> _updateFavoritesCount(int increment) async {
    try {
      if (_currentUserId == null) return;

      await _firestore.collection('users').doc(_currentUserId).update({
        'favoritesCount': FieldValue.increment(increment),
      });
    } catch (e) {
      debugPrint('Error updating favorites count: $e');
    }
  }

  /// Reset favorites count to 0
  Future<void> _resetFavoritesCount() async {
    try {
      if (_currentUserId == null) return;

      await _firestore.collection('users').doc(_currentUserId).update({
        'favoritesCount': 0,
      });
    } catch (e) {
      debugPrint('Error resetting favorites count: $e');
    }
  }

  /// Get favorite items for a specific listing ID (useful for checking across users)
  Future<List<String>> getUsersWhoFavorited(String listingId) async {
    try {
      final userIds = <String>[];

      // This would require a different collection structure for efficiency
      // For now, we'll keep it simple and not implement this
      // In production, you might want to maintain a separate collection
      // for listing favorites with user IDs as an array

      return userIds;
    } catch (e) {
      debugPrint('Error getting users who favorited: $e');
      return [];
    }
  }

  /// Search favorites
  Stream<List<FavoriteItem>> searchFavorites(String query) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _favoritesCollection
        .doc(_currentUserId)
        .collection('userFavorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final allFavorites =
              snapshot.docs.map((doc) {
                final data = doc.data();
                return FavoriteItem.fromMap(data);
              }).toList();

          // Filter by search query
          if (query.isEmpty) return allFavorites;

          final lowercaseQuery = query.toLowerCase();
          return allFavorites.where((favorite) {
            final name = favorite.listingName.toLowerCase();
            final type = favorite.listingType.toLowerCase();
            final categories = favorite.category ?? []; // List<String>

            return name.contains(lowercaseQuery) ||
                type.contains(lowercaseQuery) ||
                categories.any((c) => c.toLowerCase().contains(lowercaseQuery));
          }).toList();
        });
  }
}

/// Model class for favorite items
class FavoriteItem {
  final String listingId;
  final String listingType;
  final String listingName;
  final String? listingImage;
  final List<String>? category;
  final double? price;
  final String ownerId;
  final DateTime? addedAt;
  final String userId;

  FavoriteItem({
    required this.listingId,
    required this.listingType,
    required this.listingName,
    this.listingImage,
    this.category,
    this.price,
    required this.ownerId,
    this.addedAt,
    required this.userId,
  });

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      listingId: map['listingId'] ?? '',
      listingType: map['listingType'] ?? '',
      listingName: map['listingName'] ?? '',
      listingImage: map['listingImage'],
      category:
          map['category'] != null ? List<String>.from(map['category']) : null,
      price: map['price']?.toDouble(),
      ownerId: map['ownerId'] ?? '',
      addedAt:
          map['addedAt'] != null
              ? (map['addedAt'] as Timestamp).toDate()
              : null,
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'listingType': listingType,
      'listingName': listingName,
      'listingImage': listingImage,
      'category': category,
      'price': price,
      'ownerId': ownerId,
      'addedAt': addedAt != null ? Timestamp.fromDate(addedAt!) : null,
      'userId': userId,
    };
  }

  @override
  String toString() {
    return 'FavoriteItem(listingId: $listingId, listingName: $listingName, listingType: $listingType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteItem && other.listingId == listingId;
  }

  @override
  int get hashCode => listingId.hashCode;
}
