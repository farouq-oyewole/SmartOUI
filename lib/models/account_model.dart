import 'package:cloud_firestore/cloud_firestore.dart';

class Account {
  final String id;
  final String userId;
  final String accountNumber;
  final String accountName;
  final AccountType type;
  final String currency;
  final double balance;
  final double availableBalance;
  final AccountStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AccountLimits limits;
  final List<String> features;
  final Map<String, dynamic> metadata;

  Account({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.accountName,
    required this.type,
    this.currency = 'USD',
    required this.balance,
    required this.availableBalance,
    this.status = AccountStatus.active,
    required this.createdAt,
    required this.updatedAt,
    AccountLimits? limits,
    this.features = const [],
    this.metadata = const {},
  }) : limits = limits ?? AccountLimits();

  factory Account.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Account(
      id: doc.id,
      userId: data['userId'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      accountName: data['accountName'] ?? '',
      type: AccountType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AccountType.checking,
      ),
      currency: data['currency'] ?? 'USD',
      balance: (data['balance'] ?? 0.0).toDouble(),
      availableBalance: (data['availableBalance'] ?? 0.0).toDouble(),
      status: AccountStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AccountStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      limits: AccountLimits.fromMap(data['limits'] ?? {}),
      features: List<String>.from(data['features'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'type': type.name,
      'currency': currency,
      'balance': balance,
      'availableBalance': availableBalance,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'limits': limits.toMap(),
      'features': features,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'type': type.name,
      'currency': currency,
      'balance': balance,
      'availableBalance': availableBalance,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'limits': limits.toMap(),
      'features': features,
      'metadata': metadata,
    };
  }

  Account copyWith({
    String? id,
    String? userId,
    String? accountNumber,
    String? accountName,
    AccountType? type,
    String? currency,
    double? balance,
    double? availableBalance,
    AccountStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    AccountLimits? limits,
    List<String>? features,
    Map<String, dynamic>? metadata,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      availableBalance: availableBalance ?? this.availableBalance,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      limits: limits ?? this.limits,
      features: features ?? this.features,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convenience getters
  String get maskedAccountNumber => '**** **** ${accountNumber.substring(accountNumber.length - 4)}';
  String get formattedBalance => '\$${balance.toStringAsFixed(2)}';
  String get formattedAvailableBalance => '\$${availableBalance.toStringAsFixed(2)}';
  bool get isActive => status == AccountStatus.active;
  bool get isFrozen => status == AccountStatus.frozen;
  bool get isClosed => status == AccountStatus.closed;
  double get pendingAmount => balance - availableBalance;
}

class AccountLimits {
  final double dailyWithdrawalLimit;
  final double dailyTransferLimit;
  final double monthlyTransferLimit;
  final double minimumBalance;
  final double overdraftLimit;

  AccountLimits({
    this.dailyWithdrawalLimit = 1000.0,
    this.dailyTransferLimit = 5000.0,
    this.monthlyTransferLimit = 50000.0,
    this.minimumBalance = 0.0,
    this.overdraftLimit = 0.0,
  });

  factory AccountLimits.fromMap(Map<String, dynamic> map) {
    return AccountLimits(
      dailyWithdrawalLimit: (map['dailyWithdrawalLimit'] ?? 1000.0).toDouble(),
      dailyTransferLimit: (map['dailyTransferLimit'] ?? 5000.0).toDouble(),
      monthlyTransferLimit: (map['monthlyTransferLimit'] ?? 50000.0).toDouble(),
      minimumBalance: (map['minimumBalance'] ?? 0.0).toDouble(),
      overdraftLimit: (map['overdraftLimit'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyWithdrawalLimit': dailyWithdrawalLimit,
      'dailyTransferLimit': dailyTransferLimit,
      'monthlyTransferLimit': monthlyTransferLimit,
      'minimumBalance': minimumBalance,
      'overdraftLimit': overdraftLimit,
    };
  }

  AccountLimits copyWith({
    double? dailyWithdrawalLimit,
    double? dailyTransferLimit,
    double? monthlyTransferLimit,
    double? minimumBalance,
    double? overdraftLimit,
  }) {
    return AccountLimits(
      dailyWithdrawalLimit: dailyWithdrawalLimit ?? this.dailyWithdrawalLimit,
      dailyTransferLimit: dailyTransferLimit ?? this.dailyTransferLimit,
      monthlyTransferLimit: monthlyTransferLimit ?? this.monthlyTransferLimit,
      minimumBalance: minimumBalance ?? this.minimumBalance,
      overdraftLimit: overdraftLimit ?? this.overdraftLimit,
    );
  }
}

enum AccountType {
  checking,
  savings,
  business,
  investment,
  credit,
}

enum AccountStatus {
  active,
  inactive,
  frozen,
  closed,
  pending,
}

extension AccountTypeExtension on AccountType {
  String get displayName {
    switch (this) {
      case AccountType.checking:
        return 'Checking Account';
      case AccountType.savings:
        return 'Savings Account';
      case AccountType.business:
        return 'Business Account';
      case AccountType.investment:
        return 'Investment Account';
      case AccountType.credit:
        return 'Credit Account';
    }
  }
}

extension AccountStatusExtension on AccountStatus {
  String get displayName {
    switch (this) {
      case AccountStatus.active:
        return 'Active';
      case AccountStatus.inactive:
        return 'Inactive';
      case AccountStatus.frozen:
        return 'Frozen';
      case AccountStatus.closed:
        return 'Closed';
      case AccountStatus.pending:
        return 'Pending';
    }
  }
}
