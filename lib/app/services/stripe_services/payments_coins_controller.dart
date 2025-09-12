// services/stripe_services/payments_coins_controller.dart
// ignore_for_file: use_build_context_synchronously

import 'package:dedicated_cowboy/app/services/stripe_services/payment.dart';
import 'package:dedicated_cowboy/app/services/subscription_service/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum PaymentState {
  idle,
  initializing,
  processing,
  completed,
  failed,
  cancelled
}

class PaymentsCoinsController extends GetxController {
  final ConnectivityService _connectivityService = ConnectivityService();
  
  final Rx<PaymentState> _paymentState = PaymentState.idle.obs;
  PaymentState get paymentState => _paymentState.value;
  
  String? _currentPaymentIntentId;
  String? _lastError;
  
  String? get currentPaymentIntentId => _currentPaymentIntentId;
  String? get lastError => _lastError;

  @override
  void onInit() {
    super.onInit();
    _connectivityService.initialize();
  }

  Future<PaymentInitResult> initPaymentSheet(BuildContext context, double amount) async {
    try {
      _setPaymentState(PaymentState.initializing);
      _clearError();

      // Check internet connectivity
      final hasInternet = await _connectivityService.hasConnection();
      if (!hasInternet) {
        _setError('No internet connection. Please check your connection and try again.');
        _setPaymentState(PaymentState.failed);
        return PaymentInitResult(success: false, error: 'No internet connection');
      }

      // Create payment intent
      final data = await createPaymentIntent(
        amount: (amount * 100).toInt().toString(),
        currency: 'GBP',
        name: 'Subscription Purchase',
        address: '',
        pin: '44',
        city: 'London',
        state: 'England',
        country: 'GB',
      );

      if (data == null) {
        _setError('Failed to create payment intent');
        _setPaymentState(PaymentState.failed);
        return PaymentInitResult(success: false, error: 'Failed to create payment intent');
      }

      _currentPaymentIntentId = data['id'];
      
      // Save payment intent for recovery
      await _savePaymentIntent(data, amount);

      // Initialize Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'GB',
            testEnv: false, // Set to false for production
          ),
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'GB',
          ),
          customFlow: false,
          appearance: const PaymentSheetAppearance(
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFFF2B342),
                  text: Colors.white,
                ),
                dark: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFFF2B342),
                  text: Colors.white,
                ),
              ),
            ),
          ),
          billingDetails: const BillingDetails(
            address: Address(
              city: 'London',
              country: 'GB',
              line1: '1234 Main Street',
              line2: '',
              postalCode: 'W1A 1AB',
              state: 'England',
            ),
          ),
          merchantDisplayName: 'Dedicated Cowboy',
          paymentIntentClientSecret: data['client_secret'],
          customerEphemeralKeySecret: data['ephemeralKey'],
          customerId: data['id'],
          style: ThemeMode.light,
        ),
      );

      _setPaymentState(PaymentState.idle);
      return PaymentInitResult(
        success: true, 
        paymentIntentId: _currentPaymentIntentId!,
      );
    } catch (e) {
      _setError('Error initializing payment: $e');
      _setPaymentState(PaymentState.failed);
      print('Error during payment initialization: $e');
      return PaymentInitResult(success: false, error: e.toString());
    }
  }

  Future<PaymentResult> presentPaymentSheet() async {
    try {
      _setPaymentState(PaymentState.processing);
      
      // Check connectivity before presenting
      final hasInternet = await _connectivityService.hasConnection();
      if (!hasInternet) {
        _setError('No internet connection during payment');
        _setPaymentState(PaymentState.failed);
        return PaymentResult(
          success: false, 
          error: 'No internet connection',
          paymentIntentId: _currentPaymentIntentId,
        );
      }

      await Stripe.instance.presentPaymentSheet();
      
      _setPaymentState(PaymentState.completed);
      await _clearSavedPaymentIntent();
      
      return PaymentResult(
        success: true,
        paymentIntentId: _currentPaymentIntentId!,
        message: 'Payment completed successfully',
      );
    } on StripeException catch (e) {
      _setPaymentState(PaymentState.failed);
      
      if (e.error.localizedMessage?.contains('canceled') == true) {
        _setPaymentState(PaymentState.cancelled);
        return PaymentResult(
          success: false,
          error: 'Payment cancelled by user',
          paymentIntentId: _currentPaymentIntentId,
          isCancelled: true,
        );
      } else {
        _setError('Payment failed: ${e.error.localizedMessage}');
        return PaymentResult(
          success: false,
          error: e.error.localizedMessage ?? 'Payment failed',
          paymentIntentId: _currentPaymentIntentId,
        );
      }
    } catch (e) {
      _setError('Unexpected error during payment: $e');
      _setPaymentState(PaymentState.failed);
      print('Error during payment: $e');
      return PaymentResult(
        success: false,
        error: e.toString(),
        paymentIntentId: _currentPaymentIntentId,
      );
    }
  }

  // Combined method for easier use
  Future<PaymentResult> processPayment(BuildContext context, double amount) async {
    final initResult = await initPaymentSheet(context, amount);
    if (!initResult.success) {
      return PaymentResult(
        success: false,
        error: initResult.error ?? 'Failed to initialize payment',
      );
    }

    return await presentPaymentSheet();
  }

  // Save payment intent for recovery
  Future<void> _savePaymentIntent(Map<String, dynamic> paymentData, double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentInfo = {
        'paymentIntentId': paymentData['id'],
        'clientSecret': paymentData['client_secret'],
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'initialized',
      };
      
      await prefs.setString('current_payment_intent', jsonEncode(paymentInfo));
    } catch (e) {
      print('Error saving payment intent: $e');
    }
  }

  // Clear saved payment intent
  Future<void> _clearSavedPaymentIntent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_payment_intent');
    } catch (e) {
      print('Error clearing saved payment intent: $e');
    }
  }

  // Check for incomplete payments on app startup
  Future<String?> checkIncompletePayment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPaymentString = prefs.getString('current_payment_intent');
      
      if (savedPaymentString != null) {
        final paymentInfo = jsonDecode(savedPaymentString);
        final timestamp = DateTime.parse(paymentInfo['timestamp']);
        
        // If payment was started within last 30 minutes, it might still be valid
        if (DateTime.now().difference(timestamp).inMinutes < 30) {
          return paymentInfo['paymentIntentId'];
        } else {
          // Clear old payment intent
          await _clearSavedPaymentIntent();
        }
      }
    } catch (e) {
      print('Error checking incomplete payment: $e');
    }
    return null;
  }

  // Verify payment status with Stripe
  Future<bool> verifyPaymentStatus(String paymentIntentId) async {
    try {
      // This would typically call your backend to verify with Stripe
      // For now, we'll assume the subscription service handles this
      return true;
    } catch (e) {
      print('Error verifying payment status: $e');
      return false;
    }
  }

  void _setPaymentState(PaymentState state) {
    _paymentState.value = state;
    update();
  }

  void _setError(String error) {
    _lastError = error;
    update();
  }

  void _clearError() {
    _lastError = null;
    update();
  }

  // Reset controller state
  void reset() {
    _setPaymentState(PaymentState.idle);
    _currentPaymentIntentId = null;
    _clearError();
  }

  @override
  void onClose() {
    _connectivityService.dispose();
    super.onClose();
  }
}

// Result classes
class PaymentInitResult {
  final bool success;
  final String? error;
  final String? paymentIntentId;

  PaymentInitResult({
    required this.success,
    this.error,
    this.paymentIntentId,
  });
}

class PaymentResult {
  final bool success;
  final String? error;
  final String? message;
  final String? paymentIntentId;
  final bool isCancelled;

  PaymentResult({
    required this.success,
    this.error,
    this.message,
    this.paymentIntentId,
    this.isCancelled = false,
  });
}