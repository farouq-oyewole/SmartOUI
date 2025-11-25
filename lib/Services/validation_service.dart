import 'package:flutter_riverpod/flutter_riverpod.dart';

class ValidationService {
  // ✅ Email validation (returns bool for easy use in forms)
  static bool isValidEmail(String email) {
    final emailTrimmed = email.trim();
    final emailRegex =
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailTrimmed.isNotEmpty && emailRegex.hasMatch(emailTrimmed);
  }

  // ✅ Password validation (returns ValidationResult)
  static ValidationResult validatePassword(String password) {
    final errors = <String>[];

    if (password.isEmpty) {
      errors.add('Password is required');
    } else {
      if (password.length < 8) {
        errors.add('Password must be at least 8 characters long');
      }
      if (!password.contains(RegExp(r'[A-Z]'))) {
        errors.add('Password must contain at least one uppercase letter');
      }
      if (!password.contains(RegExp(r'[a-z]'))) {
        errors.add('Password must contain at least one lowercase letter');
      }
      if (!password.contains(RegExp(r'[0-9]'))) {
        errors.add('Password must contain at least one number');
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  // ✅ Name validation
  static ValidationResult validateName(String name) {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Name is required');
    } else if (name.trim().length < 2) {
      errors.add('Name must be at least 2 characters long');
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name.trim())) {
      errors.add('Name can only contain letters and spaces');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  // ✅ Nigerian phone number validation
  static bool isValidPhoneNumber(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^(\+234|234|0)?[789][01]\d{8}$').hasMatch(cleanPhone);
  }

  // ✅ Amount validation
  static ValidationResult validateAmount(String amount,
      {double? minAmount, double? maxAmount}) {
    final errors = <String>[];

    try {
      final value = double.parse(amount);
      if (value <= 0) {
        errors.add('Amount must be greater than zero');
      }

      if (minAmount != null && value < minAmount) {
        errors.add('Minimum amount is ₦${minAmount.toStringAsFixed(2)}');
      }

      if (maxAmount != null && value > maxAmount) {
        errors.add('Maximum amount is ₦${maxAmount.toStringAsFixed(2)}');
      }

      final decimals =
          amount.contains('.') ? amount.split('.')[1].length : 0;
      if (decimals > 2) {
        errors.add('Amount cannot have more than 2 decimal places');
      }
    } catch (e) {
      errors.add('Please enter a valid amount');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  String? get firstError => errors.isNotEmpty ? errors.first : null;
  String get allErrors => errors.join(', ');
}

// ✅ Riverpod provider (optional, for dependency injection)
final validationServiceProvider =
    Provider<ValidationService>((ref) => ValidationService());
