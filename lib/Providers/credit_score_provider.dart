// lib/providers/credit_score_provider.dart
// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Main provider that manages and syncs the user's credit score
final creditScoreProvider =
    StateNotifierProvider<CreditScoreNotifier, double>((ref) {
  return CreditScoreNotifier();
});

class CreditScoreNotifier extends StateNotifier<double> {
  CreditScoreNotifier() : super(0) {
    _init();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  bool _isSyncing = false;

  /// Initialize Firebase listeners
  Future<void> _init() async {
    _authSub = _auth.authStateChanges().listen((user) async {
      await _userDocSub?.cancel();

      if (user != null) {
        // Start listening to Firestore updates for live sync
        _userDocSub = _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
          final data = snapshot.data();
          if (data == null) return;
          final val = data['creditScore'];

          double score;
          if (val is int) {
            score = val.toDouble();
          } else if (val is double) {
            score = val;
          } else if (val is String) {
            score = double.tryParse(val) ?? 0.0;
          } else {
            score = 0.0;
          }

          // Only update state if changed (avoid rebuild loop)
          if ((state - score).abs() > 0.0001) {
            state = score;
          }
        });
      } else {
        // User logged out → stop listening & reset
        await _userDocSub?.cancel();
        state = 0;
      }
    });

    // If already signed in
    final user = _auth.currentUser;
    if (user != null) {
      _attachLiveListener(user.uid);
    }
  }

  /// Attach real-time listener manually (for initial user)
  void _attachLiveListener(String uid) {
    _userDocSub?.cancel();
    _userDocSub = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;
      final val = data['creditScore'];

      double score;
      if (val is int) {
        score = val.toDouble();
      } else if (val is double) {
        score = val;
      } else if (val is String) {
        score = double.tryParse(val) ?? 0.0;
      } else {
        score = 0.0;
      }

      if ((state - score).abs() > 0.0001) {
        state = score;
      }
    });
  }

  /// Persist the current score to Firestore
  Future<void> _saveToFirestore() async {
    final user = _auth.currentUser;
    if (user == null || _isSyncing) return;

    try {
      _isSyncing = true;
      await _firestore.collection('users').doc(user.uid).set(
        {'creditScore': state},
        SetOptions(merge: true),
      );
    } catch (e) {
      print('⚠️ Failed to save credit score: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Add points (updates local state immediately + saves to Firestore)
  Future<void> addPoints(double amount) async {
    if (amount <= 0) return;
    state += amount; // immediate local update for instant UI response
    unawaited(_saveToFirestore());
  }

  /// Set score manually and sync
  Future<void> setScore(double newScore) async {
    state = newScore;
    unawaited(_saveToFirestore());
  }

  /// Reset score (for admin/debug)
  Future<void> reset() async {
    state = 0;
    await _saveToFirestore();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}
