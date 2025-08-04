import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

class TransactionNotifier extends StateNotifier<List<Transactions>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  TransactionNotifier(this._firestoreService, this._ref) : super([]) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final user = _ref.read(currentAppUserProvider);
    if (user != null) {
      try {
        final transactions = await _firestoreService.getTransactions(user.id);
        state = transactions;
      } catch (e) {
        // Optionally handle/log the error
      }
    }
  }

  Future<void> addTransaction(Transactions transaction) async {
    try {
      final id = await _firestoreService.addTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);
      state = [newTransaction, ...state];
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  Future<void> refreshTransactions() async {
    await _loadTransactions();
  }

  List<Transactions> getTransactionsByType(String type) {
    return state.where((t) => t.type == type).toList();
  }

  List<Transactions> getTransactionsByCategory(String category) {
    return state.where((t) => t.category == category).toList();
  }

  List<Transactions> getRecentTransactions({int limit = 10}) {
    final sorted = [...state]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }
}

// Main state notifier
final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, List<Transactions>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return TransactionNotifier(firestoreService, ref);
});

// All transactions
final transactionsProvider = StreamProvider<List<Transactions>>((ref) {
  final user = ref.watch(currentAppUserProvider);
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: user.id)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Transactions.fromFirestore(doc))
          .toList());
});

// Recent transactions
final recentTransactionsProvider = Provider<List<Transactions>>((ref) {
  return ref.watch(transactionNotifierProvider.notifier).getRecentTransactions();
});

// Firestore stream for real-time transaction updates
final transactionsStreamProvider = StreamProvider<List<Transactions>>((ref) {
  final user = ref.watch(currentAppUserProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (user != null) {
    return firestoreService.getTransactionsStream(user.id);
  } else {
    return const Stream.empty();
  }
});
