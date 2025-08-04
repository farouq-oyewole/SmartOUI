import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? transactionPin; // Can be a hashed placeholder or null.
  final String? profileImage;
  final String? photoUrl;
  final String? photoFilePath;
  final double balance;
  final String cardNumber;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserStatus status;
  final List<String> accountTypes;
  final Map<String, dynamic> preferences;
  final SecuritySettings securitySettings;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.transactionPin,
    this.profileImage,
    this.photoUrl,
    this.photoFilePath,
    required this.balance,
    required this.cardNumber,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.status = UserStatus.active,
    this.accountTypes = const ['checking'],
    this.preferences = const {},
    SecuritySettings? securitySettings,
  }) : securitySettings = securitySettings ?? SecuritySettings();

  // 📥 FROM FIRESTORE
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      transactionPin: data['transactionPin'],
      profileImage: data['profileImage'],
      photoUrl: data['photoUrl'],
      photoFilePath: data['photoFilePath'],
      balance: (data['balance'] ?? 0.0).toDouble(),
      cardNumber: data['cardNumber'] ?? '',
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      status: UserStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UserStatus.active,
      ),
      accountTypes: List<String>.from(data['accountTypes'] ?? ['checking']),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      securitySettings: SecuritySettings.fromMap(data['securitySettings'] ?? {}),
    );
  }

  // 📤 TO FIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'transactionPin': transactionPin,
      'profileImage': profileImage,
      'photoUrl': photoUrl,
      'photoFilePath': photoFilePath,
      'balance': balance,
      'cardNumber': cardNumber,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status.name,
      'accountTypes': accountTypes,
      'preferences': preferences,
      'securitySettings': securitySettings.toMap(),
    };
  }

  // 🔄 JSON Support
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'transactionPin': transactionPin,
      'profileImage': profileImage,
      'photoUrl': photoUrl,
      'photoFilePath': photoFilePath,
      'balance': balance,
      'cardNumber': cardNumber,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'accountTypes': accountTypes,
      'preferences': preferences,
      'securitySettings': securitySettings.toMap(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionPin': transactionPin,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'balance': balance,
      'cardNumber': cardNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }


  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      transactionPin: json['transactionPin'],
      profileImage: json['profileImage'],
      photoUrl: json['photoUrl'],
      photoFilePath: json['photoFilePath'],
      balance: (json['balance'] ?? 0.0).toDouble(),
      cardNumber: json['cardNumber'] ?? '',
      phoneNumber: json['phoneNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: UserStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserStatus.active,
      ),
      accountTypes: List<String>.from(json['accountTypes'] ?? ['checking']),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      securitySettings: SecuritySettings.fromMap(json['securitySettings'] ?? {}),
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      transactionPin: map['transactionPin'],
      profileImage: map['profileImage'],
      photoUrl: map['photoUrl'],
      photoFilePath: map['photoFilePath'],
      balance: (map['balance'] ?? 0.0).toDouble(),
      cardNumber: map['cardNumber'] ?? '',
      phoneNumber: map['phoneNumber'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      status: UserStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserStatus.active,
      ),
      accountTypes: List<String>.from(map['accountTypes'] ?? ['checking']),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      securitySettings: SecuritySettings.fromMap(map['securitySettings'] ?? {}),
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? transactionPin,
    String? profileImage,
    String? photoUrl,
    String? photoFilePath,
    double? balance,
    String? cardNumber,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserStatus? status,
    List<String>? accountTypes,
    Map<String, dynamic>? preferences,
    SecuritySettings? securitySettings,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      transactionPin: transactionPin ?? this.transactionPin,
      profileImage: profileImage ?? this.profileImage,
      photoUrl: photoUrl ?? this.photoUrl,
      photoFilePath: photoFilePath ?? this.photoFilePath,
      balance: balance ?? this.balance,
      cardNumber: cardNumber ?? this.cardNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      accountTypes: accountTypes ?? this.accountTypes,
      preferences: preferences ?? this.preferences,
      securitySettings: securitySettings ?? this.securitySettings,
    );
  }

  /// 📌 Utility Getters
  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  String get maskedCardNumber =>
      cardNumber.length >= 4 ? '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}' : '';

  bool get isVerified => status == UserStatus.active;

  bool get hasProfileImage =>
      (photoUrl?.isNotEmpty ?? false) ||
      (photoFilePath?.isNotEmpty ?? false) ||
      (profileImage?.isNotEmpty ?? false);
}

/// 🔐 Enum for User Account Status
enum UserStatus {
  active,
  inactive,
  suspended,
  pending,
}

/// 🔐 Security Preferences Model
class SecuritySettings {
  final bool twoFactorEnabled;
  final bool biometricEnabled;
  final bool notificationsEnabled;
  final bool transactionAlertsEnabled;
  final DateTime? lastPasswordChange;
  final List<String> trustedDevices;

  SecuritySettings({
    this.twoFactorEnabled = false,
    this.biometricEnabled = false,
    this.notificationsEnabled = true,
    this.transactionAlertsEnabled = true,
    this.lastPasswordChange,
    this.trustedDevices = const [],
  });

  factory SecuritySettings.fromMap(Map<String, dynamic> map) {
    return SecuritySettings(
      twoFactorEnabled: map['twoFactorEnabled'] ?? false,
      biometricEnabled: map['biometricEnabled'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      transactionAlertsEnabled: map['transactionAlertsEnabled'] ?? true,
      lastPasswordChange: map['lastPasswordChange'] is Timestamp
          ? (map['lastPasswordChange'] as Timestamp).toDate()
          : null,
      trustedDevices: List<String>.from(map['trustedDevices'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'twoFactorEnabled': twoFactorEnabled,
      'biometricEnabled': biometricEnabled,
      'notificationsEnabled': notificationsEnabled,
      'transactionAlertsEnabled': transactionAlertsEnabled,
      'lastPasswordChange':
          lastPasswordChange != null ? Timestamp.fromDate(lastPasswordChange!) : null,
      'trustedDevices': trustedDevices,
    };
  }

  SecuritySettings copyWith({
    bool? twoFactorEnabled,
    bool? biometricEnabled,
    bool? notificationsEnabled,
    bool? transactionAlertsEnabled,
    DateTime? lastPasswordChange,
    List<String>? trustedDevices,
  }) {
    return SecuritySettings(
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      transactionAlertsEnabled: transactionAlertsEnabled ?? this.transactionAlertsEnabled,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      trustedDevices: trustedDevices ?? this.trustedDevices,
    );
  }
}
