// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../utils/responsive_helper.dart';

/// A single screen that presents both the Terms of Service and Privacy Policy.
/// `initialTab` – 0 ➜ Terms first, 1 ➜ Privacy first.
class TermsPrivacyPage extends ConsumerWidget {
  const TermsPrivacyPage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return DefaultTabController(
      initialIndex: initialTab,
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          title: const Text('Legal Information'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Terms of Service'),
              Tab(text: 'Privacy Policy'),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
            child: TabBarView(
              children: [
                _DocumentView(title: 'Terms of Service', sections: _termsSections),
                _DocumentView(title: 'Privacy Policy', sections: _privacySections),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*────────────────────────────  Helpers  ────────────────────────────*/

/// Reusable scrollable document viewer.
class _DocumentView extends StatelessWidget {
  const _DocumentView({required this.title, required this.sections});
  final String title;
  final List<_DocSection> sections;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
        child: ListView.separated(
          itemCount: sections.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (ctx, idx) {
            if (idx == 0) {
              return Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              );
            }
            final section = sections[idx - 1];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.heading,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  section.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Simple data holder for each document section.
class _DocSection {
  final String heading;
  final String body;
  const _DocSection(this.heading, this.body);
}

/*──────────────────────────  Content  ──────────────────────────────*/
// You can refine this wording as needed.

const List<_DocSection> _termsSections = [
  _DocSection(
    '1. Introduction',
    'Welcome to SmartOUI Bank App. By creating an account or using our services, you agree to be bound by these Terms '
    'of Service. Please read them carefully.',
  ),
  _DocSection(
    '2. Eligibility',
    'You must be at least 18 years old (or the age of majority in your jurisdiction) to open or operate an account. '
    'Institutional users must ensure that the representative registering has full authority.',
  ),
  _DocSection(
    '3. Account Security',
    '• Keep your login credentials confidential.\n'
    '• You are responsible for all activities that occur under your account.\n'
    '• Notify us immediately of any unauthorized use.',
  ),
  _DocSection(
    '4. Transactions & Fees',
    'All transactions processed through the app—including tuition, hostel, clearance, and other fees—are final once '
    'confirmed. A 1.5% processing fee is automatically applied to each payment and will appear on your receipt.',
  ),
  _DocSection(
    '5. Prohibited Conduct',
    'You agree not to:\n'
    '• Violate any applicable law or regulation.\n'
    '• Interfere with or disrupt the app’s operation.\n'
    '• Use the platform for fraudulent or malicious purposes.',
  ),
  _DocSection(
    '6. Termination',
    'We reserve the right to suspend or terminate your account at any time for violations of these Terms or for '
    'security reasons.',
  ),
  _DocSection(
    '7. Changes to Terms',
    'We may modify these Terms at any time. Continued use after updates constitutes acceptance of the revised Terms.',
  ),
  _DocSection(
    '8. Contact',
    'Questions?  Reach us at support@smartoui.app.',
  ),
];

const List<_DocSection> _privacySections = [
  _DocSection(
    '1. Information We Collect',
    '• Personal data: name, email, phone number, matric number, etc.\n'
    '• Financial data: card‑last‑4, account balances, and transaction history.\n'
    '• Device data: IP address, OS version, and app usage statistics.',
  ),
  _DocSection(
    '2. How We Use Information',
    'We use your data to:\n'
    '• Facilitate secure payments and receipts.\n'
    '• Provide customer support.\n'
    '• Improve our products and detect fraud.',
  ),
  _DocSection(
    '3. Data Sharing',
    'Your data is never sold. We only share it with:\n'
    '• Payment processors and partner banks to complete your transactions.\n'
    '• Regulators or law‑enforcement if required by law.',
  ),
  _DocSection(
    '4. Security',
    'SmartOUI employs industry‑standard encryption, secure storage, and regular security audits to protect your data.',
  ),
  _DocSection(
    '5. Data Retention',
    'We retain your information as long as you maintain an account or as necessary to comply with legal obligations.',
  ),
  _DocSection(
    '6. Your Rights',
    'You may access, correct, or delete your personal data at any time by contacting support.',
  ),
  _DocSection(
    '7. Changes to Policy',
    'We will notify you of significant changes via email or in‑app alert. Continued use of the app constitutes '
    'acceptance of the revised policy.',
  ),
  _DocSection(
    '8. Contact',
    'Privacy concerns?  Email farouqoye@gmail.com.',
  ),
];
