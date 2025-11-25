// ignore_for_file: deprecated_member_use

import 'package:bank_app/Pages/login_page.dart';
import 'package:bank_app/Pages/register_page.dart';
import 'package:bank_app/Providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/responsive_helper.dart';

class LoginOrSignupPage extends ConsumerStatefulWidget {
  const LoginOrSignupPage({super.key});

  @override
  ConsumerState<LoginOrSignupPage> createState() => _LoginOrSignupPageState();
}

class _LoginOrSignupPageState extends ConsumerState<LoginOrSignupPage>
    with TickerProviderStateMixin {
  bool showLoginPage = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void togglePages() {
    _animationController.reverse().then((_) {
      setState(() {
        showLoginPage = !showLoginPage;
      });
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF0B3D2E),
                    const Color(0xFF064E3B),
                    const Color(0xFF052E21),
                  ]
                : [
                    const Color(0xFFE8F5E9),
                    const Color(0xFFD0F0C0),
                    const Color(0xFFA5D6A7),
                  ],
          ),
        ),
        child: isDesktop
            ? _buildDesktopLayout()
            : isTablet
                ? _buildTabletLayout()
                : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Branding and Features (Left)
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandingSection(),
                const SizedBox(height: 48),
                _buildFeaturesList(),
              ],
            ),
          ),
        ),

        // Auth Form (Right)
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade200.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _buildAuthForm(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade100.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(32),
              child: _buildBrandingSection(),
            ),
            Expanded(child: _buildAuthForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return _buildAuthForm();
  }

  Widget _buildBrandingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child:Image.asset(
  'assets/images/mssn.png',
  width: 80,
  height: 80,
  fit: BoxFit.contain,
)

        ),
        const SizedBox(height: 24),

        // App Name
        Text(
          'MSSN_OUI Islamic App',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.green.shade900,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Stay connected spiritually — Read Qur’an, track Salah, join events, and grow your Deen.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.green.shade700,
                fontSize: 16,
              ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.menu_book_rounded,
        'title': 'Qur’an Reading Progress',
        'description': 'Continue from where you stopped and mark your memorization.',
      },
      {
        'icon': Icons.access_time_filled,
        'title': 'Prayer Reminders',
        'description': 'Get notified when it’s time for Salah, wherever you are.',
      },
      {
        'icon': Icons.star_rounded,
        'title': 'Weekly Challenges',
        'description': 'Earn credits and climb the leaderboard by participating.',
      },
      {
        'icon': Icons.people_alt_rounded,
        'title': 'Community Events',
        'description': 'Stay updated with MSSN_OUI programs and announcements.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: Colors.green.shade800,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAuthForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: showLoginPage
          ? LoginPage(onTap: togglePages)
          : RegisterPage(onTap: togglePages),
    );
  }
}
