import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps track of which prayer reminders are enabled or muted.
/// The key is the prayer name (e.g. "Fajr", "Dhuhr", etc.)
final reminderStateProvider =
    StateNotifierProvider<ReminderNotifier, Map<String, bool>>((ref) {
  return ReminderNotifier();
});

class ReminderNotifier extends StateNotifier<Map<String, bool>> {
  ReminderNotifier()
      : super({
          'Fajr': true,
          'Dhuhr': true,
          'Asr': true,
          'Maghrib': true,
          'Isha': true,
          'Iftar': true,
        });

  void toggle(String prayerName) {
    state = {
      ...state,
      prayerName: !(state[prayerName] ?? true),
    };
  }
}
