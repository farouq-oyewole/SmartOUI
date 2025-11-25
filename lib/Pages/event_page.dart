// lib/pages/events_page.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:bank_app/Providers/events_provider.dart';
import 'package:bank_app/Providers/recent_events_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/credit_score_provider.dart';


class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage>
    with TickerProviderStateMixin {
  late final AnimationController _pageFadeController;
  late final Animation<double> _pageFade;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _pageFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pageFade =
        CurvedAnimation(parent: _pageFadeController, curve: Curves.easeIn);
    _pageFadeController.forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageFadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _promptForCodeAndMark(Event event) async {
    if (event.attended) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You already marked "${event.name}" as attended.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      return;
    }

    final ctrl = TextEditingController();
    final isDark = ref.read(isDarkModeProvider);

    final ok = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: const Text('Enter event code'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Event code'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final entered = ctrl.text.trim();
    if (entered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the event code.')),
      );
      return;
    }

    final success =
        await ref.read(eventsProvider.notifier).attendEvent(event.id, entered);

    if (success) {
      // ✅ Update credit points
      final current = ref.read(creditScoreProvider);
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      ref.read(creditScoreProvider.notifier).state = current + event.points;

      // ✅ Save last attended event to show on home page
      ref.read(recentEventProvider.notifier).setRecentEvent(event);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ You earned ${event.points} points for attending "${event.name}".'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect or expired code.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final pageBg = isDark ? Colors.grey[900] : Colors.grey[50];

    return FadeTransition(
      opacity: _pageFade,
      child: Scaffold(
        backgroundColor: pageBg,
        body: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: isDark ? Colors.white : Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              final t = _glowController.value;
                              final gradient = LinearGradient(
                                begin: Alignment(-1 + t * 2, -1),
                                end: Alignment(1 - t * 2, 1),
                                colors: isDark
                                    ? [
                                        Colors.green.shade700,
                                        Colors.green.shade900
                                      ]
                                    : [
                                        Colors.green.shade300,
                                        Colors.green.shade700
                                      ],
                              );
                              return ShaderMask(
                                shaderCallback: (rect) =>
                                    gradient.createShader(Rect.fromLTWH(
                                        0, 0, rect.width, rect.height)),
                                child: const Text(
                                  'Events',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: events.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No events yet',
                              style: TextStyle(
                                color:
                                    isDark ? Colors.white70 : Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => await Future.delayed(
                              const Duration(milliseconds: 200)),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: events.length,
                            itemBuilder: (ctx, i) =>
                                _buildAnimatedEventCard(events[i], isDark),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedEventCard(Event event, bool isDark) {
    final lightGradient = [Colors.green.shade300, Colors.green.shade700];
    final darkGradient = [Colors.green.shade700, Colors.green.shade900];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final t = _glowController.value;
          final begin = Alignment(-1 + t * 2, -1);
          final end = Alignment(1 - t * 2, 1);

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Container(
              height: 88, // ✅ Fixed height prevents flex overflow
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: begin,
                  end: end,
                  colors: isDark ? darkGradient : lightGradient,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.green.shade200)
                        .withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    minVerticalPadding: 0,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: _buildEventIcon(event),
                    title: Text(
                      event.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat('EEE, d MMM yyyy • h:mma').format(event.date)}  •  ${event.points} pts',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 26,
                          width: 26,
                          child: Checkbox(
                            value: event.attended,
                            onChanged: (_) => _promptForCodeAndMark(event),
                            activeColor: Colors.white,
                            checkColor: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.attended ? 'Attended' : 'Mark',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventIcon(Event event) {
    IconData icon = Icons.event;
    final n = event.name.toLowerCase();
    if (n.contains('forum') || n.contains('sisters')) icon = Icons.group;
    if (n.contains('orientation') || n.contains('freshers')) {
      icon = Icons.school;
    }
    if (n.contains('al-huda') || n.contains('huda') || n.contains('al')) {
      icon = Icons.mosque;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
