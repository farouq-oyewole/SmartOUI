import 'package:bank_app/Providers/auth_provider.dart';
import 'package:bank_app/Providers/notification_provider.dart';
import 'package:bank_app/models/app_notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';


class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
    final user = ref.read(currentAppUserProvider);
    if (user != null) {
      await ref.read(notificationProvider.notifier).loadNotifications(user.id);
    }
  });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    final user = ref.read(currentAppUserProvider);
    if (user != null) {
      ref.read(notificationProvider.notifier).loadNotifications(user.id);
    }
  }
  super.didChangeAppLifecycleState(state);
}


  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final notifications = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: "Mark all as read",
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
              setState(() {}); // Refresh UI
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: "Clear all",
            onPressed: () {
              ref.read(notificationProvider.notifier).clearAllNotifications();
              setState(() {}); // Refresh UI
            },
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: notifications.isEmpty
          ? const Center(child: Text("No notifications yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Card(
                  color: n.isRead
                      ? (isDarkMode ? Colors.grey[850] : Colors.grey[200])
                      : (isDarkMode ? Colors.blueGrey[700] : Colors.blue[50]),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(_iconForType(n.type), color: _colorForType(n.type)),
                    title: Text(n.title),
                    subtitle: Text(n.message),
                    trailing: Text(
                      _timeAgo(n.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      ref.read(notificationProvider.notifier).markAsRead(n.id);
                      setState(() {}); // Refresh UI on tap
                    },
                  ),
                );
              },
            ),
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.transaction:
        return Icons.sync_alt;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.security:
        return Icons.security;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.general:
        throw UnimplementedError();
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.transaction:
        return Colors.purple;
      case NotificationType.payment:
        return Colors.teal;
      case NotificationType.security:
        return Colors.indigo;
      case NotificationType.promotion:
        return Colors.pink;
      case NotificationType.general:
        throw UnimplementedError();
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  }
}
