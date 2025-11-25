// ignore_for_file: unused_element, deprecated_member_use, curly_braces_in_flow_control_structures

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/credit_score_provider.dart';
import '../utils/animations.dart';

class AnimatedCreditCard extends ConsumerStatefulWidget {
  const AnimatedCreditCard({super.key});

  @override
  ConsumerState<AnimatedCreditCard> createState() =>
      _AnimatedCreditCardState();
}

class _AnimatedCreditCardState extends ConsumerState<AnimatedCreditCard>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _scoreController;
  late AnimationController _iconController;
  late AnimationController _fadeController;
  late AnimationController _sparkleController;

  late Animation<double> _cardScaleAnimation;
  late Animation<double> _scoreCountAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sparkleScale;

  double _previousScore = 0.0;

  @override
  void initState() {
    super.initState();

    _cardController =
        AnimationController(duration: AppAnimations.slow, vsync: this);
    _scoreController =
        AnimationController(duration: AppAnimations.normal, vsync: this);
    _iconController =
        AnimationController(duration: AppAnimations.fast, vsync: this);
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
    _sparkleController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _cardScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: AppAnimations.elasticCurve),
    );
    _scoreCountAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: AppAnimations.fastOutSlowIn),
    );
    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: AppAnimations.defaultCurve),
    );
    _fadeAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _sparkleScale = Tween<double>(begin: 0.0, end: 1.4).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.elasticOut),
    );

    _cardController.forward();
    _scoreController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _scoreController.dispose();
    _iconController.dispose();
    _fadeController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  /// Trigger score pulse and sparkle when score increases
  void _animateScoreChange(double newScore) {
    if (newScore > _previousScore) {
      _sparkleController.forward(from: 0.0);
    }
    if (_previousScore != newScore) {
      _previousScore = newScore;
      _scoreController.reset();
      _scoreController.forward();
    }
  }

  String? _getBadge(double score) {
    if (score >= 500) return '🏆 Platinum';
    if (score >= 400) return '🥇 Gold';
    if (score >= 300) return '🥈 Silver';
    if (score >= 200) return '🥉 Bronze';
    return null;
  }

  String _getRank(double score) {
    if (score >= 500) return 'Excellent';
    if (score >= 400) return 'Very Good';
    if (score >= 300) return 'Good';
    if (score > 0) return 'Building...';
    return 'New Tier 🌿';
  }

  Color _getScoreColor(double score) {
    if (score >= 500) return const Color(0xFF00E676);
    if (score >= 400) return const Color(0xFF43A047);
    if (score >= 300) return const Color(0xFFFFB300);
    if (score > 0) return const Color(0xFFD32F2F);
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final score = ref.watch(creditScoreProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    _animateScoreChange(score);

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallHeight = screenHeight < 700;
    final isNarrow = screenWidth < 360;

    final fontScale = isNarrow
        ? 0.82
        : (screenWidth < 350
            ? 0.85
            : screenWidth < 400
                ? 0.95
                : 1.0);
    final horizontalPadding = isNarrow
        ? 10.0
        : (screenWidth < 350
            ? 12.0
            : screenWidth < 400
                ? 16.0
                : 22.0);
    final badgeTextColor = isDarkMode ? Colors.white : Colors.black;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _cardController,
        _scoreController,
        _iconController,
        _fadeController,
        _sparkleController
      ]),
      builder: (context, child) {
        return Center(
          child: Transform.scale(
            scale: _cardScaleAnimation.value,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.94,
                minWidth: screenWidth * 0.88,
                minHeight: screenHeight * 0.28,
                maxHeight: screenHeight * 0.44,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isSmallHeight ? 16 : 22,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [
                            Color.lerp(
                                const Color(0xFF004D40),
                                const Color(0xFF00695C),
                                _fadeAnimation.value)!,
                            Color.lerp(
                                const Color(0xFF00695C),
                                const Color(0xFF009688),
                                _fadeAnimation.value)!,
                          ]
                        : [
                            Color.lerp(
                                const Color(0xFF2E7D32),
                                const Color(0xFF43A047),
                                _fadeAnimation.value)!,
                            Color.lerp(
                                const Color(0xFF43A047),
                                const Color(0xFF66BB6A),
                                _fadeAnimation.value)!,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ⭐ Sparkle animation overlay
                    if (_sparkleController.value > 0)
                      Transform.scale(
                        scale: _sparkleScale.value,
                        child: Opacity(
                          opacity: (1 - _sparkleController.value).clamp(0, 1),
                          child: Icon(
                            Icons.star,
                            color: Colors.yellowAccent.withOpacity(0.8),
                            size: 60 * _sparkleScale.value,
                          ),
                        ),
                      ),

                    // Content
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Credit Score',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18 * fontScale,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _iconController
                                            .forward()
                                            .then((_) =>
                                                _iconController.reverse());
                                      },
                                      child: Transform.rotate(
                                        angle:
                                            _iconRotationAnimation.value * pi / 6,
                                        child: Container(
                                          padding: EdgeInsets.all(6 * fontScale),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.trending_up,
                                            color: Colors.white,
                                            size: 20 * fontScale,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Score number
                                AnimatedBuilder(
                                  animation: _scoreCountAnimation,
                                  builder: (context, _) {
                                    final animatedScore =
                                        score * _scoreCountAnimation.value;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        animatedScore.toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 42 * fontScale,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.3,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black54,
                                              offset: Offset(0, 3),
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),

                                // Badge + Rank
                                Wrap(
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  runSpacing: 4,
                                  spacing: 8,
                                  children: [
                                    if (_getBadge(score) != null)
                                      Chip(
                                        label: Text(
                                          _getBadge(score)!,
                                          style: TextStyle(
                                            color: badgeTextColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13 * fontScale,
                                          ),
                                        ),
                                        backgroundColor:
                                            Colors.white.withOpacity(0.25),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6),
                                      ),
                                    SizedBox(
                                      width: constraints.maxWidth -
                                          (isNarrow ? 90 * fontScale : 120),
                                      child: Text(
                                        _getRank(score),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15 * fontScale,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (score.clamp(0, 900)) / 900,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.15),
                                    color: _getScoreColor(score),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Footer
                                SizedBox(
                                  width: constraints.maxWidth,
                                  child: Text(
                                    '⭐ Earn points by playing quizzes, donating, and attending events!',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13.5 * fontScale,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
