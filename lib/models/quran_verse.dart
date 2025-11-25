// lib/models/quran_verse.dart


class QuranVerse {
  final int surahNumber;
  final int verseNumber;
  final String surahName;
  final String arabicText;
  final String translation;
  final String? audioUrl;

  QuranVerse({
    required this.surahNumber,
    required this.verseNumber,
    required this.surahName,
    required this.arabicText,
    required this.translation,
    this.audioUrl,
  });

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'verseNumber': verseNumber,
        'surahName': surahName,
        'arabicText': arabicText,
        'translation': translation,
        'audioUrl': audioUrl,
      };

  /// Expects map shape like an ayah entry from alquran.cloud
  factory QuranVerse.fromJson(Map<String, dynamic> map) {
    final surahData = map['surah'];
    final surahNumber = surahData is Map
        ? (surahData['number'] as num?)?.toInt() ?? (map['surahNumber'] ?? 0)
        : (map['surahNumber'] ?? 0);
    final verseNumber = map['numberInSurah'] ??
        map['number'] ??
        0; // fallback if key missing

    return QuranVerse(
      surahNumber: (surahNumber is num) ? surahNumber.toInt() : 0,
      verseNumber: (verseNumber is num)
          ? verseNumber.toInt()
          : int.tryParse('$verseNumber') ?? 0,
      surahName: surahData is Map
          ? (surahData['englishName'] ?? surahData['name'] ?? '').toString()
          : (map['surahName'] ?? '').toString(),
      arabicText: map['text']?.toString() ?? '',
      translation: map['translation']?.toString() ?? '',
      audioUrl: map['audio']?.toString() ??
          map['audioUrl']?.toString() ??
          map['audio_url']?.toString(),
    );
  }

  @override
  String toString() =>
      'QuranVerse(surah:$surahNumber, ayah:$verseNumber, name:$surahName)';
}
