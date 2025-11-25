// lib/models/local_models.dart

class Event {
  final String id;
  final String title;
  final String date; // keep as string for display; switch to DateTime if you want
  final String description;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
  });

  Event copyWith({
    String? id,
    String? title,
    String? date,
    String? description,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }
}

/// Model for a Quran verse
class QuranVerse {
  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final String arabic;
  final String translation;

  QuranVerse({
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.arabic,
    required this.translation,
  });

  /// Convert to map for storage (optional)
  Map<String, dynamic> toMap() => {
        'surahNumber': surahNumber,
        'surahName': surahName,
        'verseNumber': verseNumber,
        'arabic': arabic,
        'translation': translation,
      };

  /// Create from map (optional)
  factory QuranVerse.fromMap(Map<String, dynamic> map) => QuranVerse(
        surahNumber: map['surahNumber'],
        surahName: map['surahName'],
        verseNumber: map['verseNumber'],
        arabic: map['arabic'],
        translation: map['translation'],
      );
}

