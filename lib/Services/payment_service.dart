import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:uuid/uuid.dart';

class FlutterwavePaymentService {
  final String publicKey;
  final bool isTestMode;

  FlutterwavePaymentService({
    required this.publicKey,
    this.isTestMode = true,
  });

  Future<ChargeResponse?> makePayment({
    required BuildContext context,
    required double amount,
    required String email,
    required String fullName,
    required String phoneNumber,
  }) async {
    final txRef = const Uuid().v1();

    final customer = Customer(
      name: fullName,
      phoneNumber: phoneNumber,
      email: email,
    );

    final flutterwave = Flutterwave(
      publicKey: 'FLWPUBK_TEST-4c5e1af51da5ea47b8a1e6d42a94b646-X',
      currency: 'NGN',
      redirectUrl: 'https://www.google.com', // Update this to your redirect URL
      txRef: txRef,
      amount: amount.toStringAsFixed(2),
      customer: customer,
      paymentOptions: 'card,ussd,barter',
      customization: Customization(
        title: 'Bank App Payment',
        description: "Payment via Flutterwave",
        logo: 'https://yourapp.com/logo.png', // Optional
      ),
      isTestMode: isTestMode,
    );

    final response = await flutterwave.charge(context);
    return response;
  }
}
