// ignore_for_file: file_names, deprecated_member_use

import 'package:bank_app/Providers/auth_provider.dart';
import 'package:bank_app/Providers/notification_provider.dart';
import 'package:bank_app/Providers/transaction_provider.dart';
import 'package:bank_app/Services/receipt_service.dart';
import 'package:bank_app/models/app_notification_model.dart';
import 'package:bank_app/models/receipt_model.dart';
import 'package:bank_app/models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/loading_provider.dart';
import '../components/custom_button.dart';
import '../components/custom_textfield.dart';
import '../utils/responsive_helper.dart';
import '../utils/formatters.dart';
import 'receipt_screen.dart';


final receiptServiceProvider = Provider<ReceiptService>((_) => ReceiptService());

class RegistrationPage2 extends ConsumerStatefulWidget {
  final String? feeType;
  final double? presetAmount;
  static const double feeRate = 0.002; 

  const RegistrationPage2({super.key, this.feeType, this.presetAmount});

  @override
  ConsumerState<RegistrationPage2> createState() => _RegistrationPage2State();
}

class _RegistrationPage2State extends ConsumerState<RegistrationPage2> {
  // ──────────────────────────── Controllers
  final _formKey                = GlobalKey<FormState>();
  final _nameController         = TextEditingController();
  final _departmentController   = TextEditingController();
  final _levelController        = TextEditingController();
  final _matricController       = TextEditingController();
  final _amountController       = TextEditingController();
  final _accountNumberController = TextEditingController();
  static const double feeRate = 0.002;
  // ──────────────────────────── UI state
  String _selectedFeeType = 'School Fees';
  String? _selectedBank;
  String? _accountNumber;
  String? _selectedHostel;
  bool   _isPreset       = false;

  // ──────────────────────────── Static data
  final List<String> _feeTypes = [
    'School Fees','Acceptance Fee','Hostel Fee','Registration Fee',
    'Library Fee','Medical Fee','Sports Fee','Clearance',
  ];

  final List<String> _departments = [
    'Computer Science','Engineering','Microbiology','Law',
    'Business Administration','Economics','Biochemistry',
    'Industrial Chemistry','Public Administration','Physics',
    'Estate Management','Architecture',
  ];

  final List<String> _levels = [
    '100 Level','200 Level','300 Level','400 Level','500 Level',
  ];

  final Map<String,String> bankAccounts = {
    'School Fees_Wema Bank' : '0122275995',
    'School Fees_Zenith Bank': '1012183291',
    'Hostel Fee_Wema Bank'  : '0122275995',
    'Hostel Fee_Zenith Bank': '1012183291',
    'Medical Fee_Wema Bank' : '0122949285',
  };

  final Map<String,String> hostelFees = {
    'Maye Hall':'98000','Oyetade Hall':'98000','Nursing Hostel':'150000',
    'IOA Hall':'98000','Adeline Hall':'98000','Moremi Hall':'98000',
    'Queen Amdalat Hostel':'98000','Awosusi Hall':'98000','Exemption Fee':'26000',
  };

  final List<String> allBanks = ['Wema Bank','Zenith Bank','First Access Bank'];
  final Map<String,String> bankLogos = {
    'Wema Bank'       :'assets/images/wema_logo.png',
    'Zenith Bank'     :'assets/images/zenith_logo.png',
    'First Access Bank':'assets/images/access_logo.png',
  };

