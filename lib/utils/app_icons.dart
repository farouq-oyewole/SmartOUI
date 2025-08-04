import 'package:flutter/material.dart';

class AppIcons {
  // Banking specific icons
  static const IconData wallet = Icons.account_balance_wallet;
  static const IconData transfer = Icons.swap_horiz;
  static const IconData deposit = Icons.arrow_downward;
  static const IconData withdraw = Icons.arrow_upward;
  static const IconData payment = Icons.payment;
  static const IconData card = Icons.credit_card;
  static const IconData bank = Icons.account_balance;
  static const IconData money = Icons.attach_money;
  static const IconData analytics = Icons.analytics;
  static const IconData history = Icons.history;
  static const IconData notification = Icons.notifications;
  static const IconData security = Icons.security;
  static const IconData settings = Icons.settings;
  static const IconData profile = Icons.person;
  static const IconData help = Icons.help_outline;
  static const IconData logout = Icons.logout;
  
  // Transaction type icons
  static const IconData income = Icons.trending_up;
  static const IconData expense = Icons.trending_down;
  static const IconData pending = Icons.schedule;
  static const IconData completed = Icons.check_circle;
  static const IconData failed = Icons.error;
  
  // Action icons
  static const IconData send = Icons.send;
  static const IconData receive = Icons.call_received;
  static const IconData scan = Icons.qr_code_scanner;
  static const IconData contact = Icons.contacts;
  static const IconData favorite = Icons.favorite;
  static const IconData star = Icons.star;
  
  // UI icons
  static const IconData menu = Icons.menu;
  static const IconData close = Icons.close;
  static const IconData back = Icons.arrow_back;
  static const IconData forward = Icons.arrow_forward;
  static const IconData up = Icons.keyboard_arrow_up;
  static const IconData down = Icons.keyboard_arrow_down;
  static const IconData search = Icons.search;
  static const IconData filter = Icons.filter_list;
  static const IconData sort = Icons.sort;
  static const IconData refresh = Icons.refresh;
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData copy = Icons.copy;
  static const IconData share = Icons.share;
  static const IconData download = Icons.download;
  static const IconData upload = Icons.upload;
  
  // Status icons
  static const IconData success = Icons.check_circle;
  static const IconData warning = Icons.warning;
  static const IconData error = Icons.error;
  static const IconData info = Icons.info;
  
  // Theme icons
  static const IconData lightMode = Icons.light_mode;
  static const IconData darkMode = Icons.dark_mode;
  static const IconData autoMode = Icons.brightness_auto;
}

// Custom animated icons
class AnimatedAppIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Duration duration;
  final bool animate;

  const AnimatedAppIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.duration = const Duration(milliseconds: 300),
    this.animate = true,
  });

  @override
  State<AnimatedAppIcon> createState() => _AnimatedAppIconState();
}

class _AnimatedAppIconState extends State<AnimatedAppIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animate ? _scaleAnimation.value : 1.0,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}
