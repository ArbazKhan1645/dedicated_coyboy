import 'package:dedicated_cowboy/app/models/user_model.dart';
import 'package:dedicated_cowboy/app/utils/exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<void> reloadUser();
  Future<void> updateProfile({String? displayName, String? photoURL});
  Stream<UserModel?> get authStateChanges;
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth}) 
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.reload();
        return UserModel.fromFirebaseUser(_firebaseAuth.currentUser!);
      }
      return null;
    } catch (e) {
      throw const AuthException(
        message: 'Failed to get current user.',
        code: 'get-user-failed',
      );
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (result.user == null) {
        throw const AuthException(
          message: 'Sign in failed. Please try again.',
          code: 'sign-in-failed',
        );
      }
      
      return UserModel.fromFirebaseUser(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthExceptions.fromFirebaseAuthException(e);
    } catch (e) {
      throw AuthExceptions.unknownError;
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (result.user == null) {
        throw const AuthException(
          message: 'Sign up failed. Please try again.',
          code: 'sign-up-failed',
        );
      }
      
      // Send email verification automatically
      await result.user!.sendEmailVerification();
      
      return UserModel.fromFirebaseUser(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthExceptions.fromFirebaseAuthException(e);
    } catch (e) {
      throw AuthExceptions.unknownError;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw const AuthException(
        message: 'Failed to sign out. Please try again.',
        code: 'sign-out-failed',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthExceptions.fromFirebaseAuthException(e);
    } catch (e) {
      throw const AuthException(
        message: 'Failed to send password reset email.',
        code: 'password-reset-failed',
      );
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else {
        throw const AuthException(
          message: 'No user signed in or email already verified.',
          code: 'no-user-or-verified',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException(
        message: 'Failed to send verification email.',
        code: 'verification-failed',
      );
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      throw const AuthException(
        message: 'Failed to reload user data.',
        code: 'reload-failed',
      );
    }
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        await user.reload();
      } else {
        throw const AuthException(
          message: 'No user signed in.',
          code: 'no-user',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException(
        message: 'Failed to update profile.',
        code: 'update-profile-failed',
      );
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((User? user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }
}