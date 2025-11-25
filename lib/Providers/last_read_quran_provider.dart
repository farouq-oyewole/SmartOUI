// lib/providers/last_read_quran_provider.dart
// Riverpod StateNotifier that persists the last-read Qur'an verse using SharedPreferences


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bank_app/models/quran_verse.dart';

final lastReadQuranProvider =
    StateNotifierProvider<LastReadQuranNotifier, QuranVerse?>((ref) {
  return LastReadQuranNotifier();
});

class LastReadQuranNotifier extends StateNotifier<QuranVerse?> {
  static const String _storageKey = 'last_read_quran';

  LastReadQuranNotifier() : super(null) {
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        state = QuranVerse.fromJson(jsonStr as Map<String, dynamic>);
      } else {
        state = null;
      }
    } catch (_) {
      // If anything goes wrong, keep state null (safe fallback)
      state = null;
    }
  }

  /// Sets the last-read verse in memory and persists it.
  Future<void> setLastRead(QuranVerse verse) async {
    state = verse;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, verse.toJson() as String);
    } catch (_) {
      // ignore write failures (app still has in-memory state)
    }
  }

  /// Clears persisted last-read verse and in-memory state.
  Future<void> clear() async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {
      // ignore
    }
  }
}
