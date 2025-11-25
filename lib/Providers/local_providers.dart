// lib/providers/local_providers.dart


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/local_models.dart';

final _uuid = const Uuid();

/// ---- EVENTS STATE NOTIFIER ----
/// Manages the list of events and updates the UI accordingly.
class EventsNotifier extends StateNotifier<List<Event>> {
  EventsNotifier([List<Event>? initial]) : super(initial ?? _initialEvents());

  /// Start with an empty list so the UI shows the "no events yet" message.
  static List<Event> _initialEvents() {
    return []; // No events initially
  }

  /// Add a new event to the top of the list (most recent first)
  void addEvent({
    required String title,
    required String date,
    required String description,
  }) {
    final newEvent = Event(
      id: _uuid.v4(),
      title: title,
      date: date,
      description: description,
    );
    state = [newEvent, ...state];
  }

  /// Remove an event by its ID
  void removeEvent(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  /// Update an existing event
  void updateEvent(Event updated) {
    state = state.map((e) => e.id == updated.id ? updated : e).toList();
  }

  /// Replace full list (useful when syncing from Firebase or an API)
  void setEvents(List<Event> events) {
    state = [...events];
  }
}

/// ---- PROVIDERS ----
/// Main provider for managing the event list.
final eventsProvider = StateNotifierProvider<EventsNotifier, List<Event>>((ref) {
  return EventsNotifier();
});

/// Computed provider for the most recent event.
/// Returns one event if available, otherwise an empty list (UI will show fallback message).
final recentEventsProvider = Provider<List<Event>>((ref) {
  final allEvents = ref.watch(eventsProvider);

  if (allEvents.isEmpty) {
    // No events available — return empty list so the UI can show message
    return [];
  }

  // Return only the most recent event
  return allEvents.take(1).toList();
});
/// StateNotifier to hold the last read Quran verse
class LastReadQuranNotifier extends StateNotifier<QuranVerse?> {
  LastReadQuranNotifier([super.initial]);

  /// Set the last read verse
  void setLastRead(QuranVerse verse) => state = verse;

  /// Clear the last read verse
  void clear() => state = null;
}

/// Provider to access the last read verse anywhere
final lastReadQuranProvider =
    StateNotifierProvider<LastReadQuranNotifier, QuranVerse?>(
  (ref) => LastReadQuranNotifier(),
);


