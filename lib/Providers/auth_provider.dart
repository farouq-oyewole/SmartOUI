// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

final _firestore = FirebaseFirestore.instance;
final _secureStorage = const FlutterSecureStorage();

// Auth Notifier Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier();
});

// Current User Provider
final currentAppUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authNotifierProvider);
});

class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier() : super(null) {
    _loadUser();
  }

  final _auth = FirebaseAuth.instance;

  User? get firebaseUser => _auth.currentUser;

  Future<void> _loadUser() async {
    final user = firebaseUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        state = AppUser.fromFirestore(doc);
      }
    }
  }

  Future<void> reloadUser() async => _loadUser();

  Future<void> updateUserProfile({
  required String name,
  required String phoneNumber,
  String? cardNumber,
  double? balance,
}) async {
  final uid = firebaseUser?.uid;
  if (uid == null) return;

  final data = {
    'name': name,
    'phoneNumber': phoneNumber,
    'updatedAt': Timestamp.now(),
  };

  if (cardNumber != null) {
    data['cardNumber'] = cardNumber;
  }

  if (balance != null) {
    data['balance'] = balance;
  }

  await _firestore.collection('users').doc(uid).update(data);
  await _loadUser();
}

  Future<void> updateUserPhoto({
    required String imageData,
    required bool isLocalFile,
  }) async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;
    final field = isLocalFile ? 'profileImage' : 'photoUrl';
    await _firestore.collection('users').doc(uid).update({
      field: imageData,
      'updatedAt': Timestamp.now(),
    });
    await _loadUser();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    // ignore: unused_local_variable
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _storeLoginPasswordHash(password);
    await _loadUser();
  }

  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    await _storeLoginPasswordHash(password);

    final newUser = AppUser(
      id: uid,
      name: '',
      email: email,
      balance: 0.0,
      cardNumber: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      transactionPin: null,
      phoneNumber: null,
      profileImage: null,
      photoUrl: null,
      photoFilePath: null,
      status: UserStatus.pending,
      accountTypes: ['checking'],
      preferences: {},
      securitySettings: SecuritySettings(),
    );

    await _firestore.collection('users').doc(uid).set(newUser.toFirestore());
    state = newUser;
  }

  Future<void> _storeLoginPasswordHash(String password) async {
    final hash = sha256.convert(utf8.encode(password)).toString();
    await _secureStorage.write(key: 'loginPasswordHash', value: hash);
  }

  Future<void> updateTransactionPin(String rawPin) async {
    final uid = firebaseUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final hash = sha256.convert(utf8.encode(rawPin)).toString();
    await _secureStorage.write(key: 'transactionPinHash', value: hash);

    await _firestore.collection('users').doc(uid).update({
      'transactionPin': hash,
      'updatedAt': Timestamp.now(),
    });

    await _loadUser();
  }

  Future<void> clearTransactionPin() async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;

    await _secureStorage.delete(key: 'transactionPinHash');
    await _firestore.collection('users').doc(uid).update({
      'transactionPin': FieldValue.delete(),
      'updatedAt': Timestamp.now(),
    });
    await _loadUser();
  }

  Future<bool> verifyTransactionPin(String pin) async {
    final stored = await _secureStorage.read(key: 'transactionPinHash');
    if (stored == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return hash == stored;
  }

  // ─────────────────────────────────────────────
//  Atomic balance update helpers
// ─────────────────────────────────────────────
Future<double> updateUserBalance({
  required double delta, // ➕ positive to add, ➖ negative to deduct
}) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) throw Exception('User not logged in');

  final docRef = _firestore.collection('users').doc(uid);

  final newBalance = await _firestore.runTransaction<double>((t) async {
    final snapshot = await t.get(docRef);
    final current = (snapshot.data()?['balance'] ?? 0.0).toDouble();
    final next   = (current + delta).clamp(0, double.infinity);
    t.update(docRef, {
      'balance': next,
      'updatedAt': Timestamp.now(),
    });
    return next;
  });

  // Refresh state after transaction
  await _loadUser();
  return newBalance;
}

/// Convenience wrappers
Future<double> deductUserBalance(double amount) =>
    updateUserBalance(delta: -amount);

Future<double> creditUserBalance(double amount) =>
    updateUserBalance(delta:  amount);

  Future<void> signOut() async {
    await _auth.signOut();
    await _secureStorage.deleteAll();
    state = null;
  }
}
