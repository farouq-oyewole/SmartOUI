// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:bank_app/Pages/terms_privacy_page.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/loading_provider.dart';
import '../providers/notification_provider.dart';
import '../components/custom_button.dart';
import '../components/custom_textfield.dart';
import '../services/validation_service.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final VoidCallback onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 🔐 Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ref.read(notificationProvider.notifier).showError(
        'Terms Required',
        'Please accept the terms and conditions to continue.',
      );
      return;
    }

    try {
      final email = _emailController.text.trim();
      final rawPassword = _passwordController.text.trim();
      final hashedPassword = _hashPassword(rawPassword);

      await ref.read(authNotifierProvider.notifier).createUserWithEmailAndPassword(
        email,
        hashedPassword,
      );

      ref.read(notificationProvider.notifier).showSuccess(
        'Account Created!',
        'Welcome to Banking App! Please verify your email to get started.',
      );
    } catch (e) {
      ref.read(notificationProvider.notifier).showError(
        'Sign Up Failed',
        e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(isDarkModeProvider);
    final authLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance,  
                        size: 50,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join us and start your banking journey',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 48),

                    // Name field
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'Enter your full name',
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (value) {
                        final validation = ValidationService.validateName(value ?? '');
                        return validation.isValid ? null : validation.firstError;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Enter your email',
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!ValidationService.isValidEmail(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Create a password',
                      labelText: 'Password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (value) {
                        final validation = ValidationService.validatePassword(value ?? '');
                        return validation.isValid ? null : validation.firstError;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm password field
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm your password',
                      labelText: 'Confirm Password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Terms checkbox
                    Row(
  children: [
    Checkbox(
      value: _acceptTerms,
      onChanged: (value) => setState(() => _acceptTerms = value ?? false),
      activeColor: Theme.of(context).primaryColor,
    ),
    Expanded(
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            const TextSpan(text: 'I agree to the '),
            TextSpan(
              text: 'Terms of Service',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsPrivacyPage(initialTab: 0),
                      ),
                    ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsPrivacyPage(initialTab: 1),
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  ],
),
                    const SizedBox(height: 24),

                    // Sign up button
                    PrimaryButton(
                      text: 'Create Account',
                      onPressed: _signUp,
                      isLoading: authLoading,
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR',
                              style: TextStyle(
                                  color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
