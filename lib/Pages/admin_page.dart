// lib/pages/admin_page.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:bank_app/Providers/events_provider.dart';
import 'package:bank_app/Providers/theme_provider.dart';
import 'package:bank_app/models/user_model.dart';
import 'package:bank_app/providers/admin_page_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});
  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final _eventNameController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _eventPointsController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _startCountdownUpdater();
  }

  void _startCountdownUpdater() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _eventNameController.dispose();
    _eventDateController.dispose();
    _eventPointsController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    if (d.isNegative) return 'expired';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showGeneratedCodeDialog(Event event) async {
    final updated = ref.read(eventsProvider).firstWhere((e) => e.id == event.id);
    final code = updated.code;
    final expiry = updated.codeExpiry;
    final isExpired = expiry == null || DateTime.now().isAfter(expiry);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: const Text('Attendance Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (code != null)
              SelectableText(code,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))
            else
              const Text('No code generated'),
            const SizedBox(height: 12),
            Text(
              expiry == null
                  ? 'No expiry'
                  : isExpired
                      ? 'Expired'
                      : 'Expires in ${_formatRemaining(expiry.difference(DateTime.now()))}',
              style: TextStyle(
                  color: isExpired ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (code != null)
              Text('Share this 6-digit code with attendees. Valid for 10 minutes.',
                  style: TextStyle(color: Theme.of(context).hintColor))
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _confirmDelete(Event event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: const Text('Delete Event'),
        content: Text('Delete "${event.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'))
        ],
      ),
    );
    if (ok == true) {
      await ref.read(adminProvider).deleteEvent(event.id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Event deleted')));
    }
  }

  Future<void> _showEditDialog(Event event) async {
    _eventNameController.text = event.name;
    _eventDateController.text = DateFormat('yyyy-MM-dd').format(event.date);
    _eventPointsController.text = event.points.toString();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: const Text('Edit Event'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildTextField(_eventNameController, 'Event Name'),
          const SizedBox(height: 8),
          _buildTextField(_eventDateController, 'Date (yyyy-MM-dd)'),
          const SizedBox(height: 8),
          _buildTextField(_eventPointsController, 'Points', keyboard: TextInputType.number)
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))
        ],
      ),
    );
    if (saved == true) {
      try {
        final newDate = DateTime.parse(_eventDateController.text);
        final newPoints = int.tryParse(_eventPointsController.text) ?? event.points;
        await ref.read(adminProvider).editEvent(
              id: event.id,
              name: _eventNameController.text.trim(),
              date: newDate,
              points: newPoints,
            );
        _eventNameController.clear();
        _eventDateController.clear();
        _eventPointsController.clear();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Event updated')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid date format')));
      }
    }
  }

  Future<void> _generateCodeAndShow(Event event) async {
    await ref.read(adminProvider).generateCode(event.id);
    final updated = ref.read(eventsProvider).firstWhere((e) => e.id == event.id);
    await _showGeneratedCodeDialog(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final admin = ref.read(adminProvider);
    final events = ref.watch(eventsProvider);
    final bgGradient = LinearGradient(
      colors: isDark
          ? [Colors.green.shade900, Colors.black]
          : [Colors.green.shade200, Colors.white],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          Row(children: [
            const Text("Dark Mode", style: TextStyle(fontSize: 14)),
            Switch(
              value: isDark,
              onChanged: (v) => ref.read(themeModeProvider.notifier).toggleTheme(),
              activeColor: Colors.white,
            )
          ])
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(gradient: bgGradient),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 20),
              _buildAddEventCard(context, admin, isDark),
              const SizedBox(height: 30),
              _buildEventsSection(events, isDark),
              const SizedBox(height: 30),
              _buildUsersButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(children: [
      CircleAvatar(radius: 30, backgroundColor: Colors.green[800], child: const Icon(Icons.workspace_premium, color: Colors.white, size: 32)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("MSSN Admin 👑", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        Text("Manage Events • Assign Points", style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 14))
      ])
    ]);
  }

  Widget _buildAddEventCard(BuildContext context, AdminController admin, bool isDark) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      shadowColor: Colors.green.withOpacity(0.28),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📅 Add New Event', style: TextStyle(color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 12),
          _buildTextField(_eventNameController, 'Event Name'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2035));
              if (picked != null) _eventDateController.text = DateFormat('yyyy-MM-dd').format(picked);
            },
            child: AbsorbPointer(child: _buildTextField(_eventDateController, 'Select Date')),
          ),
          const SizedBox(height: 10),
          _buildTextField(_eventPointsController, 'Points', keyboard: TextInputType.number),
          const SizedBox(height: 14),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Event'),
              onPressed: () async {
                if (_eventNameController.text.isEmpty || _eventDateController.text.isEmpty || _eventPointsController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Please fill all fields")));
                  return;
                }
                try {
                  final date = DateTime.parse(_eventDateController.text);
                  final points = int.tryParse(_eventPointsController.text) ?? 0;
                  await admin.addEvent(title: _eventNameController.text.trim(), date: date, points: points);
                  _eventNameController.clear();
                  _eventDateController.clear();
                  _eventPointsController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Event added successfully!")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid date format")));
                }
              },
            ),
          )
        ]),
      ),
    );
  }

  Widget _buildEventsSection(List<Event> events, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('📖 All Events', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 12),
      if (events.isEmpty)
        Center(child: Text("No events yet. Add some!", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontStyle: FontStyle.italic)))
      else
        ...events.map((event) {
          final expiry = event.codeExpiry;
          final remaining = expiry?.difference(DateTime.now());
          final codeVisible = event.code != null && remaining != null && !remaining.isNegative;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: isDark ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              title: Text(event.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(DateFormat('EEE, d MMM yyyy – h:mm a').format(event.date), style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700])),
                const SizedBox(height: 6),
                Row(children: [
                  Text("Points: ${event.points}", style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Text("Attended: ${event.attended ? '✅' : '❌'}", style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800]))
                ]),
                const SizedBox(height: 6),
                if (codeVisible)
                  Row(children: [
                    SelectableText("Code: ${event.code}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Text("(${_formatRemaining(remaining)})", style: const TextStyle(color: Colors.green))
                  ])
                else if (event.code != null)
                  const Text("Code expired", style: TextStyle(color: Colors.red))
              ]),
              trailing: Wrap(spacing: 6, children: [
                IconButton(icon: const Icon(Icons.edit), color: Colors.orange, onPressed: () => _showEditDialog(event)),
                IconButton(icon: const Icon(Icons.delete), color: Colors.red, onPressed: () => _confirmDelete(event)),
                IconButton(icon: const Icon(Icons.qr_code_2), color: Colors.green, onPressed: () => _generateCodeAndShow(event)),
              ]),
            ),
          );
        }),
    ]);
  }

  Widget _buildUsersButton(bool isDark) {
    return Center(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.people),
        label: const Text("View All Users"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UsersPage()),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final admin = ref.read(adminProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("All Users"), backgroundColor: const Color(0xFF2E7D32)),
      body: FutureBuilder<List<AppUser>>(
        future: admin.fetchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Text("No users found", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700])),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final scoreController = TextEditingController();
              return Card(
                color: isDark ? Colors.grey[900] : Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.person, color: Colors.white)),
                  title: Text(user.displayName, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                  subtitle: Text(user.email, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700])),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    color: const Color(0xFF2E7D32),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                          title: const Text("Add Points"),
                          content: TextField(controller: scoreController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Enter points to add")),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                              onPressed: () async {
                                final amount = int.tryParse(scoreController.text) ?? 0;
                                if (amount > 0) {
                                  await admin.addPoints(user, amount);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Added $amount points to ${user.displayName}")));
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Add"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
