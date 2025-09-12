// services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dedicated_cowboy/app/models/user_model.dart';
import 'package:dedicated_cowboy/app/repository/auth_repository.dart';
import 'package:dedicated_cowboy/app/utils/exceptions.dart';

class AuthService {
  final AuthRepository _authRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;

  AuthService({AuthRepository? authRepository})
    : _authRepository = authRepository ?? FirebaseAuthRepository();

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;

  // Auth state stream
  Stream<UserModel?> get authStateChanges => _authRepository.authStateChanges;

  // Initialize service
  Future<void> initialize() async {
    try {
      _currentUser = await _authRepository.getCurrentUser();
    } catch (e) {
      _currentUser = null;
      rethrow;
    }
  }

  // Sign In with enhanced validation
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    _validateEmail(email);
    _validatePassword(password);

    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email,
        password,
      );
      _currentUser = user;
      return user;
    } catch (e) {
      _currentUser = null;
      rethrow;
    }
  }

  // Enhanced Sign Up with automatic Firestore document creation
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? facebookPageId,
  }) async {
    _validateEmail(email);
    _validatePassword(password);

    try {
      final user = await _authRepository.signUpWithEmailAndPassword(
        email,
        password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await _authRepository.updateProfile(displayName: displayName.trim());
        await _authRepository.reloadUser();
        _currentUser = await _authRepository.getCurrentUser();
      } else {
        _currentUser = user;
      }

      return _currentUser!;
    } catch (e) {
      _currentUser = null;
      rethrow;
    }
  }

  // Create or update user document in Firestore
  Future<void> createUserDocument(
    UserModel user, {
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? facebookPageId,
    String signInMethod = 'email',
  }) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'firstName': firstName ?? _extractFirstName(user.displayName),
        'lastName': lastName ?? _extractLastName(user.displayName),
        'phoneNumber': phoneNumber ?? '',
        'facebookPageId': facebookPageId ?? '',
        'photoURL': user.photoURL ?? '',
        'emailVerified': user.emailVerified,
        'signInMethod': signInMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isProfileComplete': true,
        'accountStatus': 'active',
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      throw const AuthException(
        message: 'Failed to create user profile. Please try again.',
        code: 'profile-creation-failed',
      );
    }
  }

  // Helper methods to extract names
  String _extractFirstName(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '';
    final parts = displayName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  String _extractLastName(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '';
    final parts = displayName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  // Check if user exists and has complete profile in Firestore
  Future<Map<String, dynamic>> checkUserInFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        return {'exists': false, 'isComplete': false, 'data': null};
      }

      final userData = doc.data()!;

      // Check for required fields
      final bool isComplete =
          userData.containsKey('email') &&
          userData.containsKey('displayName') &&
          userData.containsKey('firstName') &&
          userData.containsKey('lastName') &&
          userData['email'] != null &&
          userData['displayName'] != null &&
          userData['firstName'] != null &&
          userData['lastName'] != null &&
          userData['email'].toString().isNotEmpty &&
          userData['displayName'].toString().isNotEmpty &&
          userData['firstName'].toString().isNotEmpty &&
          userData['lastName'].toString().isNotEmpty;

      return {'exists': true, 'isComplete': isComplete, 'data': userData};
    } catch (e) {
      return {'exists': false, 'isComplete': false, 'data': null};
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      _currentUser = null;
    } catch (e) {
      rethrow;
    }
  }

  // Forgot Password
  Future<void> sendPasswordResetEmail(String email) async {
    _validateEmail(email);

    try {
      await _authRepository.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    if (_currentUser == null) {
      throw const AuthException(message: 'No user signed in.', code: 'no-user');
    }

    if (_currentUser!.emailVerified) {
      throw const AuthException(
        message: 'Email is already verified.',
        code: 'already-verified',
      );
    }

    try {
      await _authRepository.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // Reload User Data
  Future<void> reloadUser() async {
    try {
      await _authRepository.reloadUser();
      _currentUser = await _authRepository.getCurrentUser();
    } catch (e) {
      rethrow;
    }
  }

  // Update Profile
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (_currentUser == null) {
      throw const AuthException(message: 'No user signed in.', code: 'no-user');
    }

    try {
      await _authRepository.updateProfile(
        displayName: displayName?.trim(),
        photoURL: photoURL?.trim(),
      );

      // Also update Firestore document
      if (displayName != null || photoURL != null) {
        final updateData = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (displayName != null) {
          updateData['displayName'] = displayName.trim();
          updateData['firstName'] = _extractFirstName(displayName);
          updateData['lastName'] = _extractLastName(displayName);
        }

        if (photoURL != null) {
          updateData['photoURL'] = photoURL.trim();
        }

        await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .update(updateData);
      }

      await reloadUser();
      return _currentUser!;
    } catch (e) {
      rethrow;
    }
  }

  // Private validation methods
  void _validateEmail(String email) {
    if (email.isEmpty) {
      throw const AuthException(
        message: 'Email cannot be empty.',
        code: 'empty-email',
      );
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      throw AuthExceptions.invalidEmail;
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw const AuthException(
        message: 'Password cannot be empty.',
        code: 'empty-password',
      );
    }

    if (password.length < 6) {
      throw const AuthException(
        message: 'Password must be at least 6 characters long.',
        code: 'password-too-short',
      );
    }
  }
}

// Enhanced AuthValidator with additional validations
class AuthValidator {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      throw AuthExceptions.invalidEmail;
    }

    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    // Enhanced password validation
    if (password.length < 8) {
      return 'Password should be at least 8 characters for better security';
    }

    return null;
  }

  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  static String? validateDisplayName(String? displayName) {
    if (displayName != null && displayName.isNotEmpty) {
      if (displayName.trim().length < 2) {
        return 'Name must be at least 2 characters long';
      }

      if (displayName.trim().length > 50) {
        return 'Name must be less than 50 characters';
      }
    }

    return null;
  }

  static String? validateName(String? name, String fieldName) {
    if (name == null || name.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (name.trim().length < 2) {
      return '$fieldName must be at least 2 characters long';
    }

    if (name.trim().length > 30) {
      return '$fieldName must be less than 30 characters';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters for validation
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number with at least 10 digits';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number is too long (maximum 15 digits)';
    }

    return null;
  }
}
