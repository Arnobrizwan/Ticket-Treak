// lib/services/stripe_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  // Publishable key (safe to expose in client)
  static const String _publishableKey =
      'pk_test_51RFW5y2NnXdvWkYVoTAYTlbvMkuGViOrWihLyQ7d7M2drAxSN0aGoQ2Pry0JqP7fyimZoeVqxAb4iZbocG2imcLa009Sbj3xqD';

  // Secret key (only for testing; remove and move to backend in production)
  static const String _secretKey =
      'sk_test_51RFW5y2NnXdvWkYVjMqc1O9zPb39NfV87Gad49BNrKWj3Gw0POYrSSYxVxetHmi53Bx6mKRMjuA08sXieB3ClfKp00ipK3OAAs';

  // Test mode flag
  static const bool _isTestMode = true;

  /// Initialize the Stripe SDK with the publishable key.
  static Future<void> initialize() async {
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
    debugPrint('✅ Stripe initialized successfully');
  }

  /// Create a PaymentIntent on Stripe (only for test mode).
  ///
  /// Amount must be provided in the smallest currency unit (e.g., cents).
  static Future<Map<String, dynamic>> createPaymentIntent({
    required String
        amount, // e.g., "2999" for $29.99 USD (or equivalent in your currency’s smallest unit)
    required String currency,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isTestMode) {
      throw Exception('Production mode requires a backend implementation.');
    }

    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amount,
        'currency': currency,
        'automatic_payment_methods[enabled]': 'true',
        if (customerId != null) 'customer': customerId,
        if (metadata != null)
          ...metadata.map(
              (key, value) => MapEntry('metadata[$key]', value.toString())),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception(
          'Failed to create payment intent: ${response.statusCode} ${response.body}');
    }
  }

  /// Confirm a PaymentIntent using Flutter Stripe’s SDK.
  ///
  /// The `clientSecret` comes from `createPaymentIntent`.
  static Future<PaymentIntent> confirmPayment({
    required String clientSecret,
    required PaymentMethodParams paymentMethodParams,
  }) async {
    try {
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethodParams,
      );
      return result;
    } on StripeException catch (e) {
      // Rethrow the StripeException so caller can inspect error.code, error.localizedMessage, etc.
      rethrow;
    } catch (error) {
      throw Exception('Payment failed: $error');
    }
  }

  /// Convert a decimal amount to the smallest currency unit (cents, pence, etc.).
  static String amountToCents(double amount) {
    return (amount * 100).round().toString();
  }

  /// Convert from smallest currency unit back to a decimal amount.
  static double centsToAmount(int cents) {
    return cents / 100;
  }

  /// Returns true if Stripe.publishableKey has been set.
  static bool get isInitialized {
    return Stripe.publishableKey.isNotEmpty;
  }

  /// Returns the publishable key (for debugging or logging).
  static String get publishableKey {
    return _publishableKey;
  }

  /// Returns true if you are running in test mode.
  static bool get isTestMode {
    return _isTestMode;
  }

  /// For local testing, validate known Stripe test card numbers.
  static bool isValidTestCard(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');

    const validTestCards = [
      '4242424242424242', // Visa
      '5555555555554444', // Mastercard
      '378282246310005', // American Express
      '6011111111111117', // Discover
      '3056930009020004', // Diners Club
      '5200828282828210', // Mastercard (debit)
      '4000056655665556', // Visa (debit)
    ];

    return validTestCards.contains(cleanNumber);
  }

  /// Get expected test outcome for a given card number.
  static String getExpectedTestResult(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (isValidTestCard(cleanNumber)) {
      return 'Test card: expected to succeed.';
    } else {
      return 'Test card: expected to be declined.';
    }
  }
}
