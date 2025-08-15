import 'package:firebase_auth/firebase_auth.dart';

class AuthExceptions {
  static const AuthException invalidEmail = AuthException(
    message: 'The email address is not valid.',
    code: 'invalid-email',
  );

  static const AuthException userDisabled = AuthException(
    message: 'This user account has been disabled.',
    code: 'user-disabled',
  );

  static const AuthException userNotFound = AuthException(
    message: 'No user found with this email address.',
    code: 'user-not-found',
  );

  static const AuthException wrongPassword = AuthException(
    message: 'Incorrect password provided.',
    code: 'wrong-password',
  );

  static const AuthException weakPassword = AuthException(
    message: 'Password is too weak. Please choose a stronger password.',
    code: 'weak-password',
  );

  static const AuthException emailAlreadyInUse = AuthException(
    message: 'An account already exists with this email address.',
    code: 'email-already-in-use',
  );

  static const AuthException operationNotAllowed = AuthException(
    message: 'This operation is not allowed. Please contact support.',
    code: 'operation-not-allowed',
  );

  static const AuthException tooManyRequests = AuthException(
    message: 'Too many requests. Please try again later.',
    code: 'too-many-requests',
  );

  static const AuthException networkError = AuthException(
    message: 'Network error. Please check your connection.',
    code: 'network-request-failed',
  );

  static const AuthException unknownError = AuthException(
    message: 'An unknown error occurred. Please try again.',
    code: 'unknown',
  );

  static AuthException fromFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return invalidEmail;
      case 'user-disabled':
        return userDisabled;
      case 'user-not-found':
        return userNotFound;
      case 'wrong-password':
        return wrongPassword;
      case 'weak-password':
        return weakPassword;
      case 'email-already-in-use':
        return emailAlreadyInUse;
      case 'operation-not-allowed':
        return operationNotAllowed;
      case 'too-many-requests':
        return tooManyRequests;
      case 'network-request-failed':
        return networkError;
      default:
        return AuthException(
          message: e.message ?? 'An unknown error occurred.',
          code: e.code,
        );
    }
  }
}

class AuthException implements Exception {
  final String message;
  final String code;
  
  const AuthException({
    required this.message,
    required this.code,
  });

  @override
  String toString() => 'AuthException: $message (Code: $code)';
}