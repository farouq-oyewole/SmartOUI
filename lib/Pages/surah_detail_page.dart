// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, deprecated_member_use, unused_field

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class SurahDetailPage extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailPage({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  _SurahDetailPageState createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _versesFuture;
  final AudioPlayer _player = AudioPlayer();
  bool _isSurahPlaying = false;
  bool _isSinglePlaying = false;
  int? _currentPlayingAyahNumber;
  ConcatenatingAudioSource? _currentPlaylist;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _versesFuture = _fetchSurahVersesWithTranslation(widget.surahNumber);
    WidgetsBinding.instance.addObserver(this);

    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });

    _player.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _totalDuration = dur);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  /// Fetch both Arabic verses and English translation
  Future<List<Map<String, dynamic>>> _fetchSurahVersesWithTranslation(int surahNumber) async {
    final arabicUrl = Uri.parse('https://api.alquran.cloud/v1/surah/$surahNumber/ar.alafasy');
    final englishUrl = Uri.parse('https://api.alquran.cloud/v1/surah/$surahNumber/en.sahih');

    final arabicResp = await http.get(arabicUrl);
    final englishResp = await http.get(englishUrl);

    if (arabicResp.statusCode != 200 || englishResp.statusCode != 200) {
      throw Exception('Failed to load Surah data');
    }

    final arabicBody = jsonDecode(arabicResp.body);
    final englishBody = jsonDecode(englishResp.body);

    final arabicAyahs = (arabicBody['data']['ayahs'] as List).cast<Map<String, dynamic>>();
    final englishAyahs = (englishBody['data']['ayahs'] as List).cast<Map<String, dynamic>>();

    List<Map<String, dynamic>> verses = [];
    for (int i = 0; i < arabicAyahs.length; i++) {
      verses.add({
        'numberInSurah': arabicAyahs[i]['numberInSurah'] ?? 0,
        'text': arabicAyahs[i]['text'] ?? '',
        'audio': arabicAyahs[i]['audio'] ?? '',
        'translation': englishAyahs.length > i ? englishAyahs[i]['text'] ?? '' : '',
      });
    }

    return verses;
  }

  Future<void> _playSingleAyah(String audioUrl, int ayahNumber) async {
    await _player.stop();
    _currentPlaylist = null;
    if (audioUrl.isEmpty) return;

    setState(() {
      _isSinglePlaying = true;
      _isSurahPlaying = false;
      _currentPlayingAyahNumber = ayahNumber;
    });

    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      await _player.play();
      await _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed || !s.playing,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSinglePlaying = false;
          _currentPlayingAyahNumber = null;
        });
      }
    }
  }

  Future<void> _playEntireSurah(List<Map<String, dynamic>> verses) async {
    await _player.stop();
    setState(() {
      _isSurahPlaying = true;
      _isSinglePlaying = false;
      _currentPlayingAyahNumber = null;
    });

    final sources = <AudioSource>[];
    final ayahNumbers = <int>[];
    for (var v in verses) {
      final audioUrl = v['audio'] ?? '';
      if (audioUrl.toString().isNotEmpty) {
        sources.add(AudioSource.uri(Uri.parse(audioUrl)));
        ayahNumbers.add(v['numberInSurah'] ?? 0);
      }
    }

    _currentPlaylist = ConcatenatingAudioSource(children: sources);
    await _player.setAudioSource(_currentPlaylist!);
    await _player.play();

    _player.currentIndexStream.listen((i) {
      if (mounted && i != null && i < ayahNumbers.length) {
        setState(() => _currentPlayingAyahNumber = ayahNumbers[i]);
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && mounted) {
        setState(() {
          _isSurahPlaying = false;
          _currentPlayingAyahNumber = null;
        });
      }
    });
  }

  Future<void> _stopPlayback() async {
    await _player.stop();
    setState(() {
      _isSurahPlaying = false;
      _isSinglePlaying = false;
      _currentPlayingAyahNumber = null;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade700;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          widget.surahName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [green.withOpacity(0.9), green.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _versesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: Text('No verses found.'));
          final verses = snapshot.data!;

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(top: 100, left: 12, right: 12, bottom: 130),
                itemCount: verses.length,
                itemBuilder: (context, index) {
                  final v = verses[index];
                  final ayahNum = v['numberInSurah'] ?? 0;
                  final isPlaying = _currentPlayingAyahNumber == ayahNum;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: isPlaying
                            ? [green.withOpacity(0.2), Colors.greenAccent.withOpacity(0.1)]
                            : [isDark ? Colors.grey[900]! : Colors.white, isDark ? Colors.black : Colors.grey[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isPlaying ? green.withOpacity(0.4) : Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(2, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          v['text'] ?? '',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'KFGQPC Uthmanic Script HAFS', // authentic Qur'an font
                            fontSize: 28,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 2.2,
                            shadows: isPlaying
                                ? [Shadow(color: green.withOpacity(0.6), blurRadius: 10)]
                                : [],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          v['translation'] ?? '',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white70 : Colors.grey[800],
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ayah $ayahNum',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                color: green,
                                size: 28,
                              ),
                              onPressed: () async {
                                if (isPlaying) {
                                  await _stopPlayback();
                                } else {
                                  await _stopPlayback();
                                  await _playSingleAyah(v['audio'] ?? '', ayahNum);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              /// Spotify-style playback bar
              if (_isSurahPlaying)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [green.withOpacity(0.95), Colors.greenAccent.withOpacity(0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: green.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.surahName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: _stopPlayback,
                              icon: const Icon(Icons.stop_circle, color: Colors.white, size: 28),
                            )
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _currentPosition.inSeconds.toDouble().clamp(0, _totalDuration.inSeconds.toDouble()),
                            min: 0,
                            max: _totalDuration.inSeconds.toDouble() > 0 ? _totalDuration.inSeconds.toDouble() : 1,
                            onChanged: (v) => _player.seek(Duration(seconds: v.toInt())),
                            activeColor: Colors.white,
                            inactiveColor: Colors.white30,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_currentPosition),
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(_formatDuration(_totalDuration),
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                    label: const Text(
                      'Play Entire Surah',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    onPressed: () async {
                      await _stopPlayback();
                      _playEntireSurah(verses);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
