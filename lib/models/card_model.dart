import 'package:cloud_firestore/cloud_firestore.dart';

class BankCard {
  final String id;
  final String userId;
  final String cardNumber;
  final String cardHolderName;
  final String expiryMonth;
  final String expiryYear;
  final CardType type;
  final CardProvider provider;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CardLimits limits;
  final Map<String, dynamic> metadata;

  BankCard({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.type,
    required this.provider,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    CardLimits? limits,
    this.metadata = const {},
  }) : limits = limits ?? CardLimits();

  factory BankCard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BankCard(
      id: doc.id,
      userId: data['userId'] ?? '',
      cardNumber: data['cardNumber'] ?? '',
      cardHolderName: data['cardHolderName'] ?? '',
      expiryMonth: data['expiryMonth'] ?? '',
      expiryYear: data['expiryYear'] ?? '',
      type: CardType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => CardType.debit,
      ),
      provider: CardProvider.values.firstWhere(
        (e) => e.name == data['provider'],
        orElse: () => CardProvider.visa,
      ),
      isDefault: data['isDefault'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      limits: CardLimits.fromMap(data['limits'] ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'type': type.name,
      'provider': provider.name,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'limits': limits.toMap(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'type': type.name,
      'provider': provider.name,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'limits': limits.toMap(),
      'metadata': metadata,
    };
  }

  BankCard copyWith({
    String? id,
    String? userId,
    String? cardNumber,
    String? cardHolderName,
    String? expiryMonth,
    String? expiryYear,
    CardType? type,
    CardProvider? provider,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    CardLimits? limits,
    Map<String, dynamic>? metadata,
  }) {
    return BankCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      limits: limits ?? this.limits,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convenience getters
  String get maskedNumber => '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  String get expiryDate => '$expiryMonth/$expiryYear';
  bool get isExpired {
    final now = DateTime.now();
    final expiry = DateTime(int.parse('20$expiryYear'), int.parse(expiryMonth));
    return now.isAfter(expiry);
  }
  String get displayName => '${provider.displayName} ${type.displayName}';
}

class CardLimits {
  final double dailyLimit;
  final double monthlyLimit;
  final double transactionLimit;
  final double atmLimit;
  final double onlineLimit;

  CardLimits({
    this.dailyLimit = 5000.0,
    this.monthlyLimit = 50000.0,
    this.transactionLimit = 1000.0,
    this.atmLimit = 2000.0,
    this.onlineLimit = 3000.0,
  });

  factory CardLimits.fromMap(Map<String, dynamic> map) {
    return CardLimits(
      dailyLimit: (map['dailyLimit'] ?? 5000.0).toDouble(),
      monthlyLimit: (map['monthlyLimit'] ?? 50000.0).toDouble(),
      transactionLimit: (map['transactionLimit'] ?? 1000.0).toDouble(),
      atmLimit: (map['atmLimit'] ?? 2000.0).toDouble(),
      onlineLimit: (map['onlineLimit'] ?? 3000.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyLimit': dailyLimit,
      'monthlyLimit': monthlyLimit,
      'transactionLimit': transactionLimit,
      'atmLimit': atmLimit,
      'onlineLimit': onlineLimit,
    };
  }

  CardLimits copyWith({
    double? dailyLimit,
    double? monthlyLimit,
    double? transactionLimit,
    double? atmLimit,
    double? onlineLimit,
  }) {
    return CardLimits(
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      transactionLimit: transactionLimit ?? this.transactionLimit,
      atmLimit: atmLimit ?? this.atmLimit,
      onlineLimit: onlineLimit ?? this.onlineLimit,
    );
  }
}

enum CardType {
  debit,
  credit,
  prepaid,
}

enum CardProvider {
  visa,
  mastercard,
  americanExpress,
  discover,
}

extension CardTypeExtension on CardType {
  String get displayName {
    switch (this) {
      case CardType.debit:
        return 'Debit Card';
      case CardType.credit:
        return 'Credit Card';
      case CardType.prepaid:
        return 'Prepaid Card';
    }
  }
}

extension CardProviderExtension on CardProvider {
  String get displayName {
    switch (this) {
      case CardProvider.visa:
        return 'Visa';
      case CardProvider.mastercard:
        return 'Mastercard';
      case CardProvider.americanExpress:
        return 'American Express';
      case CardProvider.discover:
        return 'Discover';
    }
  }
}
