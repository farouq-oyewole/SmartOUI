class PaymentRequest {
  final String id;
  final double amount;
  final String currency;
  final String email;
  final String name;
  final String? phoneNumber;
  final String description;
  final String? redirectUrl;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final PaymentStatus status;

  PaymentRequest({
    required this.id,
    required this.amount,
    this.currency = 'NGN',
    required this.email,
    required this.name,
    this.phoneNumber,
    required this.description,
    this.redirectUrl,
    this.metadata = const {},
    required this.createdAt,
    this.status = PaymentStatus.pending,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      email: json['email'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      description: json['description'],
      redirectUrl: json['redirectUrl'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'description': description,
      'redirectUrl': redirectUrl,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  PaymentRequest copyWith({
    String? id,
    double? amount,
    String? currency,
    String? email,
    String? name,
    String? phoneNumber,
    String? description,
    String? redirectUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    PaymentStatus? status,
  }) {
    return PaymentRequest(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      description: description ?? this.description,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

class PaymentResponse {
  final String id;
  final String status;
  final String message;
  final PaymentData? data;
  final String? error;
  final DateTime timestamp;

  PaymentResponse({
    required this.id,
    required this.status,
    required this.message,
    this.data,
    this.error,
    required this.timestamp,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? PaymentData.fromJson(json['data']) : null,
      error: json['error'],
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'message': message,
      'data': data?.toJson(),
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isSuccessful => status.toLowerCase() == 'success';
  bool get isFailed => status.toLowerCase() == 'failed' || error != null;
}

class PaymentData {
  final String txRef;
  final String flwRef;
  final double amount;
  final String currency;
  final String paymentType;
  final String? authorizationUrl;
  final Map<String, dynamic> customer;
  final DateTime createdAt;

  PaymentData({
    required this.txRef,
    required this.flwRef,
    required this.amount,
    required this.currency,
    required this.paymentType,
    this.authorizationUrl,
    required this.customer,
    required this.createdAt,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      txRef: json['tx_ref'] ?? '',
      flwRef: json['flw_ref'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
      paymentType: json['payment_type'] ?? '',
      authorizationUrl: json['authorization_url'],
      customer: Map<String, dynamic>.from(json['customer'] ?? {}),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tx_ref': txRef,
      'flw_ref': flwRef,
      'amount': amount,
      'currency': currency,
      'payment_type': paymentType,
      'authorization_url': authorizationUrl,
      'customer': customer,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? reference;
  final double? amount;
  final String? message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.reference,
    this.amount,
    this.message,
    required this.timestamp,
    this.metadata,
  });

  factory PaymentResult.success({
    required String transactionId,
    required String reference,
    required double amount,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      reference: reference,
      amount: amount,
      message: message ?? 'Payment successful',
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  factory PaymentResult.failure({
    required String message,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      success: false,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transactionId': transactionId,
      'reference': reference,
      'amount': amount,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] ?? false,
      transactionId: json['transactionId'],
      reference: json['reference'],
      amount: json['amount']?.toDouble(),
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }
}

enum PaymentStatus {
  pending,
  processing,
  successful,
  failed,
  cancelled,
}

enum PaymentMethod {
  card,
  bankTransfer,
  ussd,
  qr,
  mobileMoney,
}
