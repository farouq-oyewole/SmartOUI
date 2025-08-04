// ignore_for_file: deprecated_member_use

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';

class FlutterwaveService {
  static const String _baseUrl = 'https://api.flutterwave.com/v3';
  static const String _publicKey = 'FLWPUBK_TEST-your-public-key-here';
  static const String _secretKey = 'FLWSECK_TEST-your-secret-key-here';

  final http.Client _client = http.Client();

  // Initialize payment
  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String currency,
    required String email,
    required String phoneNumber,
    required String name,
    String? redirectUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final txRef = 'tx_${DateTime.now().millisecondsSinceEpoch}';
      
      final payload = {
        'tx_ref': txRef,
        'amount': amount,
        'currency': currency,
        'redirect_url': redirectUrl ?? 'https://your-app.com/payment-callback',
        'payment_options': 'card,banktransfer,ussd',
        'customer': {
          'email': email,
          'phonenumber': phoneNumber,
          'name': name,
        },
        'customizations': {
          'title': 'Banking App Payment',
          'description': 'Payment for banking services',
          'logo': 'https://your-app.com/logo.png',
        },
        'meta': metadata ?? {},
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/payments'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Payment initiation failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to initiate payment: $e');
    }
  }

  // ✅ Renamed raw API verification
  Future<Map<String, dynamic>> verifyPaymentRaw(String transactionId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/transactions/$transactionId/verify'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Payment verification failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to verify payment: $e');
    }
  }

  // ✅ Flutter-side model verification
  Future<PaymentResult> verifyPayment(String transactionId) async {
    try {
      // Simulate verification for now
      await Future.delayed(const Duration(seconds: 1));

      return PaymentResult.success(
        transactionId: transactionId,
        reference: 'VERIFIED_$transactionId',
        amount: 0.0,
        message: 'Payment verified successfully',
      );
    } catch (e) {
      return PaymentResult.failure(
        message: 'Payment verification failed: $e',
      );
    }
  }

  // Get payment details
  Future<Map<String, dynamic>> getPaymentDetails(String transactionId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/transactions/$transactionId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get payment details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get payment details: $e');
    }
  }

  // Create payment link
  Future<String> createPaymentLink({
    required double amount,
    required String currency,
    required String email,
    required String name,
    String? description,
    String? redirectUrl,
  }) async {
    try {
      final txRef = 'link_${DateTime.now().millisecondsSinceEpoch}';
      
      final payload = {
        'tx_ref': txRef,
        'amount': amount,
        'currency': currency,
        'customer': {
          'email': email,
          'name': name,
        },
        'customizations': {
          'title': 'Banking App Payment',
          'description': description ?? 'Payment for banking services',
        },
        'redirect_url': redirectUrl,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/payment-links'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['link'];
      } else {
        throw Exception('Payment link creation failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create payment link: $e');
    }
  }

  // Open payment page (web only)
  void openPaymentPage({
    required double amount,
    required String currency,
    required String email,
    required String name,
    String? redirectUrl,
  }) {
    final txRef = 'web_${DateTime.now().millisecondsSinceEpoch}';
    
    final script = '''
      FlutterwaveCheckout({
        public_key: "$_publicKey",
        tx_ref: "$txRef",
        amount: $amount,
        currency: "$currency",
        payment_options: "card,mobilemoney,ussd",
        customer: {
          email: "$email",
          name: "$name",
        },
        customizations: {
          title: "Banking App Payment",
          description: "Payment for banking services",
        },
        callback: function (data) {
          console.log(data);
          window.postMessage({type: 'PAYMENT_SUCCESS', data: data}, '*');
        },
        onclose: function() {
          window.postMessage({type: 'PAYMENT_CLOSED'}, '*');
        }
      });
    ''';

    html.document.head?.append(html.ScriptElement()
      ..type = 'text/javascript'
      ..innerHtml = script);
  }

  // Get transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    int page = 1,
    int perPage = 20,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (from != null) queryParams['from'] = from.toIso8601String();
      if (to != null) queryParams['to'] = to.toIso8601String();

      final uri = Uri.parse('$_baseUrl/transactions').replace(
        queryParameters: queryParams,
      );

      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to get transaction history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get transaction history: $e');
    }
  }

  // Refund payment
  Future<Map<String, dynamic>> refundPayment({
    required String transactionId,
    required double amount,
    String? comments,
  }) async {
    try {
      final payload = {
        'amount': amount,
        'comments': comments ?? 'Refund processed',
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/transactions/$transactionId/refund'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Refund failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  // Get supported banks
  Future<List<Map<String, dynamic>>> getSupportedBanks(String country) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/banks/$country'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to get banks: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get supported banks: $e');
    }
  }

  // Validate account
  Future<Map<String, dynamic>> validateAccount({
    required String accountNumber,
    required String accountBank,
  }) async {
    try {
      final payload = {
        'account_number': accountNumber,
        'account_bank': accountBank,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/accounts/resolve'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Account validation failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to validate account: $e');
    }
  }

  // Simulated payment
  Future<PaymentResult> makePayment({
    required double amount,
    required String description,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final reference = 'TXN_${DateTime.now().millisecondsSinceEpoch}';

      await Future.delayed(const Duration(seconds: 2));

      return PaymentResult.success(
        transactionId: 'FLW_${DateTime.now().millisecondsSinceEpoch}',
        reference: reference,
        amount: amount,
        message: 'Payment processed successfully',
        metadata: {
          'customer_name': customerName,
          'customer_email': customerEmail,
          'customer_phone': customerPhone,
          'description': description,
        },
      );
    } catch (e) {
      return PaymentResult.failure(
        message: 'Payment failed: $e',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

final flutterwaveServiceProvider = Provider<FlutterwaveService>((ref) {
  final service = FlutterwaveService();
  ref.onDispose(() => service.dispose());
  return service;
});
