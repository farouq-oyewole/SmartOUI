// lib/providers/events_provider.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Event {
  final String id;
  final String name;
  final DateTime date;
  final int points;
  final String? code;
  final DateTime? codeExpiry;
  final bool attended;

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.points,
    this.code,
    this.codeExpiry,
    this.attended = false,
  });

  Event copyWith({
    String? name,
    DateTime? date,
    int? points,
    String? code,
    DateTime? codeExpiry,
    bool? attended,
  }) {
    return Event(
      id: id,
      name: name ?? this.name,
      date: date ?? this.date,
      points: points ?? this.points,
      code: code ?? this.code,
      codeExpiry: codeExpiry ?? this.codeExpiry,
      attended: attended ?? this.attended,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'date': date.toIso8601String(),
        'points': points,
        'code': code,
        'codeExpiry': codeExpiry?.toIso8601String(),
        'attended': attended,
      };

  factory Event.fromMap(Map<String, dynamic> map) => Event(
        id: map['id'] as String,
        name: map['name'] as String,
        date: DateTime.parse(map['date'] as String),
        points: map['points'] as int,
        code: map['code'] as String?,
        codeExpiry: map['codeExpiry'] != null
            ? DateTime.parse(map['codeExpiry'])
            : null,
        attended: map['attended'] as bool? ?? false,
      );
}

/// Firestore-backed EventsNotifier
class EventsNotifier extends StateNotifier<List<Event>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final Stream<List<Event>> _eventsStream;

  EventsNotifier() : super([]) {
    _eventsStream = _firestore.collection('events').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Event.fromMap(doc.data())).toList(),
        );

    // Listen to Firestore changes in real-time
    _eventsStream.listen((eventList) {
      state = eventList;
    });
  }

  /// Add new event (named parameter)
  Future<void> addEvent({required Event event}) async {
    await _firestore.collection('events').doc(event.id).set(event.toMap());
  }

  /// Edit existing event
  Future<void> editEvent({
    required String id,
    String? name,
    DateTime? date,
    int? points,
  }) async {
    final docRef = _firestore.collection('events').doc(id);
    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (date != null) updateData['date'] = date.toIso8601String();
    if (points != null) updateData['points'] = points;

    if (updateData.isNotEmpty) {
      await docRef.update(updateData);
    }
  }

  /// Delete event
  Future<void> deleteEvent({required String id}) async {
    await _firestore.collection('events').doc(id).delete();
  }

  /// Generate 6-digit attendance code valid for 10 minutes
  Future<void> generateCode({required String id}) async {
    final randomCode = (Random().nextInt(900000) + 100000).toString();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    await _firestore
        .collection('events')
        .doc(id)
        .update({'code': randomCode, 'codeExpiry': expiry.toIso8601String()});
  }

  /// Mark attendance if code is valid
  Future<bool> attendEvent(String id, String enteredCode) async {
    final doc = await _firestore.collection('events').doc(id).get();
    if (!doc.exists) return false;

    final event = Event.fromMap(doc.data()!);
    if (event.code == enteredCode &&
        event.codeExpiry != null &&
        DateTime.now().isBefore(event.codeExpiry!)) {
      await _firestore.collection('events').doc(id).update({'attended': true});
      return true;
    }
    return false;
  }

  /// Reset all attendance
  Future<void> resetAttendance() async {
    final snapshot = await _firestore.collection('events').get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({'attended': false});
    }
  }
}

/// Provide a live stream of events
final eventsProvider =
    StateNotifierProvider<EventsNotifier, List<Event>>((ref) {
  return EventsNotifier();
});
