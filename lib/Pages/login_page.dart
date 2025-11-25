// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:convert';
import 'package:bank_app/Pages/admin_page.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../components/custom_button.dart';
import '../components/custom_textfield.dart';
import '../services/validation_service.dart';

/// Local loading flag for this screen
final authLoadingProvider = StateProvider<bool>((_) => false);

class LoginPage extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _hashPassword(String raw) {
    final bytes = utf8.encode(raw);
    return sha256.convert(bytes).toString();
  }

 Future<void> _signIn() async {
  if (!_formKey.currentState!.validate()) return;

  ref.read(authLoadingProvider.notifier).state = true;

  try {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // ✅ Admin credentials (plain-text check)
    const adminEmail1 = 'mssnadmin@gmail.com';
    const adminPassword1 = 'Subhanallah99';
    const adminEmail2 = 'mssnadmin2@gmail.com';
    const adminPassword2 = 'SuperSecret456';

    if ((email == adminEmail1 && password == adminPassword1) ||
        (email == adminEmail2 && password == adminPassword2)) {
      // Navigate directly to AdminPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPage()),
        );
      }
      return; // Skip Firebase login
    }

    // 🔹 Normal user login via Firebase
    final hashed = _hashPassword(password);

    await ref
        .read(authNotifierProvider.notifier)
        .signInWithEmailAndPassword(email, hashed, context);

    // Show success notification
    if (mounted) {
      ref.read(notificationProvider.notifier).showSuccess(
        'Welcome Back!',
        'You have successfully signed in.',
      );
    }
  } catch (e) {
    if (mounted) {
      ref.read(notificationProvider.notifier).showError(
        'Sign-in Failed',
        e.toString(),
      );
    }
  } finally {
    if (mounted) ref.read(authLoadingProvider.notifier).state = false;
  }
}



  @override
  Widget build(BuildContext context) {
    ref.watch(isDarkModeProvider);
    final isLoading = ref.watch(authLoadingProvider);

    // ─── MSSN-OUI Green & White Theme ─────────────────────
    final Color primaryGreen = const Color(0xFF007A33);
    final Color lightGreen = const Color(0xFFE6F4EA);
    final Color textDark = const Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: lightGreen,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ─── Logo ────────────────────────────────────
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/mssn.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 32),
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your MSSN-OUI account',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                    const SizedBox(height: 48),

                    // ─── Email ───────────────────────────────────
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Enter your email',
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icon(Icons.email_outlined, color: primaryGreen),
                      validator: (v) {
  if (v == null || v.isEmpty) {
    return 'Email is required';
  } else if (!ValidationService.isValidEmail(v)) {
    return 'Enter a valid email';
  }
  return null;
},
                    ),
                    const SizedBox(height: 16),

                    // ─── Password ───────────────────────────────
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Enter your password',
                      labelText: 'Password',
                      obscureText: true,
                      prefixIcon: Icon(Icons.lock_outline, color: primaryGreen),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Password required' : null,
                    ),
                    const SizedBox(height: 16),

                    // ─── Remember Me ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          activeColor: primaryGreen,
                        ),
                        Text(
                          'Remember me',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Sign-in Button ─────────────────────────
                    PrimaryButton(
                      text: 'Sign In',
                      isLoading: isLoading,
                      onPressed: _signIn,
                      color: primaryGreen,
                    ),
                    const SizedBox(height: 24),

                    // ─── Divider ────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                            child:
                                Divider(color: Colors.grey[300], thickness: 1)),
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
                            child:
                                Divider(color: Colors.grey[300], thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Google & Facebook Buttons ───────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () {
                              
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/images/google.png',
                                    width: 22, height: 22),
                                const SizedBox(width: 10),
                                const Text(
                                  'Google',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () {
                              
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/images/facebook.png',
                                    width: 22, height: 22),
                                const SizedBox(width: 10),
                                const Text(
                                  'Facebook',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ─── Sign-up Link ───────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: primaryGreen,
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
