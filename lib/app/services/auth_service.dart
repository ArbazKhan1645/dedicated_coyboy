// services/auth_service.dart
import 'package:dedicated_cowboy/app/models/user_model.dart';
import 'package:dedicated_cowboy/app/repository/auth_repository.dart';
import 'package:dedicated_cowboy/app/utils/exceptions.dart';

class AuthService {
  final AuthRepository _authRepository;
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

  // Sign In
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    _validateEmail(email);
    _validatePassword(password);

    try {
      final user = await _authRepository.signInWithEmailAndPassword(email, password);
      _currentUser = user;
      return user;
    } catch (e) {
      _currentUser = null;
      rethrow;
    }
  }

  // Sign Up
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _validateEmail(email);
    _validatePassword(password);

    try {
      final user = await _authRepository.signUpWithEmailAndPassword(email, password);
      
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
      throw const AuthException(
        message: 'No user signed in.',
        code: 'no-user',
      );
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
      throw const AuthException(
        message: 'No user signed in.',
        code: 'no-user',
      );
    }

    try {
      await _authRepository.updateProfile(
        displayName: displayName?.trim(),
        photoURL: photoURL?.trim(),
      );
      
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

// utils/auth_validator.dart
class AuthValidator {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
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
    
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirmPassword) {
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
}

// // Example usage in a controller or bloc
// class AuthController {
//   final AuthService _authService = AuthService();
  
//   // Initialize
//   Future<void> initialize() async {
//     try {
//       await _authService.initialize();
//     } catch (e) {
//       print('Failed to initialize auth service: $e');
//     }
//   }

//   // Sign In Method
//   Future<bool> signIn(String email, String password) async {
//     try {
//       await _authService.signIn(email: email, password: password);
//       return true;
//     } on AuthException catch (e) {
//       // Handle specific auth errors
//       print('Sign in error: ${e.message}');
//       return false;
//     } catch (e) {
//       print('Unexpected error during sign in: $e');
//       return false;
//     }
//   }

//   // Sign Up Method
//   Future<bool> signUp(String email, String password, {String? displayName}) async {
//     try {
//       await _authService.signUp(
//         email: email,
//         password: password,
//         displayName: displayName,
//       );
//       return true;
//     } on AuthException catch (e) {
//       print('Sign up error: ${e.message}');
//       return false;
//     } catch (e) {
//       print('Unexpected error during sign up: $e');
//       return false;
//     }
//   }

//   // Sign Out Method
//   Future<bool> signOut() async {
//     try {
//       await _authService.signOut();
//       return true;
//     } on AuthException catch (e) {
//       print('Sign out error: ${e.message}');
//       return false;
//     } catch (e) {
//       print('Unexpected error during sign out: $e');
//       return false;
//     }
//   }

//   // Reset Password Method
//   Future<bool> resetPassword(String email) async {
//     try {
//       await _authService.sendPasswordResetEmail(email);
//       return true;
//     } on AuthException catch (e) {
//       print('Password reset error: ${e.message}');
//       return false;
//     } catch (e) {
//       print('Unexpected error during password reset: $e');
//       return false;
//     }
//   }

//   // Getters
//   UserModel? get currentUser => _authService.currentUser;
//   bool get isSignedIn => _authService.isSignedIn;
//   bool get isEmailVerified => _authService.isEmailVerified;
//   Stream<UserModel?> get authStateChanges => _authService.authStateChanges;
// }