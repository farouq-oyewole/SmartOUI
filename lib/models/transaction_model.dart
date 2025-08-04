import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class Transactions {
  final String id;
  final String userId;
  final String name;
  final String description;
  final double amount;
  final String type; // 'credit' or 'debit'
  final String category;
  final DateTime date;
  final TransactionStatus status;
  final String? reference;
  final Map<String, dynamic> metadata;

  Transactions({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.status = TransactionStatus.completed,
    this.reference,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'description': description,
        'amount': amount,
        'type': type,
        'category': category,
        'date': date.toIso8601String(),
        'status': status.name,
        'reference': reference,
        'metadata': metadata,
      };

  /// Firestore deserialization
  factory Transactions.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Transactions(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] ?? '',
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: _mapStatus(data['status']),
      reference: data['reference'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'status': status.name,
      'reference': reference,
      'metadata': metadata,
    };
  }

  /// Helper method to convert string to enum
  static TransactionStatus _mapStatus(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'pending':
          return TransactionStatus.pending;
        case 'completed':
          return TransactionStatus.completed;
        case 'failed':
          return TransactionStatus.failed;
        case 'cancelled':
          return TransactionStatus.cancelled;
      }
    }
    return TransactionStatus.pending;
  }

  Transactions copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? amount,
    String? type,
    String? category,
    DateTime? date,
    TransactionStatus? status,
    String? reference,
    Map<String, dynamic>? metadata,
  }) {
    return Transactions(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isCredit => type.toLowerCase() == 'credit';
  bool get isDebit => type.toLowerCase() == 'debit';
  bool get isPending => status == TransactionStatus.pending;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isFailed => status == TransactionStatus.failed;
  bool get isCancelled => status == TransactionStatus.cancelled;
}

class TransactionCategory {
  static const String food = 'food';
  static const String transport = 'transport';
  static const String shopping = 'shopping';
  static const String entertainment = 'entertainment';
  static const String bills = 'bills';
  static const String education = 'education';
  static const String health = 'health';
  static const String transfer = 'transfer';
  static const String salary = 'salary';
  static const String other = 'other';

  static List<String> get all => [
        food,
        transport,
        shopping,
        entertainment,
        bills,
        education,
        health,
        transfer,
        salary,
        other,
      ];

  static String getDisplayName(String category) {
    switch (category) {
      case food:
        return 'Food & Dining';
      case transport:
        return 'Transportation';
      case shopping:
        return 'Shopping';
      case entertainment:
        return 'Entertainment';
      case bills:
        return 'Bills & Utilities';
      case education:
        return 'Education';
      case health:
        return 'Healthcare';
      case transfer:
        return 'Transfer';
      case salary:
        return 'Salary';
      case other:
        return 'Other';
      default:
        return 'Unknown';
    }
  }
}