  // ──────────────────────────── Navigation arg handling
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String,dynamic>?;
    if (args != null) {
      _selectedFeeType  = args['feeType']      ?? _selectedFeeType;
      _amountController.text = (args['amount'] ?? '').toString();
      _selectedBank     = args['bankName']     ?? _selectedBank;
      _accountNumber    = args['accountNumber']?? _accountNumber;
      _isPreset = true;
    } else {
      _selectedFeeType = widget.feeType ?? _selectedFeeType;
      if (widget.presetAmount != null) {
        _amountController.text = widget.presetAmount!.toStringAsFixed(2);
        _isPreset = true;
      }
    }
    _setPresetValues();
  }

  void _setPresetValues() {
    if (_selectedFeeType == 'Medical Fee') {
      _selectedBank   = 'Wema Bank';
      _accountNumber  = bankAccounts['Medical Fee_Wema Bank'];
    } else if (_selectedFeeType == 'Clearance') {
      _selectedBank   = 'First Access Bank';
      _accountNumber  = '';
    } else if ((_selectedFeeType == 'School Fees' || _selectedFeeType == 'Hostel Fee') &&
               (_selectedBank != null)) {
      final key = '${_selectedFeeType}_$_selectedBank';
      _accountNumber  = bankAccounts[key] ?? '';
    }
  }

  List<String> get availableBanks {
    if (_selectedFeeType == 'School Fees' || _selectedFeeType == 'Hostel Fee') {
      return ['Wema Bank','Zenith Bank'];
    }
    return allBanks;
  }

  bool _showBankDropdown () => _selectedFeeType != 'Medical Fee';
  bool _showAccountField () => _selectedFeeType == 'Clearance';

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _levelController.dispose();
    _matricController.dispose();
    _amountController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  // ──────────────────────────── UI ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final loadingMap = ref.watch(loadingNotifierProvider);
    final profile    = ref.watch(authNotifierProvider)!;

    final amount = double.tryParse(_amountController.text) ?? 0;
    final fee    = amount * feeRate;
    final total  = amount + fee;
    final hasEnough = profile.balance >= total;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key : _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Student Information'),
                        const SizedBox(height: 24),
                        _buildStudentDetailsSection(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Payment Details'),
                        const SizedBox(height: 24),
                        _buildPaymentDetailsSection(),
                        if (_selectedFeeType == 'Hostel Fee') _buildHostelDropdown(),
                        if (_showBankDropdown())  ...[
                          const SizedBox(height: 16),
                          _buildBankDropdown(),
                        ],
                        if (_showAccountField()) ...[
                          const SizedBox(height: 16),
                          _buildAccountNumberField(),
                        ],
                        const SizedBox(height: 32),
                        _buildPaymentSummary(total),
                        if (!hasEnough) Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Insufficient Balance: ${Formatters.formatCurrency(profile.balance)}',
                            style: TextStyle(color: Colors.red[400]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          text      : 'Proceed to Payment',
                          icon      : const Icon(Icons.payment),
                          isLoading : loadingMap['payment'] ?? false,
                          onPressed : hasEnough ? () => _processPayment(total) : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────── build widgets (unchanged) ─────────────────────────────
  Widget _buildHeader(BuildContext ctx) => Row(
    children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Theme.of(ctx).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.school, color: Theme.of(ctx).primaryColor),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fee Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Secure payment & instant receipt', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    ],
  );

  Widget _buildSectionTitle(String t)
    => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));

  Widget _buildStudentDetailsSection() {
  return Column(
    children: [
      CustomTextField(
        controller: _nameController,
        labelText : 'Full Name',
        prefixIcon: const Icon(Icons.person),
        hintText  : '',
        validator : (value) {
          if (value == null || value.trim().isEmpty) return 'Full Name is required';
          final regex = RegExp(r'^[a-zA-Z\s]+$');
          if (!regex.hasMatch(value)) return 'Only letters are allowed';
          return null;
        },
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
        ],
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _matricController,
        labelText : 'Matric Number',
        prefixIcon: const Icon(Icons.badge),
        hintText  : 'e.g. U/20/CE/0351',
        validator : (value) {
          final regex = RegExp(r'^U/\d{2}/[A-Z]{2,4}/\d{3,4}$');
          if (value == null || value.trim().isEmpty) return 'Matric Number is required';
          if (!regex.hasMatch(value.trim())) return 'Format: U/20/CE/0351';
          return null;
        },
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9/]')),
        ],
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _departmentController.text.isEmpty ? null : _departmentController.text,
        decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.school)),
        items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
        onChanged: (v) => _departmentController.text = v ?? '',
        validator: (v) => v == null ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _levelController.text.isEmpty ? null : _levelController.text,
        decoration: const InputDecoration(labelText: 'Level', prefixIcon: Icon(Icons.grade)),
        items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
        onChanged: (v) => _levelController.text = v ?? '',
        validator: (v) => v == null ? 'Required' : null,
      ),
    ],
  );
}


  Widget _buildPaymentDetailsSection() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value       : _selectedFeeType,
          decoration  : const InputDecoration(labelText: 'Fee Type', prefixIcon: Icon(Icons.receipt)),
          items       : _feeTypes.map((f)=>DropdownMenuItem(value:f,child:Text(f))).toList(),
          onChanged   : _isPreset ? null : (v){
            setState(() {
              _selectedFeeType = v!;
              _selectedBank    = null;
              _accountNumber   = null;
            });
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller : _amountController,
          labelText  : 'Amount (₦)',
          prefixIcon : const Icon(Icons.money),
          keyboardType: TextInputType.number,
          validator  : (v){
            final a = double.tryParse(v ?? '');
            if (a == null || a <= 0) return 'Invalid';
            return null;
          },
          hintText   : '',
        ),
      ],
    );
  }

  Widget _buildHostelDropdown() => DropdownButtonFormField<String>(
    value       : _selectedHostel,
    decoration  : const InputDecoration(labelText: 'Hostel', prefixIcon: Icon(Icons.home)),
    items       : hostelFees.entries
                  .map((e)=>DropdownMenuItem(value:e.key,child:Text('${e.key} – ₦${e.value}')))
                  .toList(),
    onChanged   : (v){
      setState(() {
        _selectedHostel      = v;
        _amountController.text = hostelFees[v]!;
      });
    },
    validator   : (v)=> v==null ? 'Select hostel' : null,
  );

  Widget _buildBankDropdown() => DropdownButtonFormField<String>(
    value       : _selectedBank,
    decoration  : const InputDecoration(labelText: 'Bank', prefixIcon: Icon(Icons.account_balance)),
    items       : availableBanks.map((b)=>DropdownMenuItem(
                    value:b,
                    child: Row(
                      children:[
                        Image.asset(bankLogos[b]!,width:24,height:24),
                        const SizedBox(width:8),
                        Text(b),
                      ],
                    )
                  )).toList(),
    onChanged   : (v){
      setState(() {
        _selectedBank  = v;
        _accountNumber = bankAccounts['${_selectedFeeType}_$v'];
      });
    },
    validator   : (v)=> v==null ? 'Select bank' : null,
  );

 Widget _buildAccountNumberField() => CustomTextField(
  controller: _accountNumberController,
  labelText: 'Account Number',
  hintText: 'Enter account number',
  prefixIcon: const Icon(Icons.confirmation_number),
  onChanged: (val) => _accountNumber = val,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ],
  validator: (val) {
    if (val == null || val.length != 10) return 'Enter a valid 10-digit account number';
    return null;
  },
);


  Widget _buildPaymentSummary(double total) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fee = amount * 0.002;
    return Container(
      padding   : const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1)),
      child     : Column(
        children:[
          _buildSummaryRow('Amount', Formatters.formatCurrency(amount)),
          _buildSummaryRow('Fee (0.2%)', Formatters.formatCurrency(fee)),
          const Divider(),
          _buildSummaryRow('Total', Formatters.formatCurrency(total), isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label,String value,{bool isTotal=false})=>Padding(
    padding: const EdgeInsets.symmetric(vertical:6),
    child  : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:[
        Text(label, style: TextStyle(fontWeight: isTotal?FontWeight.bold:FontWeight.normal)),
        Text(value, style: TextStyle(
          fontWeight: FontWeight.bold,
          color     : isTotal ? Theme.of(context).primaryColor : null,
        )),
      ],
    ),
  );

  // ──────────────────────────── PAYMENT  (no PIN) ──────────────────
  //  _processPayment – UPDATED VERSION (insert inside _RegistrationPage2State)
// -----------------------------------------------------------------------------
Future<void> _processPayment(double total) async {
  final notifier = ref.read(notificationProvider.notifier);
  final loading  = ref.read(loadingNotifierProvider.notifier);
  final current  = ref.read(currentAppUserProvider);

  // 🛑 Validate form first
  if (!_formKey.currentState!.validate()) {
    notifier.showError('Validation Error', 'Please fill in all required fields.');
    return;
  }

  if (current == null) {
    notifier.showError('Error', 'User not logged in.');
    return;
  }

  if (current.balance < total) {
    notifier.showError('Insufficient Balance',
        'Your wallet balance is lower than the payment total.');
    return;
  }

  try {
    loading.startLoading('payment');

    final now           = DateTime.now();
    final receiptNumber = 'RCP${now.millisecondsSinceEpoch}';
    final qrData        = '''
Receipt: $receiptNumber
Name  : ${_nameController.text}
Matric: ${_matricController.text}
Amount: ₦${total.toStringAsFixed(2)}
''';

    // 1️⃣ Save transaction to Firestore
    final txn = Transactions(
      id         : '',
      userId     : current.id,
      name       : _nameController.text,
      description: '$_selectedFeeType Payment',
      amount     : total,
      type       : 'debit',
      category   : TransactionCategory.education,
      date       : now,
      status     : TransactionStatus.completed,
      reference  : receiptNumber,
      metadata   : {
        'feeType' : _selectedFeeType,
        'bank'    : _selectedBank ?? '',
        'account' : _accountNumber ?? '',
        'hostel'  : _selectedHostel ?? '',
      },
    );

    await FirebaseFirestore.instance.collection('transactions').add(txn.toFirestore());

    // 2️⃣ Save receipt to Firebase Realtime Database
    final resolvedAccount = (_selectedFeeType == 'Clearance' &&
            _accountNumber != null && _accountNumber!.isNotEmpty)
        ? _accountNumber!
        : (bankAccounts['${_selectedFeeType}_$_selectedBank'] ?? '');

    final receipt = Receipt(
      id            : receiptNumber,
      userId        : current.id,
      name          : _nameController.text,
      matric        : _matricController.text,
      department    : _departmentController.text,
      level         : _levelController.text,
      feeType       : _selectedFeeType,
      bankName      : _selectedBank ?? '',
      accountNumber : resolvedAccount,
      amount        : total,
      date          : now,
    );

    await ref.read(receiptServiceProvider).saveReceipt(receipt);

    // 3️⃣ Deduct balance
    await ref.read(authNotifierProvider.notifier).deductUserBalance(total);
    ref.invalidate(currentAppUserProvider);
    ref.invalidate(transactionsProvider);

    // 4️⃣ Notify user
    final notiId = now.millisecondsSinceEpoch.toString();
    final noti = AppNotification(
      id        : notiId,
      userId    : current.id,
      title     : 'Payment Success',
      message   : 'Paid ₦${total.toStringAsFixed(2)} for $_selectedFeeType.',
      isRead    : false,
      timestamp : now,
      type      : NotificationType.payment,
      data      : {'receipt': receiptNumber},
    );
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notiId)
        .set(noti.toFirestore());

    await notifier.showNotification(noti);

    // 5️⃣ Navigate to receipt screen
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          name          : _nameController.text,
          department    : _departmentController.text,
          level         : _levelController.text,
          matric        : _matricController.text,
          feeType       : _selectedFeeType,
          amount        : total.toStringAsFixed(2),
          receiptNumber : receiptNumber,
          qrData        : qrData,
          bankName      : _selectedBank ?? '',
          accountNumber : resolvedAccount,
        ),
      ),
    );
  } catch (e, st) {
    debugPrint('❌ Payment Error: $e\n$st');
    notifier.showError('Payment Failed', 'Something went wrong during payment.');
  } finally {
    loading.stopLoading('payment');
  }
}
}