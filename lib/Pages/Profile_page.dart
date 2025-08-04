// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:bank_app/Providers/loading_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Providers/auth_provider.dart';
import '../components/custom_button.dart';
import '../components/custom_textfield.dart';
import '../models/user_model.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import '../services/validation_service.dart';
import '../utils/formatters.dart';
import '../utils/responsive_helper.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardController = TextEditingController();

  bool _isEditing = false;
  bool _obscureBalance = true;

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  void _loadUser() {
    final user = ref.read(currentAppUserProvider);
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber ?? '';
      _cardController.text = user.cardNumber;
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (picked != null) {
      final base64 = base64Encode(await picked.readAsBytes());
      setState(() => _selectedImage = File(picked.path));
      await ref.read(authNotifierProvider.notifier).updateUserPhoto(
        imageData: base64,
        isLocalFile: false,
      );
    }
  }

  Future<void> _toggleBalanceVisibility() async {
    setState(() => _obscureBalance = !_obscureBalance);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loadingProvider.notifier).startLoading('profile');

    try {
      final card = _cardController.text.trim();
      double balance = ref.read(currentAppUserProvider)?.balance ?? 0;

      if (card.isNotEmpty && card != ref.read(currentAppUserProvider)?.cardNumber) {
        balance = 5000000;
      }

      await ref.read(authNotifierProvider.notifier).updateUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        cardNumber: card,
        balance: balance,
      );
      await ref.read(authNotifierProvider.notifier).reloadUser();

      ref.read(notificationProvider.notifier).showSuccess('Saved', 'Profile updated successfully');
      setState(() => _isEditing = false);
    } catch (e) {
      ref.read(notificationProvider.notifier).showError('Error', e.toString());
    } finally {
      ref.read(loadingProvider.notifier).stopLoading('profile');
    }
  }

  void _cancelEdit() {
    setState(() => _isEditing = false);
    _loadUser();
  }

  void _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final loading = ref.watch(profileLoadingProvider);

    final avatarSize = context.isMobile ? 50.0 : 60.0;
    ImageProvider<Object>? img;

    if (_selectedImage != null) {
      img = FileImage(_selectedImage!);
    } else if (user?.photoUrl?.isNotEmpty ?? false) {
      img = MemoryImage(base64Decode(user!.photoUrl!));
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsiveMargin(context),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: avatarSize,
                          backgroundImage: img,
                          // ignore: deprecated_member_use
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: img == null
                              ? Icon(Icons.person, size: avatarSize, color: Theme.of(context).primaryColor)
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(user?.name ?? 'User',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    if (!_isEditing)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profile'),
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                  ],
                ),
              ),
              ResponsiveHelper.isDesktop(context)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildForm(user, loading)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildSettings()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildForm(user, loading),
                        const SizedBox(height: 24),
                        _buildSettings(),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(AppUser? user, bool loading) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: const Icon(Icons.person_outline),
                enabled: _isEditing,
                validator: (v) =>
                    ValidationService.validateName(v ?? '').isValid ? null : 'Enter valid name',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: const Icon(Icons.phone_outlined),
                enabled: _isEditing,
                validator: (v) {
                  if ((v ?? '').isNotEmpty && !ValidationService.isValidPhoneNumber(v!)) {
                    return 'Invalid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
  controller: _cardController,
  labelText: 'Card Number',
  hintText: 'Enter your card number',
  prefixIcon: const Icon(Icons.credit_card),
  enabled: _isEditing,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(16),
  ],
  validator: (v) {
    if ((v ?? '').isEmpty) return 'Card number is required';
    if ((v ?? '').length < 16) return 'Enter full 16-digit card number';
    return null;
  },
),

              const SizedBox(height: 24),
              if (_isEditing)
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: _cancelEdit, child: const Text('Cancel'))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        text: 'Save',
                        onPressed: _saveProfile,
                        isLoading: loading,
                      ),
                    ),
                  ],
                ),
              if (!_isEditing) ...[
                const SizedBox(height: 16),
                _infoRow('Card Number', user?.maskedCardNumber ?? 'N/A'),
                _balanceRow(user?.balance ?? 0),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _balanceRow(double balance) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Balance', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            Row(
              children: [
                Text(
                  _obscureBalance ? '••••••' : Formatters.formatCurrency(balance),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: Icon(_obscureBalance ? Icons.visibility : Icons.visibility_off),
                  onPressed: _toggleBalanceVisibility,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildSettings() {
    final isDark = ref.watch(isDarkModeProvider);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.grey),
              title: const Text('Dark Mode'),
              subtitle: Text(isDark ? 'Enabled' : 'Disabled', style: const TextStyle(color: Colors.grey)),
              trailing: Switch(
                value: isDark,
                onChanged: (v) => ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
