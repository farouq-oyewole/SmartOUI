// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/loading_provider.dart';
import '../components/custom_button.dart';
import '../components/custom_textfield.dart';
import '../services/validation_service.dart';
import 'login_or_register_page.dart';
import 'main_navigation_page.dart';

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(currentAppUserProvider);
    final isLoading = ref.watch(authLoadingProvider);

    if (isLoading) return const AuthLoadingScreen();

    // if user not logged in, show login/signup
    if (appUser == null) {
      return const LoginOrSignupPage();
    }

    // if user profile is incomplete
    if (appUser.name.isEmpty || appUser.phoneNumber == null) {
      return const UserSetupPage();
    }

    // otherwise go to main navigation
    return const MainNavigationPage();
  }
}

class AuthLoadingScreen extends ConsumerWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔹 Replaceable logo
            Image.asset(
              'assets/images/mssn.png', // your preferred local logo
              height: 100,
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'MSSN OUI',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparing your Islamic dashboard...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserSetupPage extends ConsumerStatefulWidget {
  const UserSetupPage({super.key});

  @override
  ConsumerState<UserSetupPage> createState() => _UserSetupPageState();
}

class _UserSetupPageState extends ConsumerState<UserSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _setupUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authNotifierProvider.notifier).updateUserProfile(
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
          );

      ref.invalidate(currentAppUserProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to setup profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authLoading = ref.watch(authLoadingProvider);
    final appUser = ref.watch(currentAppUserProvider);

    return Scaffold(
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🔹 Replaceable logo
                    Image.asset(
                      'assets/images/mssn.png',
                      height: 100,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Complete Your Profile',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'As-salamu Alaykum, ${appUser?.email ?? 'dear user'}!\nLet’s complete your MSSN OUI profile to get started.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'Enter your full name',
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (value) {
                        final validation =
                            ValidationService.validateName(value ?? '');
                        return validation.isValid ? null : validation.firstError;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      hintText: 'Enter your phone number (optional)',
                      labelText: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          return ValidationService.isValidPhoneNumber(value)
                              ? null
                              : 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: 'Complete Setup',
                      onPressed: _setupUser,
                      isLoading: authLoading,
                    ),
                    const SizedBox(height: 16),
                    SecondaryButton(
                      text: 'Sign Out',
                      onPressed: authLoading
                          ? null
                          : () => ref.read(authNotifierProvider.notifier).signOut(),
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
