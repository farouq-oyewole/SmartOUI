import 'package:bank_app/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/flutterwave_service.dart';
import '../services/firestore_service.dart';
import '../models/payment_model.dart';
import 'auth_provider.dart';
import 'transaction_provider.dart';

// Services
final paymentServiceProvider = Provider<FlutterwaveService>((ref) => FlutterwaveService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// Payment History State
class PaymentNotifier extends StateNotifier<List<PaymentResult>> {
  final FlutterwaveService _flutterwaveService;
  // ignore: unused_field
  final FirestoreService _firestoreService;
  final Ref _ref;

  PaymentNotifier(this._flutterwaveService, this._firestoreService, this._ref) : super([]);

  Future<PaymentResult> processPayment({
    required double amount,
    required String description,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final result = await _flutterwaveService.makePayment(
        amount: amount,
        description: description,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
      );

      // Update payment history list
      state = [result, ...state];
      return result;
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  Future<void> initiatePayment({
  required double amount,
  required String currency,
  required String description,
  String? redirectUrl,
}) async {
  // Read the current user directly
  final currentUser = _ref.read(currentAppUserProvider);
  if (currentUser == null) {
    throw Exception('User not authenticated');
  }

  // Call your payment service
  final paymentData = await _flutterwaveService.initiatePayment(
    amount: amount,
    currency: currency,
    email: currentUser.email,
    phoneNumber: currentUser.phoneNumber ?? '',
    name: currentUser.name,
    redirectUrl: redirectUrl,
  );

  // Build a pending transaction
  final transaction = Transactions(
    id: '',
    userId: currentUser.id,
    name: description,
    description: description,
    amount: amount,
    type: 'credit',
    category: 'deposit',
    date: DateTime.now(),
    status: TransactionStatus.pending,
    reference: paymentData['data']['tx_ref'],
    metadata: {},
  );

  // Save it to Firestore / state
  await _ref.read(transactionNotifierProvider.notifier).addTransaction(transaction);
}

  Future<PaymentResult> verifyPayment(String transactionId) async {
    try {
      return await _flutterwaveService.verifyPayment(transactionId);
    } catch (e) {
      throw Exception('Payment verification failed: $e');
    }
  }

  void openPaymentPage({
  required double amount,
  required String currency,
  required String description,
  String? redirectUrl,
}) {
  final currentUser = _ref.read(currentAppUserProvider);

  if (currentUser == null) return;

  _flutterwaveService.openPaymentPage(
    amount: amount,
    currency: currency,
    email: currentUser.email,
    name: currentUser.name,
    redirectUrl: redirectUrl,
  );
}


  void clearPaymentHistory() {
    state = [];
  }
}

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, List<PaymentResult>>((ref) {
  final flutterwaveService = ref.watch(paymentServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PaymentNotifier(flutterwaveService, firestoreService, ref);
});

final paymentHistoryProvider = Provider<List<PaymentResult>>((ref) {
  return ref.watch(paymentNotifierProvider);
});
