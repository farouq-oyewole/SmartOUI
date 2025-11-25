// ignore_for_file: file_names, unused_element, deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:bank_app/Pages/about_mssn_oui_page.dart';
import 'package:bank_app/Pages/faqs_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/responsive_helper.dart';

/// ----------------------
/// Placeholder Pages
/// ----------------------

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage>
    with TickerProviderStateMixin {
  final String donateLink = 'https://your-donation-link.com'; // 🔗 Replace manually

  late AnimationController _gradientController;
  late AnimationController _pointsController;
  late AnimationController _buttonController;

  late Animation<Alignment> _topAlignment;
  late Animation<Alignment> _bottomAlignment;
  late List<Animation<double>> _pointAnimations;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> donationTiers = [
    {'amount': '₦1,000 - ₦5,000', 'min': 10.0, 'max': 50.0},
    {'amount': '₦6,000 - ₦10,000', 'min': 60.0, 'max': 100.0},
    {'amount': '₦11,000 - ₦15,000', 'min': 110.0, 'max': 150.0},
    {'amount': '₦16,000 - ₦20,000', 'min': 160.0, 'max': 200.0},
    {'amount': '₦21,000 - ₦25,000', 'min': 210.0, 'max': 250.0}, // 🆕 Added Tier
    {'amount': '₦26,000 - ₦30,000', 'min': 260.0, 'max': 300.0}, // 🆕 Added Tier
  ];

  @override
  void initState() {
    super.initState();

    // 🌈 Animated gradient shimmer
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _topAlignment = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );

    _bottomAlignment = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
    ).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );

    // 🎯 Points animation
    _pointsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pointAnimations = donationTiers
        .map(
          (tier) => Tween<double>(
            begin: 0,
            end: tier['max'] as double,
          ).animate(
            CurvedAnimation(
              parent: _pointsController,
              curve: Curves.easeOutCubic,
            ),
          ),
        )
        .toList();

    // 🎯 Button animation
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _buttonController, curve: Curves.easeIn);

    // Start animations
    _pointsController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _pointsController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _launchDonationLink() async {
    final Uri url = Uri.parse(donateLink);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open donation link")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const mssnGreen = Color(0xFF2E7D32);
    const lightGreen = Color(0xFF66BB6A);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _topAlignment.value,
                end: _bottomAlignment.value,
                colors: const [mssnGreen, lightGreen],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔙 Floating back button
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white.withOpacity(0.95),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Support MSSN OUI',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Earn credit points for every donation you make',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.4)
                                : Colors.grey.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Donation Tiers',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: donationTiers.length,
                              itemBuilder: (context, index) {
                                final tier = donationTiers[index];
                                return AnimatedBuilder(
                                  animation: _pointsController,
                                  builder: (context, child) {
                                    final currentPoints =
                                        _pointAnimations[index].value;
                                    final minPoints = tier['min'] as double;
                                    final maxPoints = tier['max'] as double;
                                    final displayedMin =
                                        (currentPoints < minPoints
                                                ? currentPoints
                                                : minPoints)
                                            .toInt();
                                    final displayedMax =
                                        currentPoints.toInt().clamp(
                                              minPoints,
                                              maxPoints,
                                            );

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 18),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? mssnGreen.withOpacity(0.15)
                                            : lightGreen.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark
                                              ? lightGreen.withOpacity(0.4)
                                              : mssnGreen.withOpacity(0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            tier['amount'],
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            '$displayedMin - $displayedMax pts',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: isDark
                                                  ? lightGreen
                                                  : mssnGreen,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: ElevatedButton(
                                onPressed: _launchDonationLink,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mssnGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Text(
                                  'Donate Now',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


class DonationHistoryPage extends StatelessWidget {
  const DonationHistoryPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Donation History")),
        body: const Center(child: Text("Donation History Page (Coming Soon)")),
      );
}

class HelpAndSupportPage extends StatefulWidget {
  const HelpAndSupportPage({super.key});

  @override
  State<HelpAndSupportPage> createState() => _HelpAndSupportPageState();
}

class _HelpAndSupportPageState extends State<HelpAndSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  final Color primaryGreen = const Color(0xFF1B5E20);

  Future<void> _sendEmail() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final message = _messageController.text;

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'mssn_support@gmail.com',
      queryParameters: {
        'subject': 'MSSN OUI App Issue Report from $name',
        'body': 'Name: $name\nEmail: $email\n\nMessage:\n$message',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsapp = Uri.parse("https://wa.me/2348101473273");
    if (await canLaunchUrl(whatsapp)) {
      await launchUrl(whatsapp, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.black, Colors.grey[900]!]
                : [primaryGreen.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back,
                        color: isDark ? Colors.white : primaryGreen, size: 26),
                    const SizedBox(width: 6),
                    Text(
                      "Back",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Title
              Text(
                "Help & Support",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryGreen,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We’re here to help! Access resources or report an issue below.",
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 30),

              // Support Cards
              _buildSupportCard(
                icon: Icons.help_outline,
                title: "FAQs",
                description: "Find answers to common questions about the app.",
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const FaqPage())),
              ),
              const SizedBox(height: 18),
              _buildSupportCard(
                icon: Icons.contact_support_outlined,
                title: "Contact Us",
                description:
                    "Need personal help? Chat with our support via WhatsApp.",
                onTap: _launchWhatsApp,
              ),
              const SizedBox(height: 18),
              _buildSupportCard(
                icon: Icons.info_outline,
                title: "About MSSN OUI",
                description:
                    "Learn about our mission, goals, and activities on campus.",
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AboutMssnOuiPage())),
              ),

              const SizedBox(height: 40),

              // Report an Issue form
              Text(
                "Report an Issue",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryGreen,
                ),
              ),
              const SizedBox(height: 15),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: "Name",
                      icon: Icons.person_outline,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email_outlined,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _messageController,
                      label: "Message",
                      icon: Icons.message_outlined,
                      isDark: isDark,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _sendEmail();
                          }
                        },
                        icon: const Icon(Icons.send_rounded),
                        label: const Text("Send Report",
                            style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  const Color(0xFF1B5E20).withOpacity(0.15),
              radius: 24,
              child: Icon(icon, color: const Color(0xFF1B5E20), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      )),
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter $label' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
        labelStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[800],
            fontWeight: FontWeight.w500),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
        ),
      ),
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
    );
  }
}


