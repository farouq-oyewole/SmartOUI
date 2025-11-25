// lib/Pages/quran_page.dart
// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'surah_detail_page.dart';

class QuranPage extends ConsumerStatefulWidget {
  const QuranPage({super.key});

  @override
  _QuranPageState createState() => _QuranPageState();
}

class _QuranPageState extends ConsumerState<QuranPage> {
  late Future<List<Map<String, dynamic>>> _surahsFuture;

  @override
  void initState() {
    super.initState();
    _surahsFuture = _fetchSurahList();
  }

  Future<List<Map<String, dynamic>>> _fetchSurahList() async {
    final url = Uri.parse('https://api.alquran.cloud/v1/surah');
    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load surah list (status ${resp.statusCode})');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map<Map<String, dynamic>>((e) {
      return {
        'number': e['number'] ?? 0,
        'englishName': e['englishName'] ?? '',
        'name': e['name'] ?? '',
        'englishNameTranslation': e['englishNameTranslation'] ?? '',
        'numberOfAyahs': e['numberOfAyahs'] ?? 0,
        'revelationType': e['revelationType'] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _surahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 3));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No surahs available.'));
          }

          final surahs = snapshot.data!;
          final green = Colors.green.shade700;

          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: surahs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildHeader(green),
                  );
                }

                final surah = surahs[index - 1];
                final name = surah['englishName'] ?? '';
                final arabicName = surah['name'] ?? '';
                final number = surah['number'] ?? 0;
                final revelationType = surah['revelationType'] ?? '';
                final ayahs = surah['numberOfAyahs'] ?? 0;

                return _buildSurahCard(
                  context,
                  surahNumber: number,
                  englishName: name,
                  arabicName: arabicName,
                  revelationType: revelationType,
                  totalAyahs: ayahs,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurahDetailPage(
                          surahNumber: number,
                          surahName: name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Color green) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [green.withOpacity(0.85), green.withOpacity(0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Text(
            'List of Surahs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tap any Surah to read or listen to its recitation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 12),
          Text(
            '﷽',
            style: TextStyle(
              fontSize: 34,
              color: Colors.white,
              fontFamily: 'Amiri',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahCard(
    BuildContext context, {
    required int surahNumber,
    required String englishName,
    required String arabicName,
    required String revelationType,
    required int totalAyahs,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final green = Colors.green.shade700;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: green.withOpacity(0.15),
              radius: 22,
              child: Text(
                surahNumber.toString(),
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    englishName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$revelationType • $totalAyahs verses",
                    style: TextStyle(
                      color:
                          isDark ? Colors.white70 : Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              arabicName,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Amiri',
                color: green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
