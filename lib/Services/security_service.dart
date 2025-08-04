import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

class SecurityService {
  final StorageService _storageService;

  SecurityService(this._storageService);

  // Generate secure random string
  String generateSecureToken(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  // Hash password/PIN
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate salt
  String generateSalt() {
    return generateSecureToken(32);
  }

  // Verify password/PIN
  bool verifyPassword(String password, String hashedPassword, String salt) {
    final hashedInput = hashPassword(password, salt);
    return hashedInput == hashedPassword;
  }

  // Generate transaction reference
  String generateTransactionReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = generateSecureToken(8);
    return 'TXN_${timestamp}_$random';
  }

  // Generate card number (for demo purposes)
  String generateCardNumber() {
    final random = Random.secure();
    final digits = List.generate(16, (_) => random.nextInt(10));
    
    // Apply Luhn algorithm to make it valid
    int sum = 0;
    bool alternate = false;
    
    for (int i = digits.length - 2; i >= 0; i--) {
      int digit = digits[i];
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    digits[digits.length - 1] = (10 - (sum % 10)) % 10;
    
    return digits.join();
  }

  // Encrypt sensitive data (simplified - use proper encryption in production)
  String encryptData(String data, String key) {
    // This is a simplified encryption - use proper encryption libraries in production
    final bytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);
    final encrypted = <int>[];
    
    for (int i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encrypted);
  }

  // Decrypt sensitive data
  String decryptData(String encryptedData, String key) {
    try {
      final encrypted = base64.decode(encryptedData);
      final keyBytes = utf8.encode(key);
      final decrypted = <int>[];
      
      for (int i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  // Mask sensitive information
  String maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  String maskAccountNumber(String accountNumber) {
    if (accountNumber.length < 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }

  String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) return email;
    
    final maskedUsername = username[0] + '*' * (username.length - 2) + username[username.length - 1];
    return '$maskedUsername@$domain';
  }

  String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 4) return phoneNumber;
    return '***-***-${phoneNumber.substring(phoneNumber.length - 4)}';
  }

  // Session management
  Future<void> createSession(String userId) async {
    final sessionToken = generateSecureToken(64);
    final sessionData = {
      'user_id': userId,
      'token': sessionToken,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
    };
    
    await _storageService.cacheData('session', sessionData);
  }

  Future<Map<String, dynamic>?> getSession() async {
    return await _storageService.getCachedData('session', maxAge: const Duration(hours: 24));
  }

  Future<void> invalidateSession() async {
    await _storageService.removeCachedData('session');
  }

  Future<bool> isSessionValid() async {
    final session = await getSession();
    if (session == null) return false;
    
    final expiresAt = DateTime.parse(session['expires_at']);
    return DateTime.now().isBefore(expiresAt);
  }

  // Rate limiting
  Future<bool> checkRateLimit(String action, {int maxAttempts = 5, Duration window = const Duration(minutes: 15)}) async {
    final key = 'rate_limit_$action';
    final cached = await _storageService.getCachedData(key, maxAge: window);
    
    if (cached == null) {
      await _storageService.cacheData(key, {'attempts': 1});
      return true;
    }
    
    final attempts = cached['attempts'] as int;
    if (attempts >= maxAttempts) {
      return false;
    }
    
    await _storageService.cacheData(key, {'attempts': attempts + 1});
    return true;
  }

  Future<void> resetRateLimit(String action) async {
    final key = 'rate_limit_$action';
    await _storageService.removeCachedData(key);
  }

  // Device fingerprinting (simplified)
  String generateDeviceFingerprint() {
    // In a real app, this would collect device-specific information
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = generateSecureToken(16);
    return 'device_${timestamp}_$random';
  }

  // Fraud detection helpers
  bool isAmountSuspicious(double amount, List<double> recentAmounts) {
    if (recentAmounts.isEmpty) return false;
    
    final average = recentAmounts.reduce((a, b) => a + b) / recentAmounts.length;
    final threshold = average * 3; // 3x average is suspicious
    
    return amount > threshold;
  }

  bool isFrequencysuspicious(List<DateTime> recentTransactions) {
    if (recentTransactions.length < 3) return false;
    
    final now = DateTime.now();
    final recentCount = recentTransactions
        .where((date) => now.difference(date).inMinutes < 5)
        .length;
    
    return recentCount >= 3; // 3 transactions in 5 minutes is suspicious
  }

  bool isLocationSuspicious(String currentLocation, List<String> recentLocations) {
    // Simplified location check - in reality, you'd use proper geolocation
    if (recentLocations.isEmpty) return false;
    
    final lastLocation = recentLocations.last;
    return currentLocation != lastLocation && 
           !recentLocations.contains(currentLocation);
  }

  // Security score calculation
  int calculateSecurityScore({
    required bool hasStrongPassword,
    required bool hasTwoFactor,
    required bool hasBiometric,
    required bool hasRecentActivity,
    required bool hasVerifiedEmail,
    required bool hasVerifiedPhone,
  }) {
    int score = 0;
    
    if (hasStrongPassword) score += 20;
    if (hasTwoFactor) score += 25;
    if (hasBiometric) score += 20;
    if (hasRecentActivity) score += 10;
    if (hasVerifiedEmail) score += 15;
    if (hasVerifiedPhone) score += 10;
    
    return score;
  }

  String getSecurityLevel(int score) {
    if (score >= 80) return 'High';
    if (score >= 60) return 'Medium';
    if (score >= 40) return 'Low';
    return 'Very Low';
  }

  // Generate OTP
  String generateOTP({int length = 6}) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }

  // Validate OTP timing
  bool isOTPValid(DateTime generatedAt, {Duration validFor = const Duration(minutes: 5)}) {
    final now = DateTime.now();
    return now.difference(generatedAt) <= validFor;
  }

  // Log security events
  Future<void> logSecurityEvent({
    required String event,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    final logEntry = {
      'event': event,
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };
    
    // In a real app, this would be sent to a security monitoring service
    await _storageService.cacheData('security_log_${DateTime.now().millisecondsSinceEpoch}', logEntry);
  }
}

final securityServiceProvider = Provider<SecurityService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SecurityService(storageService);
});
