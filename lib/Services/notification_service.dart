import 'dart:async';
import 'package:bank_app/Providers/notification_provider.dart';
import 'package:bank_app/models/app_notification_model.dart';
import 'package:bank_app/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  final Ref _ref;
  Timer? _periodicTimer;

  NotificationService(this._ref) {
    _startPeriodicChecks();
  }

  void _startPeriodicChecks() {
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkForNotifications();
    });
  }

  Future<void> _checkForNotifications() async {
    try {
      await _checkLowBalance();
      await _checkUnusualActivity();
      await _checkBudgetAlerts();
    } catch (e) {
      // ignore: avoid_print
      print('Notification check error: $e');
    }
  }

  Future<void> _checkLowBalance() async {}
  Future<void> _checkUnusualActivity() async {}
  Future<void> _checkBudgetAlerts() async {}

  Future<void> sendTransactionNotification(Transactions transaction) async {
    final title = transaction.isCredit ? 'Money Received' : 'Payment Made';
    final message = transaction.isCredit
        ? 'You received ₦${transaction.amount.toStringAsFixed(2)}'
        : 'You paid ₦${transaction.amount.toStringAsFixed(2)}';

    await _ref.read(notificationProvider.notifier).showNotification(
      AppNotification(
        id: transaction.id,
        userId: transaction.userId,
        title: title,
        message: message,
        type: NotificationType.transaction,
        timestamp: DateTime.now(),
        data: {
          'transaction_id': transaction.id,
          'amount': transaction.amount,
          'type': transaction.type,
        }, isRead: false,
      ),
    );
  }

  Future<void> sendPaymentNotification({
    required String title,
    required String message,
    required String status,
    Map<String, dynamic>? data,
  }) async {
    await _ref.read(notificationProvider.notifier).showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // Add if needed
        title: title,
        message: message,
        type: NotificationType.payment,
        timestamp: DateTime.now(),
        data: {'status': status, ...?data},
        isRead: false
      ),
    );
  }

  Future<void> sendSecurityNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await _ref.read(notificationProvider.notifier).showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // Add if needed
        title: title,
        message: message,
        type: NotificationType.security,
        timestamp: DateTime.now(),
        data: data,
        isRead: false
      ),
    );
  }

  Future<void> sendLowBalanceAlert(double currentBalance, double threshold) async {
    await _ref.read(notificationProvider.notifier).showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: 'Low Balance Alert',
        message:
            'Your balance (₦${currentBalance.toStringAsFixed(2)}) is below ₦${threshold.toStringAsFixed(2)}',
        type: NotificationType.warning,
        timestamp: DateTime.now(),
        data: {
          'current_balance': currentBalance,
          'threshold': threshold,
        },
        isRead: false
      ),
    );
  }

  Future<void> sendBudgetExceededAlert(String category, double spent, double budget) async {
    await _ref.read(notificationProvider.notifier).showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: 'Budget Exceeded',
        message:
            'You’ve exceeded your $category budget. Spent ₦${spent.toStringAsFixed(2)}, budget ₦${budget.toStringAsFixed(2)}',
        type: NotificationType.warning,
        timestamp: DateTime.now(),
        data: {
          'category': category,
          'spent': spent,
          'budget': budget,
        },
        isRead: false
      ),
    );
  }

  Future<void> sendLoginNotification(String deviceInfo, String location) async {
    await _ref.read(notificationProvider.notifier).showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: 'New Login Detected',
        message: 'Login from $deviceInfo in $location',
        type: NotificationType.security,
        timestamp: DateTime.now(),
        data: {
          'device': deviceInfo,
          'location': location,
          'timestamp': DateTime.now().toIso8601String(),
        },
        isRead: false
      ),
    );
  }

  Future<void> sendPasswordChangeNotification() async {
    await _ref.read(notificationProvider.notifier).showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: 'Password Changed',
        message: 'Your password was changed',
        type: NotificationType.security,
        timestamp: DateTime.now(),
        data: {
          'timestamp': DateTime.now().toIso8601String(),
        },
        isRead: false
      ),
    );
  }

  Future<void> sendCardBlockedNotification(String cardNumber) async {
    final last4 = cardNumber.length >= 4
        ? cardNumber.substring(cardNumber.length - 4)
        : cardNumber;

    await _ref.read(notificationProvider.notifier).showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: 'Card Blocked',
        message: 'Card ending in $last4 has been blocked',
        type: NotificationType.security,
        timestamp: DateTime.now(),
        data: {
          'card_number': last4,
          'timestamp': DateTime.now().toIso8601String(),
        },
        isRead: false
      ),
    );
  }

  Future<void> sendTransferNotification({
    required String recipientName,
    required double amount,
    required String status,
  }) async {
    final title =
        status == 'completed' ? 'Transfer Completed' : 'Transfer $status';
    final message = status == 'completed'
        ? 'Transferred ₦${amount.toStringAsFixed(2)} to $recipientName'
        : 'Transfer ₦${amount.toStringAsFixed(2)} is $status';

    await _ref.read(notificationProvider.notifier).showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: title,
        message: message,
        type: NotificationType.transaction,
        timestamp: DateTime.now(),
        data: {
          'recipient': recipientName,
          'amount': amount,
          'status': status,
        },
        isRead: false
      ),
    );
  }

  Future<void> sendPromotionalNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await _ref.read(notificationProvider.notifier).showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: title,
        message: message,
        type: NotificationType.promotion,
        timestamp: DateTime.now(),
        data: data,
        isRead: false
      ),
    );
  }

  void clearAllNotifications() =>
      _ref.read(notificationProvider.notifier).clearAllNotifications();

  void markAsRead(String id) =>
      _ref.read(notificationProvider.notifier).markAsRead(id);

  void dispose() => _periodicTimer?.cancel();
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref);
  ref.onDispose(service.dispose);
  return service;
});
