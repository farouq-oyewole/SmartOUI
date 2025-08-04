import 'package:flutter_riverpod/flutter_riverpod.dart';

class ValidationService {
  // Email validation
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Password validation
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
      if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        errors.add('Password must contain at least one special character');
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  // Phone number validation
  static bool isValidPhoneNumber(String phone) {
    // Nigerian phone number validation
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^(\+234|234|0)?[789][01]\d{8}$').hasMatch(cleanPhone);
  }

  // Card number validation (Luhn algorithm)
  static bool isValidCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    int sum = 0;
    bool alternate = false;
    
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }

  // CVV validation
  static bool isValidCVV(String cvv, String cardNumber) {
    final cleanCVV = cvv.replaceAll(RegExp(r'\D'), '');
    final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    // American Express cards have 4-digit CVV
    if (cleanCardNumber.startsWith('34') || cleanCardNumber.startsWith('37')) {
      return cleanCVV.length == 4;
    }
    
    // Other cards have 3-digit CVV
    return cleanCVV.length == 3;
  }

  // Expiry date validation
  static bool isValidExpiryDate(String month, String year) {
    try {
      final monthInt = int.parse(month);
      final yearInt = int.parse(year);
      
      if (monthInt < 1 || monthInt > 12) {
        return false;
      }
      
      final now = DateTime.now();
      final currentYear = now.year % 100; // Get last 2 digits
      final currentMonth = now.month;
      
      if (yearInt < currentYear) {
        return false;
      }
      
      if (yearInt == currentYear && monthInt < currentMonth) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Amount validation
  static ValidationResult validateAmount(String amount, {double? minAmount, double? maxAmount}) {
    final errors = <String>[];
    
    try {
      final amountValue = double.parse(amount);
      
      if (amountValue <= 0) {
        errors.add('Amount must be greater than zero');
      }
      
      if (minAmount != null && amountValue < minAmount) {
        errors.add('Amount must be at least \$${minAmount.toStringAsFixed(2)}');
      }
      
      if (maxAmount != null && amountValue > maxAmount) {
        errors.add('Amount cannot exceed \$${maxAmount.toStringAsFixed(2)}');
      }
      
      // Check for reasonable decimal places
      final decimalPlaces = amount.split('.').length > 1 ? amount.split('.')[1].length : 0;
      if (decimalPlaces > 2) {
        errors.add('Amount cannot have more than 2 decimal places');
      }
      
    } catch (e) {
      errors.add('Please enter a valid amount');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  // PIN validation
  static ValidationResult validatePIN(String pin) {
    final errors = <String>[];
    
    if (pin.length != 4 && pin.length != 6) {
      errors.add('PIN must be 4 or 6 digits');
    }
    
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      errors.add('PIN must contain only numbers');
    }
    
    // Check for sequential numbers
    if (_isSequential(pin)) {
      errors.add('PIN cannot be sequential numbers');
    }
    
    // Check for repeated numbers
    if (_isRepeated(pin)) {
      errors.add('PIN cannot be all the same number');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  // Account number validation
  static bool isValidAccountNumber(String accountNumber) {
    final cleanNumber = accountNumber.replaceAll(RegExp(r'\D'), '');
    return cleanNumber.length >= 8 && cleanNumber.length <= 17;
  }

  // Routing number validation
  static bool isValidRoutingNumber(String routingNumber) {
    final cleanNumber = routingNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.length != 9) {
      return false;
    }
    
    // ABA routing number checksum validation
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      int digit = int.parse(cleanNumber[i]);
      int weight = [3, 7, 1, 3, 7, 1, 3, 7, 1][i];
      sum += digit * weight;
    }
    
    return sum % 10 == 0;
  }

  // Name validation
  static ValidationResult validateName(String name) {
    final errors = <String>[];
    
    if (name.isEmpty) {
      errors.add('Name is required');
    } else if (name.trim().length < 2) {
      errors.add('Name must be at least 2 characters long');
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      errors.add('Name can only contain letters and spaces');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  // Transfer description validation
  static ValidationResult validateDescription(String description) {
    final errors = <String>[];
    
    if (description.trim().isEmpty) {
      errors.add('Description is required');
    }
    
    if (description.trim().length < 3) {
      errors.add('Description must be at least 3 characters long');
    }
    
    if (description.trim().length > 100) {
      errors.add('Description must not exceed 100 characters');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  // Comprehensive form validation
  static Map<String, ValidationResult> validateTransferForm({
    required String recipientName,
    required String accountNumber,
    required String amount,
    required String description,
    String? routingNumber,
  }) {
    return {
      'recipientName': validateName(recipientName),
      'accountNumber': ValidationResult(
        isValid: isValidAccountNumber(accountNumber),
        errors: isValidAccountNumber(accountNumber) ? [] : ['Invalid account number'],
      ),
      'amount': validateAmount(amount, minAmount: 1.0, maxAmount: 10000.0),
      'description': validateDescription(description),
      if (routingNumber != null)
        'routingNumber': ValidationResult(
          isValid: isValidRoutingNumber(routingNumber),
          errors: isValidRoutingNumber(routingNumber) ? [] : ['Invalid routing number'],
        ),
    };
  }

  // Payment form validation
  static Map<String, ValidationResult> validatePaymentForm({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String cardHolderName,
    required String amount,
  }) {
    return {
      'cardNumber': ValidationResult(
        isValid: isValidCardNumber(cardNumber),
        errors: isValidCardNumber(cardNumber) ? [] : ['Invalid card number'],
      ),
      'expiryDate': ValidationResult(
        isValid: isValidExpiryDate(expiryMonth, expiryYear),
        errors: isValidExpiryDate(expiryMonth, expiryYear) ? [] : ['Invalid expiry date'],
      ),
      'cvv': ValidationResult(
        isValid: isValidCVV(cvv, cardNumber),
        errors: isValidCVV(cvv, cardNumber) ? [] : ['Invalid CVV'],
      ),
      'cardHolderName': validateName(cardHolderName),
      'amount': validateAmount(amount, minAmount: 1.0),
    };
  }

  // Helper methods
  static bool _isSequential(String pin) {
    for (int i = 0; i < pin.length - 1; i++) {
      int current = int.parse(pin[i]);
      int next = int.parse(pin[i + 1]);
      if (next != current + 1) {
        return false;
      }
    }
    return true;
  }

  static bool _isRepeated(String pin) {
    return pin.split('').every((digit) => digit == pin[0]);
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, this.errors = const []});

  String? get firstError => errors.isNotEmpty ? errors.first : null;
  String get allErrors => errors.join(', ');
}

final validationServiceProvider = Provider<ValidationService>((ref) => ValidationService());
