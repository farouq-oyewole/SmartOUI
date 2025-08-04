import 'package:flutter/material.dart';
import '../utils/animations.dart';


class FloatingActionMenu extends StatefulWidget {
  final List<FloatingActionMenuItem> items;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const FloatingActionMenu({
    super.key,
    required this.items,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.elasticCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });
    
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.primaryColor;
    final foregroundColor = widget.foregroundColor ?? Colors.white;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Menu items
        ...widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = (index + 1) * 70.0 * _scaleAnimation.value;
              
              return Transform.translate(
                offset: Offset(0, -offset),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FloatingActionButton(
                    heroTag: 'fab_$index',
                    mini: true,
                    backgroundColor: item.backgroundColor ?? backgroundColor,
                    foregroundColor: item.foregroundColor ?? foregroundColor,
                    onPressed: () {
                      _toggle();
                      item.onPressed();
                    },
                    child: Icon(item.icon),
                  ),
                ),
              );
            },
          );
        }),
        
        // Main FAB
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: FloatingActionButton(
                heroTag: 'main_fab',
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                onPressed: _toggle,
                child: Icon(_isOpen ? Icons.close : Icons.add),
              ),
            );
          },
        ),
      ],
    );
  }
}

class FloatingActionMenuItem {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const FloatingActionMenuItem({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });
}
