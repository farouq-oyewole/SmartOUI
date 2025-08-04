// ignore_for_file: deprecated_member_use

import 'package:bank_app/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payment_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/loading_provider.dart';
import '../providers/notification_provider.dart';
import '../services/validation_service.dart';
import '../models/transaction_model.dart';
import 'custom_textfield.dart';

class PaymentActions extends ConsumerStatefulWidget {
  const PaymentActions({super.key});

  @override
  ConsumerState<PaymentActions> createState() => _PaymentActionsState();
}

class _PaymentActionsState extends ConsumerState<PaymentActions> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedAction = 'deposit';

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(paymentLoadingProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildActionSelector(),
          const SizedBox(height: 16),
          AmountTextField(
            controller: _amountController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final validation = ValidationService.validateAmount(value, minAmount: 1.0);
              return validation.isValid ? null : validation.firstError;
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _descriptionController,
            hintText: 'Enter description (optional)',
            labelText: 'Description',
            maxLines: 2,
            prefixIcon: const Icon(Icons.description_outlined),
          ),
          const SizedBox(height: 20),
          _buildActionGrid(context, isLoading),
        ],
      ),
    );
  }

  Widget _buildActionSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSelectorButton('deposit', 'Add Money', Icons.add),
          _buildSelectorButton('transfer', 'Transfer', Icons.send),
          _buildSelectorButton('withdraw', 'Withdraw', Icons.remove),
        ],
      ),
    );
  }

  Widget _buildSelectorButton(String action, String label, IconData icon) {
    final isSelected = _selectedAction == action;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedAction = action),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, bool isLoading) {
    final actions = [
      {
        'icon': Icons.add_circle_outline,
        'label': 'Add Money',
        'color': Colors.green,
        'onTap': () => _handleAddMoney(),
      },
      {
        'icon': Icons.send_outlined,
        'label': 'Send Money',
        'color': Colors.blue,
        'onTap': () => _handleSendMoney(),
      },
      {
        'icon': Icons.account_balance_outlined,
        'label': 'Deposit',
        'color': Colors.teal,
        'onTap': () => _handleDeposit(),
      },
      {
        'icon': Icons.money_outlined,
        'label': 'Withdraw',
        'color': Colors.orange,
        'onTap': () => _handleWithdraw(),
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: actions.map((action) {
        return _buildActionButton(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['color'] as Color,
          onTap: action['onTap'] as VoidCallback,
          isLoading: isLoading,
        );
      }).toList(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (isLoading)
              Container(
                margin: const EdgeInsets.only(right: 12),
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
          ],
        ),
      ),
    );
  }

 Future<void> _handleAddMoney() async {
  final amount = _amountController.text.trim();

  if (amount.isEmpty) {
    _showError('Please enter an amount');
    return;
  }

  final validation = ValidationService.validateAmount(amount, minAmount: 1.0);
  if (!validation.isValid) {
    _showError(validation.firstError ?? 'Invalid amount');
    return;
  }

  final AppUser? currentUser = ref.read(currentAppUserProvider);

  if (currentUser == null) {
    _showError('User not authenticated');
    return;
  }

  try {
    ref.read(loadingNotifierProvider.notifier).startLoading('payment');

    await ref.read(paymentNotifierProvider.notifier).processPayment(
      amount: double.parse(amount),
      description: _descriptionController.text.trim().isEmpty
          ? 'Add money to wallet'
          : _descriptionController.text.trim(),
      customerName: currentUser.name,
      customerEmail: currentUser.email,
      customerPhone: currentUser.phoneNumber ?? '',
    );

    _clearForm();
    _showSuccess('Payment initiated successfully');
  } catch (e) {
    _showError('Failed to initiate payment: $e');
  } finally {
    ref.read(loadingNotifierProvider.notifier).stopLoading('payment');
  }
}




  Future<void> _handleSendMoney() async {
    Navigator.pushNamed(context, '/send-money');
  }

  Future<void> _handleDeposit() async {
  final amount = _amountController.text.trim();

  if (amount.isEmpty) {
    _showError('Please enter an amount');
    return;
  }

  final validation = ValidationService.validateAmount(amount, minAmount: 1.0);
  if (!validation.isValid) {
    _showError(validation.firstError ?? 'Invalid amount');
    return;
  }

  final AppUser? currentUser = ref.read(currentAppUserProvider);

  if (currentUser == null) {
    _showError('User not authenticated');
    return;
  }

  try {
    ref.read(loadingNotifierProvider.notifier).startLoading('payment');

    await ref.read(transactionNotifierProvider.notifier).addTransaction(
      Transactions(
        userId: currentUser.id,
        amount: double.parse(amount),
        description: _descriptionController.text.trim().isEmpty
            ? 'Deposit to account'
            : _descriptionController.text.trim(),
        type: 'deposit',
        date: DateTime.now(),
        id: '',
        name: '',
        category: '',
      ),
    );

    _clearForm();
    _showSuccess('Deposit processed successfully');
  } catch (e) {
    _showError('Failed to process deposit: $e');
  } finally {
    ref.read(loadingNotifierProvider.notifier).stopLoading('payment');
  }
}



  Future<void> _handleWithdraw() async {
    Navigator.pushNamed(context, '/withdraw');
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();
  }

  void _showSuccess(String message) {
  ref.read(notificationProvider.notifier).showSuccess('Success', message);
}

void _showError(String message) {
  ref.read(notificationProvider.notifier).showError('Error', message);
}
}
