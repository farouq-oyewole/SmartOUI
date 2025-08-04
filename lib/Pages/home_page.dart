// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:bank_app/Providers/auth_provider.dart';
import 'package:bank_app/Providers/notification_provider.dart';
import 'package:bank_app/components/transaction_history.dart';
import 'package:bank_app/models/user_model.dart';
import 'package:bank_app/providers/balance_provider.dart';
import 'package:bank_app/providers/theme_provider.dart';
import 'package:bank_app/providers/transaction_provider.dart';
import 'package:bank_app/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool isObscured = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final ProviderSubscription<int> _notificationSub;

  @override
  void initState() {
    super.initState();

    // Properly listen to notification count changes
    _notificationSub = ref.listenManual<int>(
      unreadNotificationsCountProvider,
      (previous, next) {
        if ((previous ?? 0) < next) {
          _playNotificationSound();
        }
      },
    );
  }

  @override
  void dispose() {
    _notificationSub.close(); // Prevent memory leak
    super.dispose();
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint('Sound playback error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(currentAppUserProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final transactionListAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentAppUserProvider);
            ref.invalidate(balanceProvider);
            ref.invalidate(transactionsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context, appUser?.name ?? 'User', unreadCount, appUser?.photoUrl),
              const SizedBox(height: 20),
              _buildBalanceCard(context, appUser),
              const SizedBox(height: 24),
              const _ActionButtons(),
              const SizedBox(height: 24),
              transactionListAsync.when(
                data: (transactions) {
                  final recent = transactions.take(3).toList();
                  return TransactionHistory(
                    transactions: recent,
                    onSeeAll: () => Navigator.pushNamed(context, '/transactions'),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text("Error: $error")),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, int notifications, String? photoUrl) {
    final isDark = ref.watch(isDarkModeProvider);
    return Row(
      children: [
        GestureDetector(
          onTap: () => _pickAndUpdateImage(ref),
          child: CircleAvatar(
            radius: 24,
            backgroundImage: photoUrl != null
                ? MemoryImage(base64Decode(photoUrl))
                : const AssetImage("assets/images/profile.png") as ImageProvider,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning!',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
              ),
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              icon: Icon(
                Icons.notifications_none_rounded,
                size: 27,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (notifications > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    notifications > 9 ? '9+' : notifications.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, AppUser? user) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final masked = '₦•••••••';

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Balance", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                isObscured ? masked : Formatters.formatCurrency(user.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => isObscured = !isObscured),
                child: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _formatCardNumber(user.cardNumber),
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              const Icon(Icons.credit_card, color: Colors.amber),
              const SizedBox(width: 6),
              const Icon(Icons.circle, size: 16, color: Colors.red),
              const Icon(Icons.circle, size: 16, color: Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCardNumber(String cardNumber) {
    if (cardNumber.isEmpty) return '•••• •••• •••• ••••';
    return cardNumber.length >= 4
        ? '•••• •••• •••• ${cardNumber.substring(cardNumber.length - 4)}'
        : '•••• •••• •••• ••••';
  }

  Future<void> _pickAndUpdateImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await File(picked.path).readAsBytes();
      final base64String = base64Encode(bytes);
      await ref.read(authNotifierProvider.notifier).updateUserPhoto(
            imageData: base64String,
            isLocalFile: true,
          );
      ref.invalidate(currentAppUserProvider);
    }
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isDark = ref.watch(isDarkModeProvider);

    final actions = [
      {"icon": Icons.school, "label": "School Fees", "amount": 245000},
      {"icon": Icons.local_hospital, "label": "Medical Fee", "amount": 10000},
      {"icon": Icons.hotel, "label": "Hostel Fee", "amount": 98000},
      {"icon": Icons.verified_user, "label": "Clearance", "amount": 100000},
    ];

    final Map<String, String> _bankAccounts = {
      'School Fees_Wema Bank': '0122275995',
      'School Fees_Zenith Bank': '1012183291',
      'Hostel Fee_Wema Bank': '0122275995',
      'Hostel Fee_Zenith Bank': '1012183291',
    };

    final Map<String, String> _bankLogos = {
      'Wema Bank': 'assets/images/wema_logo.png',
      'Zenith Bank': 'assets/images/zenith_logo.png',
    };

    void _showBankSelectionDialog(String feeType, int amount) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          title: Text(
            'Select Bank for $feeType',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Wema Bank', 'Zenith Bank'].map((bank) {
              final key = '${feeType}_$bank';
              final accountNumber = _bankAccounts[key] ?? '';
              final logoPath = _bankLogos[bank];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: isDark ? Colors.blueGrey[700] : Colors.blue[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      logoPath ?? '',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                  title: Text(
                    bank,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Account: $accountNumber'),
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushNamed(context, '/register', arguments: {
                      'feeType': feeType,
                      'amount': amount,
                      'bankName': bank,
                      'accountNumber': accountNumber,
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: actions.map((action) {
          final label = action['label'] as String;
          final amount = action['amount'] as int;

          return GestureDetector(
            onTap: () {
              if (label == 'School Fees' || label == 'Hostel Fee') {
                _showBankSelectionDialog(label, amount);
              } else {
                Navigator.pushNamed(context, '/register', arguments: {
                  'feeType': label,
                  'amount': amount,
                });
              }
            },
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primaryColor,
                    child: Icon(action["icon"] as IconData, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
