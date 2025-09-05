// ignore_for_file: use_build_context_synchronously

import 'package:dedicated_cowboy/app/services/stripe_services/payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';

class PaymentsCoinsController extends GetxController {
  Future<bool> initPaymentSheet(BuildContext context, double amount) async {
    try {
      final data = await createPaymentIntent(
        amount: (amount * 100).toInt().toString(),
        currency: 'GBP',
        name: 'Arbaz Khan',
        address: '',
        pin: '44',
        city: 'London',
        state: 'England',
        country: 'GB',
      );
                             
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            testEnv: true,
          ),
          customFlow: false,
          appearance: const PaymentSheetAppearance(
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xff43918D),
                  text: Colors.white,
                ),
                dark: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xff43918D),
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
              line2: 'Apt. 1',
              postalCode: 'W1A 1AB',
              state: 'England',
            ),
          ),
          merchantDisplayName: 'Test Merchant',
          paymentIntentClientSecret: data['client_secret'],
          customerEphemeralKeySecret: data['ephemeralKey'],
          customerId: data['id'],
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet().then((data) {
        print('$data sheet value');
      });
      return true;
    } catch (e) {
      if (e is StripeException &&
          e.error.localizedMessage == 'The payment flow has been canceled') {
        print('Payment canceled by the user');
      } else {
        print('Error during payment: $e');
      }
      return false;
    }
  }

  final count = 0.obs;

  void increment() => count.value++;
}
