import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? transactionPin; // Future use if needed
  final String? profileImage;
  final String? photoUrl;
  final String? photoFilePath;
  final int creditScore; // replaces balance
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
    this.phoneNumber,
    this.transactionPin,
    this.profileImage,
    this.photoUrl,
    this.photoFilePath,
    this.creditScore = 0,
    required this.createdAt,
    required this.updatedAt,
    this.status = UserStatus.active,
    this.accountTypes = const ['member'],
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
      phoneNumber: data['phoneNumber'],
      transactionPin: data['transactionPin'],
      profileImage: data['profileImage'],
      photoUrl: data['photoUrl'],
      photoFilePath: data['photoFilePath'],
      creditScore: (data['creditScore'] ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      status: UserStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UserStatus.active,
      ),
      accountTypes: List<String>.from(data['accountTypes'] ?? ['member']),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      securitySettings: SecuritySettings.fromMap(data['securitySettings'] ?? {}),
    );
  }

  // 📤 TO FIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'transactionPin': transactionPin,
      'profileImage': profileImage,
      'photoUrl': photoUrl,
      'photoFilePath': photoFilePath,
      'creditScore': creditScore,
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
      'phoneNumber': phoneNumber,
      'transactionPin': transactionPin,
      'profileImage': profileImage,
      'photoUrl': photoUrl,
      'photoFilePath': photoFilePath,
      'creditScore': creditScore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'accountTypes': accountTypes,
      'preferences': preferences,
      'securitySettings': securitySettings.toMap(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      transactionPin: json['transactionPin'],
      profileImage: json['profileImage'],
      photoUrl: json['photoUrl'],
      photoFilePath: json['photoFilePath'],
      creditScore: (json['creditScore'] ?? 0).toInt(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: UserStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserStatus.active,
      ),
      accountTypes: List<String>.from(json['accountTypes'] ?? ['member']),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      securitySettings: SecuritySettings.fromMap(json['securitySettings'] ?? {}),
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? transactionPin,
    String? profileImage,
    String? photoUrl,
    String? photoFilePath,
    int? creditScore,
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
      phoneNumber: phoneNumber ?? this.phoneNumber,
      transactionPin: transactionPin ?? this.transactionPin,
      profileImage: profileImage ?? this.profileImage,
      photoUrl: photoUrl ?? this.photoUrl,
      photoFilePath: photoFilePath ?? this.photoFilePath,
      creditScore: creditScore ?? this.creditScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      accountTypes: accountTypes ?? this.accountTypes,
      preferences: preferences ?? this.preferences,
      securitySettings: securitySettings ?? this.securitySettings,
    );
  }

  /// 🏅 Derived properties
  String get badge {
    if (creditScore >= 100) return '🥇 Gold';
    if (creditScore >= 50) return '🥈 Silver';
    if (creditScore >= 30) return '🥉 Bronze';
    return '🌱 New Member';
  }

  String get displayName => name.isNotEmpty ? name : email.split('@').first;
  bool get hasProfileImage =>
      (photoUrl?.isNotEmpty ?? false) ||
      (photoFilePath?.isNotEmpty ?? false) ||
      (profileImage?.isNotEmpty ?? false);
}

/// 🔐 Enum for User Account Status
enum UserStatus { active, inactive, suspended, pending }

/// 🔐 Security Preferences Model
class SecuritySettings {
  final bool twoFactorEnabled;
  final bool biometricEnabled;
  final bool notificationsEnabled;
  final DateTime? lastPasswordChange;
  final List<String> trustedDevices;

  SecuritySettings({
    this.twoFactorEnabled = false,
    this.biometricEnabled = false,
    this.notificationsEnabled = true,
    this.lastPasswordChange,
    this.trustedDevices = const [],
  });

  factory SecuritySettings.fromMap(Map<String, dynamic> map) {
    return SecuritySettings(
      twoFactorEnabled: map['twoFactorEnabled'] ?? false,
      biometricEnabled: map['biometricEnabled'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
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
      'lastPasswordChange':
          lastPasswordChange != null ? Timestamp.fromDate(lastPasswordChange!) : null,
      'trustedDevices': trustedDevices,
    };
  }
}
