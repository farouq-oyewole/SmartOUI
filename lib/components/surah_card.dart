// lib/widgets/surah_card.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class SurahCard extends StatelessWidget {
  final int surahNumber;
  final String englishName;
  final String arabicName;
  final String revelationType;
  final int totalAyahs;
  final bool isDark;
  final VoidCallback onTap;

  const SurahCard({
    super.key,
    required this.surahNumber,
    required this.englishName,
    required this.arabicName,
    required this.revelationType,
    required this.totalAyahs,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            ),
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
                      color: isDark ? Colors.white70 : Colors.grey[700],
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
