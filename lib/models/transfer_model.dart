import 'package:cloud_firestore/cloud_firestore.dart';

class Transfer {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final String recipientAccount;
  final double amount;
  final String currency;
  final String description;
  final String? reference;
  final TransferType type;
  final TransferStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;
  final TransferFee fee;
  final Map<String, dynamic> metadata;

  Transfer({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.recipientAccount,
    required this.amount,
    this.currency = 'USD',
    required this.description,
    this.reference,
    required this.type,
    this.status = TransferStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
    TransferFee? fee,
    this.metadata = const {},
  }) : fee = fee ?? TransferFee();

  factory Transfer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transfer(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      recipientId: data['recipientId'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientAccount: data['recipientAccount'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      description: data['description'] ?? '',
      reference: data['reference'],
      type: TransferType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransferType.internal,
      ),
      status: TransferStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransferStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      failureReason: data['failureReason'],
      fee: TransferFee.fromMap(data['fee'] ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientAccount': recipientAccount,
      'amount': amount,
      'currency': currency,
      'description': description,
      'reference': reference,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failureReason': failureReason,
      'fee': fee.toMap(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientAccount': recipientAccount,
      'amount': amount,
      'currency': currency,
      'description': description,
      'reference': reference,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'failureReason': failureReason,
      'fee': fee.toMap(),
      'metadata': metadata,
    };
  }

  Transfer copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? recipientId,
    String? recipientName,
    String? recipientAccount,
    double? amount,
    String? currency,
    String? description,
    String? reference,
    TransferType? type,
    TransferStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? failureReason,
    TransferFee? fee,
    Map<String, dynamic>? metadata,
  }) {
    return Transfer(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientAccount: recipientAccount ?? this.recipientAccount,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
      fee: fee ?? this.fee,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convenience getters
  bool get isPending => status == TransferStatus.pending;
  bool get isCompleted => status == TransferStatus.completed;
  bool get isFailed => status == TransferStatus.failed;
  bool get isProcessing => status == TransferStatus.processing;
  double get totalAmount => amount + fee.totalFee;
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';
}

class TransferFee {
  final double baseFee;
  final double percentageFee;
  final double fixedFee;
  final String currency;

  TransferFee({
    this.baseFee = 0.0,
    this.percentageFee = 0.0,
    this.fixedFee = 0.0,
    this.currency = 'USD',
  });

  factory TransferFee.fromMap(Map<String, dynamic> map) {
    return TransferFee(
      baseFee: (map['baseFee'] ?? 0.0).toDouble(),
      percentageFee: (map['percentageFee'] ?? 0.0).toDouble(),
      fixedFee: (map['fixedFee'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baseFee': baseFee,
      'percentageFee': percentageFee,
      'fixedFee': fixedFee,
      'currency': currency,
    };
  }

  double get totalFee => baseFee + percentageFee + fixedFee;
  String get formattedTotalFee => '\$${totalFee.toStringAsFixed(2)}';
}

enum TransferType {
  internal,
  external,
  international,
  wire,
}

enum TransferStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

extension TransferTypeExtension on TransferType {
  String get displayName {
    switch (this) {
      case TransferType.internal:
        return 'Internal Transfer';
      case TransferType.external:
        return 'External Transfer';
      case TransferType.international:
        return 'International Transfer';
      case TransferType.wire:
        return 'Wire Transfer';
    }
  }
}

extension TransferStatusExtension on TransferStatus {
  String get displayName {
    switch (this) {
      case TransferStatus.pending:
        return 'Pending';
      case TransferStatus.processing:
        return 'Processing';
      case TransferStatus.completed:
        return 'Completed';
      case TransferStatus.failed:
        return 'Failed';
      case TransferStatus.cancelled:
        return 'Cancelled';
    }
  }
}
