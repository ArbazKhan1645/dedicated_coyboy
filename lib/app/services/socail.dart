import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class SocialService {
  // Fixed typo: SocailService -> SocialService
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Configure GoogleSignIn with serverClientId

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize();
      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      const List<String> scopes = <String>[
        'https://www.googleapis.com/auth/contacts.readonly',
      ];

      final GoogleSignInClientAuthorization? authorization = await googleUser
          .authorizationClient
          .authorizationForScopes(scopes);

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleAuth.idToken,
      );

      var user = await _auth.signInWithCredential(credential);

      _createOrUpdateUserProfile(user.user!);
      // Sign in to Firebase with the Google user credential
      return user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> _createOrUpdateUserProfile(User? user) async {
    if (user == null) {
      return;
    }
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      final userDoc = _firestore.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();

      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
      };

      if (!userSnapshot.exists) {
        // Create new user document

        await userDoc.set(userData);
        print('New user profile created for: ${user.uid}');
      } else {
        // Update existing user document
        await userDoc.update(userData);
        print('User profile updated for: ${user.uid}');
      }
    } catch (e) {
      print('Error creating/updating user profile: $e');
      // Don't throw here as authentication was successful
    }
  }

  // Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      await FacebookAuth.instance.logOut();

      // Trigger the sign-in flow with basic permissions only
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: [
          'public_profile',
        ], // These are basic permissions that don't require review
      );
      if (loginResult.status == LoginStatus.success) {
        // Create a credential from the access token
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(
              loginResult.accessToken!.tokenString,
            );

        var user = await _auth.signInWithCredential(facebookAuthCredential);

        _createOrUpdateUserProfile(user.user!);
        // Sign in to Firebase with the Google user credential
        return user;
      } else if (loginResult.status == LoginStatus.cancelled) {
        // User canceled the sign-in
        return null;
      } else {
        throw Exception('Facebook login failed: ${loginResult.message}');
      }
    } catch (e) {
      print('Facebook Sign-In Error: $e');
      throw Exception('Facebook sign-in failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Email Sign-In Error: $e');
      throw Exception('Email sign-in failed: $e');
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Email Registration Error: $e');
      throw Exception('Email registration failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from all providers
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
    } catch (e) {
      print('Sign Out Error: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      print('Delete Account Error: $e');
      throw Exception('Account deletion failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Reset Password Error: $e');
      throw Exception('Password reset failed: $e');
    }
  }

  // Get user profile data
  Map<String, dynamic>? getUserProfile() {
    final user = _auth.currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'isAnonymous': user.isAnonymous,
        'creationTime': user.metadata.creationTime,
        'lastSignInTime': user.metadata.lastSignInTime,
      };
    }
    return null;
  }
}
