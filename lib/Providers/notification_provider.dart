import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/app_notification_model.dart';
import 'auth_provider.dart';

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  final Ref ref;
  final AudioPlayer _audioPlayer = AudioPlayer();

  NotificationNotifier(this.ref) : super([]);

  Future<void> loadNotifications(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    state = snapshot.docs
        .map((doc) => AppNotification.fromFirestore(doc))
        .toList();
  }

  Future<void> addNotification(AppNotification notification) async {
    state = [notification, ...state];

    // Save to Firestore
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toFirestore());

    await _playNotificationSound();
  }
  
  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (_) {}
  }

  Future<void> showNotification(AppNotification notification) async {
  // Save to Firestore
  await FirebaseFirestore.instance
      .collection('notifications')
      .add(notification.toFirestore());

  // Add to local state
  state = [notification, ...state];

  // Play notification sound
  await _playNotificationSound();
}


  Future<void> showSuccess(String title, String message) async {
    final now = DateTime.now();
    final userId = ref.read(currentAppUserProvider)?.id ?? '';
    final notification = AppNotification(
      id: now.millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      message: message,
      isRead: false,
      timestamp: now,
      type: NotificationType.success,
    );
    await showNotification(notification);
  }

  Future<void> showError(String title, String message) async {
    final now = DateTime.now();
    final userId = ref.read(currentAppUserProvider)?.id ?? '';
    final notification = AppNotification(
      id: now.millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      message: message,
      isRead: false,
      timestamp: now,
      type: NotificationType.error,
    );
    await showNotification(notification);
  }
  void markAsRead(String id) async {
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(isRead: true)
        else
          n,
    ];

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .update({'isRead': true});
  }

  void markAllAsRead() {
    for (final n in state) {
      if (!n.isRead) {
        FirebaseFirestore.instance
            .collection('notifications')
            .doc(n.id)
            .update({'isRead': true});
      }
    }

    state = [for (final n in state) n.copyWith(isRead: true)];
  }



  void clearAllNotifications() async {
    final user = ref.read(currentAppUserProvider);
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final n in state) {
      final docRef = FirebaseFirestore.instance.collection('notifications').doc(n.id);
      batch.delete(docRef);
    }

    await batch.commit();
    state = [];
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>(
  (ref) => NotificationNotifier(ref),
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});
