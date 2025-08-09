import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:finimoi/core/config/stripe_config.dart';
import 'package:http/http.dart' as http; // To simulate network calls
import 'dart:convert';

class StripeService {

  Future<void> initStripe() async {
    Stripe.publishableKey = StripeConfig.publishableKey;
    await Stripe.instance.applySettings();
  }

  // This method simulates a call to your backend to create a PaymentIntent.
  Future<Map<String, dynamic>> _createPaymentIntent(double amount, String currency) async {
    // In a real app, this would be an http.post to your server.
    // final response = await http.post(Uri.parse('https://your-backend.com/create-payment-intent'), ...);

    print('Simulating backend call to create PaymentIntent...');
    await Future.delayed(const Duration(seconds: 1)); // Simulate network latency

    // This is a mock response that your backend would typically return.
    // The client_secret is the key piece of information needed by the frontend.
    return {
      'client_secret': 'pi_...YOUR_MOCK_CLIENT_SECRET_HERE',
      'ephemeral_key': 'ek_...YOUR_MOCK_EPHEMERAL_KEY_HERE',
      'customer': 'cus_...YOUR_MOCK_CUSTOMER_ID_HERE',
    };
  }

  Future<void> presentPaymentSheet(BuildContext context, {required double amount}) async {
    try {
      final paymentIntentData = await _createPaymentIntent(amount, 'EUR');

      if (paymentIntentData['client_secret'] == null) {
        throw Exception('Failed to create payment intent.');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'FinIMoi',
          customerId: paymentIntentData['customer'],
          customerEphemeralKeySecret: paymentIntentData['ephemeral_key'],
          style: ThemeMode.dark,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment completed!')),
      );

    } on StripeException catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.error.localizedMessage}')),
      );
    } catch (e) {
      print('Error presenting payment sheet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  // This is a placeholder for creating a virtual card.
  // Stripe Issuing requires a complex backend and verification process.
  Future<void> createVirtualCard() async {
    print('Simulating virtual card creation with Stripe Issuing...');
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, this would make a secure call to your backend,
    // which would then call the Stripe Issuing API.
  }

  // This is a placeholder for transferring funds to a bank account.
  // Stripe Connect or Payouts API would be used on the backend.
  Future<void> transferToBank() async {
    print('Simulating transfer to bank account via Stripe...');
    await Future.delayed(const Duration(seconds: 1));
  }
}
