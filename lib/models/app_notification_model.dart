import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  success,
  error,
  payment,
  security,
  general,
  warning,
  transaction,
  promotion, info,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime timestamp;
  final NotificationType type;
  final Map<String, dynamic>? data;
  

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.timestamp,
    this.type = NotificationType.general,
    this.data,
  });

  /// Create notification from Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: _typeFromString(data['type']),
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.name,
      if (data != null) 'data': data,
    };
  }

  /// Create a copy with optional new values
  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? timestamp,
    NotificationType? type,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }

  /// Helper: convert string to NotificationType
  static NotificationType _typeFromString(String? value) {
    switch (value) {
      case 'success':
        return NotificationType.success;
      case 'error':
        return NotificationType.error;
      case 'payment':
        return NotificationType.payment;
      case 'security':
        return NotificationType.security;
      default:
        return NotificationType.general;
    }
  }
}
