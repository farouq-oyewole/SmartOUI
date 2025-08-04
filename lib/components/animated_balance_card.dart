// ignore_for_file: unused_element, deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/balance_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/formatters.dart';
import '../utils/animations.dart';
import '../utils/app_icons.dart';

class AnimatedBalanceCard extends ConsumerStatefulWidget {
  const AnimatedBalanceCard({super.key});

  @override
  ConsumerState<AnimatedBalanceCard> createState() => _AnimatedBalanceCardState();
}

class _AnimatedBalanceCardState extends ConsumerState<AnimatedBalanceCard>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _balanceController;
  late AnimationController _iconController;
  
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _balanceCountAnimation;
  late Animation<double> _iconRotationAnimation;

  bool _isBalanceVisible = true;
  double _previousBalance = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Card animation controller
    _cardController = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    
    // Balance animation controller
    _balanceController = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    
    // Icon animation controller
    _iconController = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );

    // Card scale animation
    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: AppAnimations.elasticCurve,
    ));

    // Balance count animation
    _balanceCountAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _balanceController,
      curve: AppAnimations.fastOutSlowIn,
    ));

    // Icon rotation animation
    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: AppAnimations.defaultCurve,
    ));

    // Start animations
    _cardController.forward();
    _balanceController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _balanceController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
    _iconController.forward().then((_) {
      _iconController.reverse();
    });
  }

  void _animateBalanceChange(double newBalance) {
    if (_previousBalance != newBalance) {
      _previousBalance = newBalance;
      _balanceController.reset();
      _balanceController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(balanceProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final theme = Theme.of(context);

    // Update card color animation based on theme

    return AnimatedBuilder(
      animation: Listenable.merge([
        _cardController,
        _balanceController,
        _iconController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with balance toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _balanceCountAnimation,
                          builder: (context, child) {
                            final animatedBalance = balance * _balanceCountAnimation.value;
                            return Text(
                              _isBalanceVisible
                                  ? Formatters.formatCurrency(animatedBalance)
                                  : '••••••',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _toggleBalanceVisibility,
                      child: Transform.rotate(
                        angle: _iconRotationAnimation.value * 0.5,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isBalanceVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: AppIcons.send,
                        label: 'Send',
                        onTap: () {
                          // Navigate to send money
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: AppIcons.receive,
                        label: 'Receive',
                        onTap: () {
                          // Navigate to receive money
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: AppIcons.scan,
                        label: 'Scan',
                        onTap: () {
                          // Navigate to QR scanner
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
