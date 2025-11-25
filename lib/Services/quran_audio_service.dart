// lib/services/quran_audio_service.dart
// Handles Quran audio playback (for ayah and full surah).

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class QuranAudioService {
  final AudioPlayer _player = AudioPlayer();

  QuranAudioService();

  /// Play a single ayah by URL
  static Future<void> playAyah(String url) async {
    final player = AudioPlayer();
    try {
      await player.setUrl(url);
      await player.play();
    } catch (e) {
      throw Exception('Error playing ayah: $e');
    }
  }

  /// Play the full surah as concatenated audio from AlQuran API
  static Future<void> playFullSurah(int surahNumber) async {
    final base = 'https://api.alquran.cloud/v1/surah/$surahNumber/ar.alafasy';

    try {
      final response = await http.get(Uri.parse(base));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ayahs = data['data']['ayahs'] as List;

        final audioUrls = ayahs
            .map((a) => a['audio'] as String?)
            .where((a) => a != null && a.isNotEmpty)
            .cast<String>()
            .toList();

        if (audioUrls.isEmpty) throw Exception('No audio found for surah.');

        final player = AudioPlayer();
        final playlist =
            // ignore: deprecated_member_use
            ConcatenatingAudioSource(children: audioUrls.map((u) => AudioSource.uri(Uri.parse(u))).toList());
        await player.setAudioSource(playlist);
        await player.play();
      } else {
        throw Exception('Failed to fetch audio for surah $surahNumber');
      }
    } catch (e) {
      throw Exception('Error playing full surah: $e');
    }
  }

  Future<void> stop() async => _player.stop();
  Future<void> dispose() async => _player.dispose();
}
