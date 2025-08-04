// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:convert';
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
  final _formKey               = GlobalKey<FormState>();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  bool _rememberMe             = false;

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

  //  Email / Password Sign‑in
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authLoadingProvider.notifier).state = true;   // start spinner

    try {
      final hashed = _hashPassword(_passwordController.text.trim());

      await ref
          .read(authNotifierProvider.notifier)
          .signInWithEmailAndPassword(
            _emailController.text.trim(),
            hashed,
          );

      ref.read(notificationProvider.notifier).showSuccess(
        'Welcome Back!',
        'You have successfully signed in.',
      );
    } catch (e) {
      ref.read(notificationProvider.notifier).showError(
        'Sign‑in Failed',
        e.toString(),
      );
    } finally {
      ref.read(authLoadingProvider.notifier).state = false; // stop spinner
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    ref.watch(isDarkModeProvider);
    final isLoading   = ref.watch(authLoadingProvider);

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

                    // ─── Logo ────────────────────────────────────
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.account_balance,
                          size: 50, color: Theme.of(context).primaryColor),
                    ),

                    const SizedBox(height: 32),

                    Text('Welcome Back',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Sign in to your banking account',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.grey[600])),
                    const SizedBox(height: 48),

                    // ─── Email ───────────────────────────────────
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Enter your email',
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email required';
                        if (!ValidationService.isValidEmail(v)) {
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
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Password required' : null,
                    ),
                    const SizedBox(height: 16),

                    // ─── Remember & Forgot ──────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() {
                              _rememberMe = v ?? false;
                            }),
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          Text('Remember me',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Sign‑in Button ─────────────────────────
                    PrimaryButton(
                      text: 'Sign In',
                      isLoading: isLoading,
                      onPressed: _signIn,
                    ),
                    const SizedBox(height: 24),

                    // ─── Divider ────────────────────────────────
                    Row(children: [
                      Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1)),
                    ]),
                    const SizedBox(height: 24),
                    // ─── Sign‑up Link ───────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Don\'t have an account? ',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[600])),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text('Sign Up',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold)),
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
