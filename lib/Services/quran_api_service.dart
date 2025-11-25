// lib/services/quran_api_service.dart
// Quran data fetching service with static methods for global access.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QuranApiService {
  static const String _base = 'https://api.alquran.cloud/v1';

  /// Fetch all surahs from AlQuran API.
  static Future<List<Map<String, dynamic>>> fetchAllSurahs() async {
    final url = Uri.parse('$_base/surah');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List surahs = data['data'];
      return surahs.map((s) => Map<String, dynamic>.from(s)).toList();
    } else {
      throw Exception('Failed to load surahs: ${response.statusCode}');
    }
  }

  /// Fetch all verses for a specific surah with arabic + translation + audio.
  static Future<List<Map<String, dynamic>>> fetchSurahVerses(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'surah_$surahNumber';

    try {
      final arabicRes = await http.get(Uri.parse('$_base/surah/$surahNumber/quran-uthmani'));
      final translationRes = await http.get(Uri.parse('$_base/surah/$surahNumber/en.sahih'));
      final audioRes = await http.get(Uri.parse('$_base/surah/$surahNumber/ar.alafasy'));

      if (arabicRes.statusCode == 200 &&
          translationRes.statusCode == 200 &&
          audioRes.statusCode == 200) {
        final arabicData = json.decode(arabicRes.body)['data']['ayahs'] as List;
        final translationData = json.decode(translationRes.body)['data']['ayahs'] as List;
        final audioData = json.decode(audioRes.body)['data']['ayahs'] as List;

        final verses = List.generate(arabicData.length, (i) {
          final arabic = arabicData[i]['text'] ?? '';
          final translation = translationData[i]['text'] ?? '';
          final audioUrl = audioData[i]['audio'] ?? '';
          return {
            'arabic': arabic,
            'translation': translation,
            'audio': audioUrl,
          };
        });

        // Cache result
        await prefs.setString(cacheKey, json.encode(verses));
        return verses;
      } else {
        throw Exception('API returned invalid status codes.');
      }
    } catch (e) {
      // fallback to cache
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final cachedData = json.decode(cached);
        return List<Map<String, dynamic>>.from(cachedData);
      }
      throw Exception('Failed to fetch surah verses: $e');
    }
  }
}
