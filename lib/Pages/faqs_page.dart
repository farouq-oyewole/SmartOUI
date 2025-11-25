import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF1B5E20);
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("FAQs"),
        backgroundColor: primaryGreen,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFaq(
              "What is the Credit Score system?",
              "Your credit score reflects your consistency and support for MSSN activities. The more donations and verified participation you have, the higher your score — unlocking new tiers, recognitions, and special rewards."),
          _buildFaq(
              "How do I earn points?",
              "Each donation or verified payment adds points automatically. For example, ₦1,000 equals 10 points. Your total points reflect your contribution range."),
          _buildFaq(
              "How do I view or download my donation profile?",
              "You can view your MSSN donation profile directly on the app and download it as a PDF to keep a personal record of your support."),
          _buildFaq(
              "What kind of events does MSSN OUI organize?",
              "MSSN OUI hosts a wide range of events including Islamic lectures, Ramadan programs, Jumu’ah gatherings, Qur’an competitions, charity outreaches, and campus-wide Da’wah initiatives."),
          _buildFaq(
              "Can I verify my receipt from previous donations?",
              "Yes! The app allows you to scan or upload your receipt QR code and verify it instantly using our smart verification system."),
          _buildFaq(
              "Does the app support dark mode?",
              "Absolutely! The app adapts automatically to your system theme — ensuring a comfortable reading experience anytime."),
          _buildFaq(
              "Who do I contact for help?",
              "You can reach out directly through the 'Help & Support' page to contact us via WhatsApp or email."),
        ],
      ),
    );
  }

  Widget _buildFaq(String question, String answer) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 10, right: 10),
          child: Text(
            answer,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        )
      ],
    );
  }
}
