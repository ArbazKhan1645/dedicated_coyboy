import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StripeService {
  static const String _baseUrl = 'https://your-backend-url.com'; // Replace with your backend URL
  
  static Future<void> init() async {
    Stripe.publishableKey = 'pk_test_your_publishable_key_here'; // Replace with your publishable key
    await Stripe.instance.applySettings();
  }

  static Future<Map<String, dynamic>> createPaymentIntent({
    required String amount,
    required String currency,
    String? customerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'currency': currency,
          'customer_id': customerId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  static Future<bool> processPayment({
    required String paymentIntentClientSecret,
    String? returnUrl,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: 'Your Business Name',
          returnURL: returnUrl ?? 'your-app://stripe-redirect',
          style: ThemeMode.system,
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            name: CollectionMode.always,
            email: CollectionMode.always,
            phone: CollectionMode.never,
            address: AddressCollectionMode.never,
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      print('Stripe Exception: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      print('Other Exception: $e');
      return false;
    }
  }

  static Future<bool> processCardPayment({
    required String paymentIntentClientSecret,
    required PaymentMethodParams paymentMethodParams,
  }) async {
    try {
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntentClientSecret,
        data: paymentMethodParams,
      );
      
      return result.status == PaymentIntentsStatus.Succeeded;
    } on StripeException catch (e) {
      print('Stripe Exception: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      print('Other Exception: $e');
      return false;
    }
  }
}