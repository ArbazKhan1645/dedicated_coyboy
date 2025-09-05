// report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/models/report_model/report_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  static ReportService? _instance;
  static ReportService get instance => _instance ??= ReportService._();
  ReportService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _reportsCollection = 'reports';

  // Predefined report reasons
  static const List<String> defaultReasons = [
    'Inappropriate content',
    'Spam or scam',
    'False information',
    'Offensive language',
    'Misleading pricing',
    'Duplicate listing',
    'Item not as described',
    'Unsafe or dangerous item',
    'Copyright violation',
    'Other (specify below)',
  ];

  // Submit a new report
  Future<bool> submitReport({
    required String listingId,
    required String listingType,
    required String listingName,
    String? listingImage,
    required String reason,
    String? customReason,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to submit reports');
      }

      // Check if user has already reported this listing
      final existingReport =
          await _firestore
              .collection(_reportsCollection)
              .where('reporterId', isEqualTo: currentUser.uid)
              .where('listingId', isEqualTo: listingId)
              .limit(1)
              .get();

      if (existingReport.docs.isNotEmpty) {
        throw Exception('You have already reported this listing');
      }

      final report = ReportModel(
        reporterId: currentUser.uid,
        listingId: listingId,
        listingType: listingType,
        listingName: listingName,
        listingImage: listingImage,
        reason: reason,
        customReason: customReason,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_reportsCollection).add(report.toFirestore());
      return true;
    } catch (e) {
      print('Error submitting report: $e');
      rethrow;
    }
  }

  // Get user's reports
  Stream<List<ReportModel>> getUserReports() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_reportsCollection)
        .where('reporterId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ReportModel.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get specific report by ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc =
          await _firestore.collection(_reportsCollection).doc(reportId).get();

      if (doc.exists) {
        return ReportModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting report: $e');
      return null;
    }
  }

  // Check if user has already reported a listing
  Future<bool> hasUserReportedListing(String listingId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final query =
          await _firestore
              .collection(_reportsCollection)
              .where('reporterId', isEqualTo: currentUser.uid)
              .where('listingId', isEqualTo: listingId)
              .limit(1)
              .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking report status: $e');
      return false;
    }
  }

  // Get reports count for a specific listing
  Future<int> getListingReportsCount(String listingId) async {
    try {
      final query =
          await _firestore
              .collection(_reportsCollection)
              .where('listingId', isEqualTo: listingId)
              .get();

      return query.docs.length;
    } catch (e) {
      print('Error getting reports count: $e');
      return 0;
    }
  }

  // Admin functions (if needed)
  Future<bool> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminResponse,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Admin must be authenticated');
      }

      await _firestore.collection(_reportsCollection).doc(reportId).update({
        'status': status.toString().split('.').last,
        'resolvedAt':
            status != ReportStatus.pending && status != ReportStatus.inReview
                ? Timestamp.fromDate(DateTime.now())
                : null,
        'adminResponse': adminResponse,
        'adminId': currentUser.uid,
      });

      return true;
    } catch (e) {
      print('Error updating report status: $e');
      return false;
    }
  }
}
