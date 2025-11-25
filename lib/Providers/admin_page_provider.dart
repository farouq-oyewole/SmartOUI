// lib/providers/admin_provider.dart
import 'package:bank_app/Providers/credit_score_provider.dart';
import 'package:bank_app/Providers/events_provider.dart';
import 'package:bank_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminProvider = Provider<AdminController>((ref) {
  return AdminController(ref);
});

class AdminController {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminController(this.ref);

  /// Add a new event (available for all users)
  Future<void> addEvent({
    required String title,
    required DateTime date,
    required int points,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newEvent = Event(
      id: id,
      name: title,
      date: date,
      points: points,
      attended: false,
    );

    // Add event directly to Firestore via EventsNotifier
    await ref.read(eventsProvider.notifier).addEvent(event: newEvent);
  }

  /// Edit an existing event (real-time for all users)
  Future<void> editEvent({
    required String id,
    String? name,
    DateTime? date,
    int? points,
  }) async {
    await ref.read(eventsProvider.notifier).editEvent(
      id: id,
      name: name,
      date: date,
      points: points,
    );
  }

  /// Delete an event
  Future<void> deleteEvent(String id) async {
    await ref.read(eventsProvider.notifier).deleteEvent(id: id);
  }

  /// Generate a new attendance code for an event
  Future<void> generateCode(String eventId) async {
    await ref.read(eventsProvider.notifier).generateCode(id: eventId);
  }

  /// Add bonus points to a user's credit score
  Future<void> addPoints(AppUser user, int amount) async {
    // Update local state
    final current = ref.read(creditScoreProvider);
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    ref.read(creditScoreProvider.notifier).state = current + amount;

    // Update Firestore
    await _firestore.collection('users').doc(user.id).update({
      'creditScore': FieldValue.increment(amount),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Stream all app users for live updates
  Stream<List<AppUser>> streamAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppUser(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phoneNumber: data['phoneNumber'],
          transactionPin: data['transactionPin'],
          profileImage: data['profileImage'],
          photoUrl: data['photoUrl'],
          photoFilePath: data['photoFilePath'],
          creditScore: (data['creditScore'] ?? 0).toInt(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: UserStatus.values.firstWhere(
            (e) => e.name == data['status'],
            orElse: () => UserStatus.active,
          ),
          accountTypes: List<String>.from(data['accountTypes'] ?? ['member']),
          preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
          securitySettings: SecuritySettings.fromMap(data['securitySettings'] ?? {}),
        );
      }).toList();
    });
  }

  Future<List<AppUser>> fetchAllUsers({int limit = 200}) async {
    try {
      final query = _firestore.collection('users').limit(limit);
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }
}
