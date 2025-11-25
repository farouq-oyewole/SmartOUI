// lib/pages/home_page.dart
// Full complete HomePage that uses the models & providers above.
// Replace your existing HomePage with this file (adjust import paths if needed).

// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:bank_app/Providers/auth_provider.dart';
import 'package:bank_app/Providers/last_read_quran_provider.dart';

import 'package:bank_app/Providers/notification_provider.dart';
import 'package:bank_app/Providers/recent_events_provider.dart';
import 'package:bank_app/components/animated_credit_card.dart';
import 'package:bank_app/components/recent_events_section.dart';
import 'package:bank_app/models/user_model.dart';
import 'package:bank_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final ProviderSubscription<int> _notificationSub;

  @override
  void initState() {
    super.initState();
    // Listen to unread notifications and play a sound when it increases
    _notificationSub = ref.listenManual<int>(
      unreadNotificationsCountProvider,
      (previous, next) {
        if ((previous ?? 0) < next) {
          _playNotificationSound();
        }
      },
    );
  }

  @override
  void dispose() {
    _notificationSub.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint('Notification play error: $e');
    }
  }

  Future<void> _pickAndUpdateImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        final base64String = base64Encode(bytes);

        // Update via your auth notifier (assumes updateUserPhoto exists and accepts base64)
        await ref.read(authNotifierProvider.notifier).updateUserPhoto(
              imageData: base64String,
              isLocalFile: true,
            );

        ref.invalidate(currentAppUserProvider);
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      ref.read(notificationProvider.notifier).showError('Image Error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? appUser = ref.watch(currentAppUserProvider);
    final bool isDarkMode = ref.watch(isDarkModeProvider);
    final int unreadCount = ref.watch(unreadNotificationsCountProvider);

    // ignore: unused_local_variable
    final recentEvents = ref.watch(recentEventProvider);
    ref.watch(lastReadQuranProvider);
    ref.watch(recentEventProvider);

    final Color surfaceBg = isDarkMode ? Colors.grey[900]! : Colors.grey[50]!;
    final Color primary = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: surfaceBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // refresh user & providers if needed
            ref.invalidate(currentAppUserProvider);
            // no-op: events are local; but you could also re-fetch from remote here
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context, appUser, unreadCount),
              const SizedBox(height: 20),

              // Animated credit card (existing component)
              const AnimatedCreditCard(),
              const SizedBox(height: 20),

              // Action buttons (two rows, two per row)
              _buildActionsSection(context, primary, isDarkMode),
              const SizedBox(height: 24),

              // Recent Events (uses eventsProvider -> recentEventsProvider)
            RecentEventsSection(
  onSeeAll: () {
    Navigator.pushNamed(context, '/events');
  },
  limit: 1, // ✅ Only one event shown
),

             const SizedBox(height: 18),

              // Last Read Quran Verse section
              _buildLastReadQuranSection(context, isDarkMode),


              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ----- HEADER -----
  Widget _buildHeader(BuildContext context, AppUser? appUser, int notifications) {
    final bool isDark = ref.watch(isDarkModeProvider);
    final textColor = isDark ? Colors.white : Colors.black87;

    ImageProvider avatar;
    if (appUser?.photoUrl?.isNotEmpty ?? false) {
      avatar = MemoryImage(base64Decode(appUser!.photoUrl!));
    } else {
      avatar = const AssetImage('assets/images/profile.png');
    }

    return Row(
      children: [
        GestureDetector(
          onTap: _pickAndUpdateImage,
          child: CircleAvatar(
            radius: 28,
            backgroundImage: avatar,
            backgroundColor: Colors.transparent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'As-salamu alaykum 👋',
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appUser?.displayName ?? 'Member',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              icon: Icon(
                Icons.notifications_none_rounded,
                size: 28,
                color: isDark ? Colors.white : Colors.black54,
              ),
            ),
            if (notifications > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.3),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    notifications > 9 ? '9+' : notifications.toString(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ----- ACTIONS (two rows, two per row) -----
  Widget _buildActionsSection(BuildContext context, Color primary, bool isDark) {
  final double screenWidth = MediaQuery.of(context).size.width;
  final double cardWidth = (screenWidth - 56) / 2; // slightly smaller for spacing
  final Color cardColor = isDark ? Colors.grey[850]! : Colors.white;

  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionCard(
            context,
            width: cardWidth,
            icon: Icons.quiz,
            label: 'Quizzes',
            route: '/quizzes',
            cardColor: cardColor,
            primary: primary,
            isDark: isDark,
          ),
          _actionCard(
            context,
            width: cardWidth,
            icon: Icons.calendar_today,
            label: 'Events',
            route: '/events',
            cardColor: cardColor,
            primary: primary,
            isDark: isDark,
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionCard(
            context,
            width: cardWidth,
            icon: Icons.menu_book,
            label: 'Quran',
            route: '/quran',
            cardColor: cardColor,
            primary: primary,
            isDark: isDark,
          ),
          _actionCard(
            context,
            width: cardWidth,
            icon: Icons.notifications,
            label: 'Reminders',
            route: '/reminders',
            cardColor: cardColor,
            primary: primary,
            isDark: isDark,
          ),
        ],
      ),
    ],
  );
}

Widget _actionCard(
  BuildContext context, {
  required double width,
  required IconData icon,
  required String label,
  required String route,
  required Color cardColor,
  required Color primary,
  required bool isDark,
}) {
  return InkWell(
    onTap: () => Navigator.pushNamed(context, route),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22, // smaller icon bubble
            backgroundColor: primary,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5, // smaller text
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}




  // ----- LAST READ QURAN SECTION -----
Widget _buildLastReadQuranSection(BuildContext context, bool isDark) {
  return Consumer(
    builder: (context, ref, child) {
      // Watch the lastReadQuranProvider
      final lastRead = ref.watch(lastReadQuranProvider);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: isDark ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🟢 HEADER ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.menu_book,
                              color: Colors.green[800], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Last Read Qur’an Verse",
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/quran'),
                        child: Text(
                          "See All",
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 🟡 CONTENT SECTION
                  if (lastRead == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Text(
                        "You haven't read anything yet. Open the Qur’an page to start reading.",
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          fontStyle: FontStyle.italic,
                          fontSize: 15,
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🕌 Surah + Ayah Info
                        Text(
                          "${lastRead.surahName} — Ayah ${lastRead.verseNumber}",
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 🕋 Verse Text
                        Text(
                          lastRead.translation,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
}