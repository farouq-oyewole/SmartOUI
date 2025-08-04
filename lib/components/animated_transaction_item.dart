// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../utils/animations.dart';
import '../utils/app_icons.dart';

class AnimatedTransactionItem extends StatefulWidget {
  final Transactions transaction;
  final int index;
  final VoidCallback? onTap;

  const AnimatedTransactionItem({
    super.key,
    required this.transaction,
    required this.index,
    this.onTap,
  });

  @override
  State<AnimatedTransactionItem> createState() => _AnimatedTransactionItemState();
}

class _AnimatedTransactionItemState extends State<AnimatedTransactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.fastOutSlowIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.elasticCurve,
    ));

    // Start animation with delay based on index
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
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
                      // Transaction icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getTransactionColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTransactionIcon(),
                          color: _getTransactionColor(),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Transaction details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.transaction.description,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatDate(widget.transaction.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Amount and status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${widget.transaction.type == 'credit' ? '+' : '-'}${Formatters.formatCurrency(widget.transaction.amount)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _getTransactionColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                             widget.transaction.status.name.toUpperCase(),
                             style: TextStyle(
                             color: _getStatusColor(),
                             fontSize: 10,
                             fontWeight: FontWeight.w600,
                             ),
                             ),

                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getTransactionIcon() {
    switch (widget.transaction.type) {
      case 'credit':
        return AppIcons.income;
      case 'debit':
        return AppIcons.expense;
      default:
        return AppIcons.pending;
    }
  }

  Color _getTransactionColor() {
    switch (widget.transaction.type) {
      case 'credit':
        return Colors.green;
      case 'debit':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _getStatusColor() {
    switch (widget.transaction.status.name.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
