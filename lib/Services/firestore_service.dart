import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> createUser(AppUser user) async {
    await _firestore.collection('users').doc(user.id).set(user.toFirestore());
  }

  Future<void> deleteUser(String uid) async {
  try {
    await _firestore.collection('users').doc(uid).delete();

    // Optionally delete user's transactions or other related data
    final batch = _firestore.batch();
    final transactionSnapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .get();

    for (final doc in transactionSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  } catch (e) {
    throw Exception('Failed to delete user data: $e');
  }
}


  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }
    return null;
  }

  Stream<AppUser?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> updateUserBalance(String uid, double newBalance) async {
    await updateUser(uid, {'balance': newBalance});
  }

  // ✅ Add a transaction (with generated ID)
  Future<String> addTransaction(Transactions transaction) async {
    final docRef = _firestore.collection('transactions').doc();
    final transactionWithId = transaction.copyWith(id: docRef.id);
    await docRef.set(transactionWithId.toFirestore());
    return docRef.id;
  }

  // ✅ Get transactions once
  Future<List<Transactions>> getTransactions(String userId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Transactions.fromFirestore(doc))
        .toList();
  }

  // ✅ Get real-time transactions stream
  Stream<List<Transactions>> getTransactionsStream(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Transactions.fromFirestore(doc)).toList());
  }

  Future<List<Transactions>> getTransactionsByDateRange({
  required String userId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final snapshot = await _firestore
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
      .orderBy('date')
      .get();

  return snapshot.docs.map((doc) => Transactions.fromFirestore(doc)).toList();
}

Future<Map<String, double>> getTransactionSummary(
  String userId,
  DateTime startDate,
  DateTime endDate,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
      .get();

  double totalIncome = 0;
  double totalExpense = 0;

  for (final doc in snapshot.docs) {
    final txn = Transactions.fromFirestore(doc);
    if (txn.type == 'credit') {
      totalIncome += txn.amount;
    } else if (txn.type == 'debit') {
      totalExpense += txn.amount;
    }
  }

  return {
    'income': totalIncome,
    'expense': totalExpense,
  };
}

}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
