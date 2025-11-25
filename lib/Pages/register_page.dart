// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/loading_provider.dart';
import '../providers/notification_provider.dart';
import '../components/custom_button.dart';
import '../components/custom_textfield.dart';
import '../services/validation_service.dart';
import 'terms_privacy_page.dart';

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

      await ref
          .read(authNotifierProvider.notifier)
          .createUserWithEmailAndPassword(email, hashedPassword);

      ref.read(notificationProvider.notifier).showSuccess(
            'Account Created!',
            'Welcome to MSSN OUI! Please verify your email to continue.',
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
    final authLoading = ref.watch(authLoadingProvider);

    // 🟢 Define MSSN OUI greenish-white theme colors
    const Color mssnGreen = Color(0xFF2E7D32); // deep Islamic green
    const Color lightGreen = Color(0xFFE8F5E9); // light green tint
    const Color whiteColor = Colors.white;

    return Scaffold(
      backgroundColor: lightGreen,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: mssnGreen.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 3,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✅ MSSN Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: lightGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: mssnGreen.withOpacity(0.15),
                            blurRadius: 6,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        "assets/images/mssn.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ✅ Title
                    Text(
                      'Create Account',
                      style: TextStyle(
                        color: mssnGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join the MSSN OUI community today',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ✅ Full name
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'Enter your full name',
                      labelText: 'Full Name',
                      prefixIcon:
                          const Icon(Icons.person_outline, color: mssnGreen),
                      validator: (value) {
                        final validation =
                            ValidationService.validateName(value ?? '');
                        return validation.isValid
                            ? null
                            : validation.firstError;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ✅ Email
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Enter your email',
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon:
                          const Icon(Icons.email_outlined, color: mssnGreen),
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

                    // ✅ Password
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Create a password',
                      labelText: 'Password',
                      obscureText: true,
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: mssnGreen),
                      validator: (value) {
                        final validation =
                            ValidationService.validatePassword(value ?? '');
                        return validation.isValid
                            ? null
                            : validation.firstError;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ✅ Confirm Password
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm your password',
                      labelText: 'Confirm Password',
                      obscureText: true,
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: mssnGreen),
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

                    // ✅ Terms Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) =>
                              setState(() => _acceptTerms = value ?? false),
                          activeColor: mssnGreen,
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    color: mssnGreen,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const TermsPrivacyPage(
                                                    initialTab: 0),
                                          ),
                                        ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: mssnGreen,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const TermsPrivacyPage(
                                                    initialTab: 1),
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

                    // ✅ Create Account button
                    CustomButton(
                      text: 'Create Account',
                      onPressed: _signUp,
                      isLoading: authLoading,
                      backgroundColor: mssnGreen,
                      textColor: whiteColor,
                    ),

                    const SizedBox(height: 24),

                    // ✅ Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ✅ Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: mssnGreen,
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
