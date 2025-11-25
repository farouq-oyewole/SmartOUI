// lib/Pages/prayer_times_page.dart
// ignore_for_file: file_names, unnecessary_null_comparison, deprecated_member_use, unused_result, unused_local_variable

import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import providers - make sure these files exist
import '../providers/coordinate_provider.dart';
import '../providers/reverse_geocode_provider.dart';
import '../providers/prayer_times_provider.dart';
import '../providers/reminder_state_provider.dart';

class PrayerTimesPage extends ConsumerStatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  ConsumerState<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends ConsumerState<PrayerTimesPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _clockTimer;
  bool _snackbarShown = false;
  bool _adhanPlayed = false;

  // Fade controller for the header / circular fade-in
  late final AnimationController _headerFadeController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.96,
      upperBound: 1.03,
    )..repeat(reverse: true);

    // Tick to refresh every second (updates countdown)
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Header & ring fade-in (runs once on init, and when app resumes)
    _headerFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _clockTimer?.cancel();
    _audioPlayerDispose();
    _headerFadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Fade-in again when user returns to app / reopens this page (not every second)
    if (state == AppLifecycleState.resumed && mounted) {
      _headerFadeController
        ..reset()
        ..forward();
    }
  }

  void _audioPlayerDispose() {
    try {
      _audioPlayer.dispose();
    } catch (_) {}
  }

  Future<void> _playAdhan() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/adhan.mp3'));
    } catch (_) {}
  }

  String _formatLarge(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  Color get mssnGreen => const Color(0xFF0B6B3D);

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final cleaned = value.split(' ').first.trim();
      final parts = cleaned.split(':');
      if (parts.length >= 2) {
        final now = DateTime.now();
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        return DateTime(now.year, now.month, now.day, h, m);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final coordsAsync = ref.watch(coordinatesProvider);
    final reverseGeo = ref.watch(reverseGeocodeProvider);
    final prayerAsync = ref.watch(prayerTimesProvider);
    final now = DateTime.now();

    coordsAsync.whenData((pos) {
      if (pos.isFallback && !_snackbarShown) {
        _snackbarShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not fetch your exact location, using Osun State (fallback)',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        });
      }
    });

    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final headerGradient = LinearGradient(
      colors: [mssnGreen.withOpacity(1.0), mssnGreen.withOpacity(0.92)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: prayerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _errorWidget(e.toString()),
        data: (timesModel) {
          final raw = timesModel.timings;
          final Map<String, DateTime> ordered = {};

          for (final k in ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
            final dt = _toDateTime(raw[k]);
            if (dt != null) ordered[k] = dt;
          }

          // Ensure keys exist (fallback to now)
          for (final k in ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
            ordered.putIfAbsent(k, () => DateTime(now.year, now.month, now.day, now.hour, now.minute));
          }

          String currentPrayer = 'None';
          String nextPrayer = 'None';
          DateTime? nextPrayerTime;

          final listOrder = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
          for (int i = 0; i < listOrder.length; i++) {
            final name = listOrder[i];
            final dt = ordered[name]!;
            if (dt.isAfter(now)) {
              nextPrayer = name;
              nextPrayerTime = dt;
              if (i > 0) currentPrayer = listOrder[i - 1];
              break;
            } else {
              currentPrayer = name;
            }
          }

          nextPrayerTime ??= ordered['Fajr']!.add(const Duration(days: 1));
          final countdown = nextPrayerTime.difference(now);

          if (countdown.inSeconds <= 0 && !_adhanPlayed) {
            _adhanPlayed = true;
            _playAdhan();
          } else if (countdown.inSeconds > 0) {
            _adhanPlayed = false;
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(coordinatesProvider.future);
              await ref.refresh(prayerTimesProvider.future);
              await ref.refresh(reverseGeocodeProvider.future);
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Top header with animated fade (uses same green in both modes)
                SafeArea(
                  top: true,
                  bottom: false,
                  child: AnimatedBuilder(
                    animation: _headerFadeController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _headerFadeController.value,
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: headerGradient,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2.0),
                            child: Center(
                              child: Text(
                                'Prayer Times',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),

                          // Circular countdown stack (ring centered in the green header)
                          SizedBox(
                            height: 300,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Circular countdown (ring). uses lemon yellow inside widget.
                                CircularCountdownWidget(
                                  progress: _arcProgress(ordered, now),
                                  countdown: countdown,
                                  nextPrayer: nextPrayer,
                                  // color argument no longer used for adaptive color - ring uses lemon color internally
                                  color: Colors.amberAccent,
                                ),

                                // location — slightly below the ring, larger/more visible
                                Positioned(
                                  bottom: 10,
                                  child: reverseGeo.when(
                                    data: (loc) => Text(
                                      loc,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    loading: () => const Text(
                                      'Detecting location...',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    error: (_, __) => const Text(
                                      'Location unavailable',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // small spacing between header and prayer cards
                const SizedBox(height: 12),

                // Prayer cards grid
                _buildPrayerCards(context, ordered, now),

                const SizedBox(height: 16),

                // Reminders section (colors adaptive inside method)
                _buildRemindersSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  double _arcProgress(Map<String, DateTime> ordered, DateTime now) {
    final listOrder = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    DateTime? prev;
    DateTime? next;

    for (int i = 0; i < listOrder.length; i++) {
      final dt = ordered[listOrder[i]]!;
      if (dt.isAfter(now)) {
        next = dt;
        prev = i > 0 ? ordered[listOrder[i - 1]] : dt.subtract(const Duration(hours: 6));
        break;
      }
    }

    if (next == null || prev == null) return 0.0;
    final total = next.difference(prev).inSeconds;
    final elapsed = now.difference(prev).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

 Widget _buildPrayerCards(
    BuildContext context, Map<String, DateTime> ordered, DateTime now) {
  final prayers = ordered.entries.toList();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 84,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: prayers.length,
      itemBuilder: (_, i) {
        final name = prayers[i].key;
        final time = prayers[i].value;
        final isNext = time.isAfter(now) &&
            (i == 0 || prayers[i - 1].value.isBefore(now));

        // Card background adapts: white in light mode, dark in dark mode
        final cardBg = isNext
            ? mssnGreen.withOpacity(0.12)
            : (isDark ? const Color(0xFF1A1A1A) : Colors.white);

        final borderColor = isNext
            ? const Color(0xFFFFEB3B)
            : (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

        // 🟡 Updated logic for text colors:
        final textColor = isNext
            ? (isDark ? const Color(0xFFFFEB3B) : Colors.black)
            : (isDark ? Colors.white : Colors.black87);

        final subTextColor = isNext
            ? (isDark ? const Color(0xFFFFEB3B) : Colors.black54)
            : (isDark ? Colors.white70 : Colors.black54);

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isNext ? 1.6 : 0.8,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatLarge(time),
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}


  Widget _buildRemindersSection() {
    return Consumer(
      builder: (context, ref, _) {
        final reminders = ref.watch(reminderStateProvider);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Reminders',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...reminders.entries.map((entry) {
              final prayer = entry.key;
              final enabled = entry.value;
              return SwitchListTile(
                title: Text(
                  prayer,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                activeColor: const Color(0xFFFFEB3B), // lemon yellow
                value: enabled,
                onChanged: (val) {
                  ref.read(reminderStateProvider.notifier).toggle(prayer);
                },
              );
            }),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _errorWidget(String e) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading data: $e',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
}
// --------------------------------------------------------------
// 🕋 CIRCULAR COUNTDOWN WIDGET
// --------------------------------------------------------------

class CircularCountdownWidget extends StatefulWidget {
  final double progress;
  final Duration countdown;
  final String nextPrayer;
  final Color color;

  const CircularCountdownWidget({
    super.key,
    required this.progress,
    required this.countdown,
    required this.nextPrayer,
    required this.color,
  });

  @override
  State<CircularCountdownWidget> createState() =>
      _CircularCountdownWidgetState();
}

class _CircularCountdownWidgetState extends State<CircularCountdownWidget>
    with TickerProviderStateMixin {
  late  AnimationController _tickController;
  late  AnimationController _fadeController;
  bool _fadePlayed = false;

  @override
  void initState() {
    super.initState();

    // Rotating tick marks controller
    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Fade-in animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Play fade-in once on entry
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(covariant CircularCountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only trigger fade-in once when widget first appears or is rebuilt after tab switch
    if (!_fadePlayed) {
      _fadePlayed = true;
      _fadeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tickController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lemonYellow = const Color(0xFFFFE066);

    final hours = widget.countdown.inHours.remainder(24);
    final minutes = widget.countdown.inMinutes.remainder(60);
    final seconds = widget.countdown.inSeconds.remainder(60);
    final timeText =
        "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return FadeTransition(
      opacity: _fadeController,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: widget.progress),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return AnimatedBuilder(
            animation: _tickController,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle rotating tick marks
                  CustomPaint(
                    painter: TickMarkPainter(rotation: _tickController.value),
                    size: const Size(230, 230),
                  ),

                  // Progress ring (lemon yellow)
                  CustomPaint(
                    painter: CircularTimerPainter(
                      progress: value,
                      color: lemonYellow,
                    ),
                    size: const Size(220, 220),
                  ),

                  // Center text
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.nextPrayer,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Remaining",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------------
// 🎨 CUSTOM PAINTERS
// --------------------------------------------------------------

class CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularTimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 10.0;
    final radius = (size.width / 2) - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final startAngle = -pi / 2;
    final sweep = 2 * pi * progress;

    final bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.8), color],
        startAngle: 0,
        endAngle: 2 * pi,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Background circle
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircularTimerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class TickMarkPainter extends CustomPainter {
  final double rotation;
  TickMarkPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final tickPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(2 * pi * rotation);

    for (int i = 0; i < 60; i++) {
      final angle = (2 * pi / 60) * i;
      final inner = Offset(radius - 8, 0);
      final outer = Offset(radius - 2, 0);
      canvas.save();
      canvas.rotate(angle);
      canvas.drawLine(inner, outer, tickPaint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TickMarkPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