/// ----------------------
/// QR Code Display Page
/// ----------------------
class QrCodePage extends StatefulWidget {
  final String userId;
  const QrCodePage({super.key, required this.userId});

  @override
  State<QrCodePage> createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final profileLink = "https://myapp.com/user/${widget.userId}";
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My QR Code"),
        centerTitle: true,
      ),
      body: Center(
        child: Screenshot(
          controller: _screenshotController,
          child: Card(
            elevation: 8,
            color: card,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "MSSN Profile QR",
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: profileLink,
                    version: QrVersions.auto,
                    size: 230.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Scan this QR to view my MSSN Profile",
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------------
/// PROFILE CARD PREVIEW PAGE
/// ----------------------
class ProfileCardPreviewPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String tier;
  final ImageProvider<Object>? image;
  const ProfileCardPreviewPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.tier,
    this.image,
  });

  @override
  State<ProfileCardPreviewPage> createState() => _ProfileCardPreviewPageState();
}

class _ProfileCardPreviewPageState extends State<ProfileCardPreviewPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final profileLink = "https://myapp.com/user/${widget.userId}";
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Card Preview")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            children: [
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  width: 600,
                  height: 520,
                  margin: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0B6623),
                        Color(0xFF2E7D32),
                        Color(0xFF66BB6A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.55, 1.0],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundImage: widget.image,
                        backgroundColor: Colors.white24,
                        child: widget.image == null
                            ? const Icon(
                                Icons.account_circle_rounded,
                                color: Colors.white70,
                                size: 80,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Tier: ${widget.tier}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      QrImageView(
                        data: profileLink,
                        size: 150,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "MSSN OUI  Profile",
                        style: TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "#GivingBackWithFaith 💚",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------
/// MAIN PROFILE PAGE
/// ----------------------
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  File? _selectedImage;
  double donatedAmount = 0.0;

  final double bronzeTarget = 200.0;
  final double silverTarget = 300.0;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (picked != null) {
      final base64 = base64Encode(await picked.readAsBytes());
      setState(() => _selectedImage = File(picked.path));
      await ref.read(authNotifierProvider.notifier).updateUserPhoto(
            imageData: base64,
            isLocalFile: false,
          );
      ref.invalidate(currentAppUserProvider);
    }
  }

  void _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri uri = Uri.parse("https://wa.me/2348058999616");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open WhatsApp")),
      );
    }
  }

  Map<String, dynamic> _getTierInfo(double amount) {
    if (amount <= 0) return {"name": "New Tier", "target": bronzeTarget};
    if (amount < bronzeTarget) return {"name": "Bronze", "target": bronzeTarget};
    if (amount < silverTarget) return {"name": "Silver", "target": silverTarget};
    return {"name": "Gold", "target": silverTarget};
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final primary = isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF1F8F6);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final text = isDark ? Colors.white : Colors.black87;

    ImageProvider<Object>? img;
    if (_selectedImage != null) {
      img = FileImage(_selectedImage!);
    } else if (user?.photoUrl?.isNotEmpty ?? false) {
      img = MemoryImage(base64Decode(user!.photoUrl!));
    }

    final tier = _getTierInfo(donatedAmount)["name"];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsiveMargin(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Profile",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),
                  if (user?.id != null)
                    IconButton(
                      icon: const Icon(Icons.qr_code_2_rounded, size: 28),
                      color: primary,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrCodePage(userId: user!.id),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              /// PROFILE IMAGE
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: img,
                      backgroundColor:
                          isDark ? Colors.grey[850] : Colors.white,
                      child: img == null
                          ? Icon(Icons.account_circle_rounded,
                              size: 70, color: primary)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Edit Picture"),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primary),
                        foregroundColor: primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? "User",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              /// PROFILE CARD PREVIEW NAV
              Card(
                elevation: 4,
                shadowColor: primary.withOpacity(0.3),
                color: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.card_membership_rounded, color: Colors.white),
                  title: const Text("View Profile Card",
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                    "View your MSSN Profile Card",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  onTap: () {
                    if (user?.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileCardPreviewPage(
                            userId: user!.id,
                            userName: user.name,
                            tier: tier,
                            image: img,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              /// NAVIGATION BUTTONS
              _buildNavItem(Icons.volunteer_activism_rounded,
                  "Donate for MSSN", primary,  const DonatePage(), cardColor),
              _buildNavItem(Icons.history_rounded, "Donation History", primary,
                  const DonationHistoryPage(), cardColor),
              _buildNavItem(Icons.developer_mode_rounded,
                  "Reach Out to Developers", primary, null, cardColor,
                  customAction: _openWhatsApp),
              _buildNavItem(Icons.help_outline_rounded, "Help & Support",
                  primary, const HelpAndSupportPage(), cardColor),

              const SizedBox(height: 30),

              /// SIGN OUT + DARK MODE
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dark_mode_rounded, color: text),
                  const SizedBox(width: 6),
                  Text(
                    "Dark Mode",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: text,
                    ),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (v) {
                      ref
                          .read(themeModeProvider.notifier)
                          .toggleTheme();
                    },
                    activeColor: primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aesthetic Nav Item
  Widget _buildNavItem(
    IconData icon,
    String title,
    Color color,
    Widget? page,
    Color cardColor, {
    VoidCallback? customAction,
  }) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color, size: 26),
        title: Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.w500, color: color, fontSize: 15),
        ),
        trailing:
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
        onTap: () {
          if (customAction != null) {
            customAction();
          } else if (page != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          }
        },
      ),
    );
  }
}
