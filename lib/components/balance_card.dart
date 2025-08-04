// ignore_for_file: deprecated_member_use

import 'package:bank_app/Providers/balance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class BalanceCard extends ConsumerWidget {
  final bool showActions;
  final VoidCallback? onToggleVisibility;

  const BalanceCard({
    super.key,
    this.showActions = true,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayedBalance = ref.watch(displayedBalanceProvider);
    final formattedCardNumber = ref.watch(formattedCardNumberProvider);
    final currentUser = ref.watch(currentAppUserProvider);
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Colors.grey[800]!, Colors.grey[900]!]
              : [Colors.black87, Colors.black],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        displayedBalance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onToggleVisibility ?? () {
                          ref.read(balanceNotifierProvider.notifier)
                              .toggleBalanceVisibility();
                        },
                        child: Icon(
                          isBalanceVisible 
                              ? Icons.visibility_outlined 
                              : Icons.visibility_off_outlined,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Card chip and logo
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VISA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Card number and user info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedCardNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentUser?.name.toUpperCase() ?? 'CARD HOLDER',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              if (showActions)
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.add,
                      onTap: () => Navigator.pushNamed(context, '/add-money'),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.send,
                      onTap: () => Navigator.pushNamed(context, '/send-money'),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

// Compact version for smaller spaces
class CompactBalanceCard extends ConsumerWidget {
  const CompactBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayedBalance = ref.watch(displayedBalanceProvider);
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Balance',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayedBalance,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(balanceNotifierProvider.notifier)
                  .toggleBalanceVisibility();
            },
            child: Icon(
              isBalanceVisible 
                  ? Icons.visibility_outlined 
                  : Icons.visibility_off_outlined,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
