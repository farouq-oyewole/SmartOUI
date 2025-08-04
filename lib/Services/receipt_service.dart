import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/receipt_model.dart';

class ReceiptService {
  // ✅ Use correct instance of Firebase with explicit databaseURL
  final DatabaseReference _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://bankapp-8deff-default-rtdb.firebaseio.com',
  ).ref();

  /// Save a single receipt to Realtime Database under `/receipts/{id}`
  Future<void> saveReceipt(Receipt receipt) async {
    try {
      await _db.child('receipts').child(receipt.id).set(receipt.toJson());
    } catch (e) {
      throw Exception('Failed to save receipt: $e');
    }
  }

  /// Stream receipts by userId from `/receipts` ordered by child "userId"
  Stream<List<Receipt>> streamReceiptsByUser(String userId) {
    return _db
        .child('receipts')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data == null || data is! Map<dynamic, dynamic>) return [];

          return data.entries.map((entry) {
            final value = Map<String, dynamic>.from(entry.value);
            return Receipt.fromJson(value);
          }).toList();
        });
  }
}
