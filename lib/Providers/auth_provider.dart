// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:bank_app/Pages/admin_page.dart';
import 'package:bank_app/Pages/quiz_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

final _firestore = FirebaseFirestore.instance;
final _secureStorage = const FlutterSecureStorage();

// Auth Notifier Provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier(ref);
});

// Current User Provider
final currentAppUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authNotifierProvider);
});

class AuthNotifier extends StateNotifier<AppUser?> {
  final Ref ref;
  AuthNotifier(this.ref) : super(null) {
    _loadUser();
  }

  final _auth = FirebaseAuth.instance;

  User? get firebaseUser => _auth.currentUser;

  /// Load user from Firestore into state
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

  /// Update profile information
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
    if (cardNumber != null) data['cardNumber'] = cardNumber;
    if (balance != null) data['balance'] = balance;

    await _firestore.collection('users').doc(uid).update(data);
    await _loadUser();
  }

  /// Update user profile image
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

  /// Sign in (with daily quiz state restoration)
  Future<void> signInWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    const adminEmail1 = 'mssnadmin@gmail.com';
    const adminPassword1 = 'Subhanallah99';
    const adminEmail2 = 'mssnadmin2@gmail.com';
    const adminPassword2 = 'SuperSecret456';

    // Admin login shortcut
    if ((email == adminEmail1 && password == adminPassword1) ||
        (email == adminEmail2 && password == adminPassword2)) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPage()),
        );
      }
      return;
    }

    try {
      // Firebase sign in
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Store hashed password locally (optional)
      await _storeLoginPasswordHash(password);

      // Load user data into state
      await _loadUser();

      // Restore quiz state without starting quiz automatically
      await restoreQuizState();
    } on FirebaseAuthException catch (e) {
      final errorMessage = e.message ?? 'Login failed. Please try again.';
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An unexpected error occurred.')));
      }
    }
  }

  /// Create a new user (registration)
  Future<void> createUserWithEmailAndPassword(
      String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final uid = credential.user!.uid;

    await _storeLoginPasswordHash(password);

    final newUser = AppUser(
      id: uid,
      name: '',
      email: email,
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

    // Restore quiz state after registration (does NOT auto-start the quiz)
    await restoreQuizState();
  }

  /// Store hashed login password
  Future<void> _storeLoginPasswordHash(String password) async {
    final hash = sha256.convert(utf8.encode(password)).toString();
    await _secureStorage.write(key: 'loginPasswordHash', value: hash);
  }

  /// Transaction PIN management
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

  /// User balance updates
  Future<double> updateUserBalance({required double delta}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final docRef = _firestore.collection('users').doc(uid);

    final newBalance = await _firestore.runTransaction<double>((t) async {
      final snapshot = await t.get(docRef);
      final current = (snapshot.data()?['balance'] ?? 0.0).toDouble();
      final next = (current + delta).clamp(0, double.infinity);
      t.update(docRef, {
        'balance': next,
        'updatedAt': Timestamp.now(),
      });
      return next;
    });

    await _loadUser();
    return newBalance;
  }

  Future<double> deductUserBalance(double amount) =>
      updateUserBalance(delta: -amount);

  Future<double> creditUserBalance(double amount) =>
      updateUserBalance(delta: amount);

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();

    // Clear session info
    await _secureStorage.delete(key: 'user_token');
    await _secureStorage.delete(key: 'refresh_token');

    // Do NOT delete quiz-related storage (quiz_played_today, etc.)
    state = null;
  }

  /// Restore quiz state from SharedPreferences
  Future<void> restoreQuizState() async {
    final prefs = await SharedPreferences.getInstance();

    final todayKey =
        'quiz_played_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    final quizPlayedToday = prefs.getBool(todayKey) ?? false;

    final quizNotifier = ref.read(quizNotifierProvider.notifier);

    if (quizPlayedToday) {
      // Daily limit reached
      quizNotifier.state =
          quizNotifier.state.copyWith(dailyLimitReached: true);
    } else {
      // Quiz not started yet
      quizNotifier.state = quizNotifier.state.copyWith(
        dailyLimitReached: false,
      );
    }
  }

  /// Mark quiz as played today
  Future<void> markQuizAsPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey =
        'quiz_played_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    await prefs.setBool(todayKey, true);

    final quizNotifier = ref.read(quizNotifierProvider.notifier);
    quizNotifier.state = quizNotifier.state.copyWith(dailyLimitReached: true);
  }
}
