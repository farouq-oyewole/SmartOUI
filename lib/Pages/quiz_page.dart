// lib/quizzespage.dart
// ignore_for_file: unused_local_variable, avoid_print, curly_braces_in_flow_control_structures, deprecated_member_use, non_constant_identifier_names, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:animations/animations.dart';
import 'package:bank_app/Providers/credit_score_provider.dart';
import 'package:bank_app/Providers/leaderboard_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// -------------------------------
/// Riverpod state & notifier with daily persistence
/// -------------------------------

final quizNotifierProvider =
    StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref: ref);
});

class QuizState {
  final bool loading;
  final bool fetchError;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int countdown;
  final int questionTimeLeft;
  final int totalPoints;
  final bool showingFeedback;
  final bool finished;
  final List<UserScore> leaderboard;
  final bool confetti;
  final int questionsAnsweredToday;
  final bool showingResult;
  final bool dailyLimitReached;
  final bool quizStarted;

  QuizState({
    required this.loading,
    required this.fetchError,
    required this.questions,
    required this.currentIndex,
    required this.countdown,
    required this.questionTimeLeft,
    required this.totalPoints,
    required this.showingFeedback,
    required this.finished,
    required this.leaderboard,
    required this.confetti,
    required this.questionsAnsweredToday,
    required this.showingResult,
    required this.dailyLimitReached,
    required this.quizStarted,
  });

  QuizState copyWith({
    bool? loading,
    bool? fetchError,
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? countdown,
    int? questionTimeLeft,
    int? totalPoints,
    bool? showingFeedback,
    bool? finished,
    List<UserScore>? leaderboard,
    bool? confetti,
    int? questionsAnsweredToday,
    bool? showingResult,
    bool? dailyLimitReached,
    bool? quizStarted,
  }) {
    return QuizState(
      loading: loading ?? this.loading,
      fetchError: fetchError ?? this.fetchError,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      countdown: countdown ?? this.countdown,
      questionTimeLeft: questionTimeLeft ?? this.questionTimeLeft,
      totalPoints: totalPoints ?? this.totalPoints,
      showingFeedback: showingFeedback ?? this.showingFeedback,
      finished: finished ?? this.finished,
      leaderboard: leaderboard ?? this.leaderboard,
      confetti: confetti ?? this.confetti,
      questionsAnsweredToday:
          questionsAnsweredToday ?? this.questionsAnsweredToday,
      showingResult: showingResult ?? this.showingResult,
      dailyLimitReached: dailyLimitReached ?? this.dailyLimitReached,
      quizStarted: quizStarted ?? this.quizStarted,
    );
  }

  factory QuizState.initial() => QuizState(
        loading: true,
        fetchError: false,
        questions: [],
        currentIndex: -1,
        countdown: 5,
        questionTimeLeft: 15,
        totalPoints: 0,
        showingFeedback: false,
        finished: false,
        leaderboard: [],
        confetti: false,
        questionsAnsweredToday: 0,
        showingResult: false,
        dailyLimitReached: false,
        quizStarted: false,
      );
}

class QuizNotifier extends StateNotifier<QuizState> {
  final Ref ref;
  Timer? _countdownTimer;
  Timer? _questionTimer;
  DateTime? _countdownEnd;
  DateTime? _questionEnd;
  SharedPreferences? _prefs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final int quizSize = 10;
  final int maxDailyQuestions = 10;

  QuizNotifier({required this.ref}) : super(QuizState.initial()) {
    _init();
  }

  /// INITIALIZATION
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadDailyProgress();

    final savedQuizJson = _prefs?.getString('quiz_session');
    if (savedQuizJson != null && !state.dailyLimitReached) {
      try {
        final Map<String, dynamic> data = jsonDecode(savedQuizJson);
        final questions = (data['questions'] as List)
            .map((e) => QuizQuestion.fromMap(Map<String, dynamic>.from(e)))
            .toList();

        state = state.copyWith(
          questions: questions,
          currentIndex: data['currentIndex'] ?? -1,
          totalPoints: data['totalPoints'] ?? 0,
          showingFeedback: false,
          finished: data['finished'] ?? false,
          showingResult: data['showingResult'] ?? false,
          countdown: data['countdown'] ?? state.countdown,
          questionTimeLeft: data['questionTimeLeft'] ?? 15,
          quizStarted: data['quizStarted'] ?? false,
        );

        if (state.currentIndex < 0) {
          // start initial countdown if we are at pre-quiz state
          startInitialCountdown(seconds: state.countdown);
        } else if (!state.finished) {
          // resume question timer with remaining time
          _questionEnd =
              DateTime.now().add(Duration(seconds: state.questionTimeLeft));
          _startQuestionTimer(seconds: state.questionTimeLeft);
        }
        return;
      } catch (_) {
        // fallback to fresh load
      }
    }
    await loadQuestions();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _questionTimer?.cancel();
    super.dispose();
  }

  /// DAILY PROGRESS
  Future<void> _loadDailyProgress() async {
    final sp = _prefs ?? await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = sp.getString('quiz_date') ?? '';
    final savedCount = sp.getInt('quiz_count') ?? 0;

    if (savedDate == today) {
      final reached = savedCount >= maxDailyQuestions;
      state = state.copyWith(
          questionsAnsweredToday: savedCount, dailyLimitReached: reached);
    } else {
      await sp.setString('quiz_date', today);
      await sp.setInt('quiz_count', 0);
      state =
          state.copyWith(questionsAnsweredToday: 0, dailyLimitReached: false);
    }
  }

  Future<void> _saveDailyProgress(int count) async {
    final sp = _prefs ?? await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await sp.setString('quiz_date', today);
    await sp.setInt('quiz_count', count);
    state = state.copyWith(questionsAnsweredToday: count);
  }

  /// QUIZ SESSION PERSISTENCE
  void _saveQuizSession() {
    final session = {
      'questions': state.questions.map((q) => q.toMap()).toList(),
      'currentIndex': state.currentIndex,
      'totalPoints': state.totalPoints,
      'questionTimeLeft': state.questionTimeLeft,
      'finished': state.finished,
      'showingResult': state.showingResult,
      'countdown': state.countdown,
      'quizStarted': state.quizStarted,
    };
    _prefs?.setString('quiz_session', jsonEncode(session));
  }

  void _clearQuizSession() {
    _prefs?.remove('quiz_session');
  }

  /// LOAD QUESTIONS
  Future<void> loadQuestions() async {
    state = state.copyWith(loading: true, fetchError: false);

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDay = prefs.getString("quiz_day");

    final quizFinishedToday = prefs.getBool("quiz_played_today") ?? false;

    if (lastDay == today && quizFinishedToday) {
      state = state.copyWith(
        loading: false,
        dailyLimitReached: true,
        fetchError: false,
        quizStarted: false,
      );
      return;
    }

    List<String> usedIds = prefs.getStringList("used_question_ids") ?? [];
    List<String> todayIds = prefs.getStringList("today_question_ids") ?? [];

    try {
      final jsonString =
          await rootBundle.loadString('assets/quiz/questions.json');
      final data = jsonDecode(jsonString);
      if (data is! List) throw Exception('Invalid JSON format');

      final allQuestions = data.map<QuizQuestion>((e) {
        final map = Map<String, dynamic>.from(e);
        final options = List<String>.from(map['options'] ?? []);
        final answer = map['answer'] ?? (options.isNotEmpty ? options[0] : '');
        final correctIndex = options.indexOf(answer);
        return QuizQuestion(
          id: map['id']?.toString() ?? UniqueKey().toString(),
          question: map['question'] ?? '',
          options: options,
          correctIndex: correctIndex >= 0 ? correctIndex : 0,
          points: (map['points'] is int) ? map['points'] as int : 10,
        );
      }).toList();

      if (lastDay != today) {
        await prefs.setString("quiz_day", today);
        await prefs.setStringList("today_question_ids", []);
        await prefs.setInt("quiz_count", 0);
        await prefs.setBool("quiz_played_today", false);
        todayIds = [];
        usedIds = [];
      }

      final unused = allQuestions.where((q) => !usedIds.contains(q.id)).toList();
      if (unused.isEmpty) {
        usedIds = [];
        unused.addAll(allQuestions);
      }

      unused.shuffle();
      final selected = unused.take(quizSize).toList();

      usedIds.addAll(selected.map((q) => q.id));
      todayIds = selected.map((q) => q.id).toList();
      await prefs.setStringList("used_question_ids", usedIds);
      await prefs.setStringList("today_question_ids", todayIds);

      final rng = Random();
      final prepared =
          selected.map((q) => _withShuffledOptions(q, rng).copyWith(selectedIndex: null)).toList();

      // update state
      state = state.copyWith(
        questions: prepared,
        loading: false,
        currentIndex: -1,
        totalPoints: 0,
        finished: false,
        showingResult: false,
        dailyLimitReached: false,
        quizStarted: false,
        countdown: 5,
        questionTimeLeft: 15,
      );

      // start initial countdown on fresh load
      startInitialCountdown(seconds: state.countdown);
    } catch (e) {
      state = state.copyWith(loading: false, fetchError: true);
    }
  }

  QuizQuestion _withShuffledOptions(QuizQuestion original, Random rng) {
    final opts = List<String>.from(original.options);
    final correctAnswer = opts[original.correctIndex];
    opts.shuffle(rng);
    final newCorrectIndex = opts.indexOf(correctAnswer);
    return QuizQuestion(
      id: original.id,
      question: original.question,
      options: opts,
      correctIndex: newCorrectIndex,
      points: original.points,
      selectedIndex: original.selectedIndex,
    );
  }

  /// START QUIZ (button)
  Future<void> startQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final quizFinishedToday = prefs.getBool("quiz_played_today") ?? false;

    if (quizFinishedToday) {
      state = state.copyWith(dailyLimitReached: true, quizStarted: false);
      return;
    }

    state = state.copyWith(quizStarted: true, currentIndex: 0, questionTimeLeft: 15);
    _questionEnd = DateTime.now().add(const Duration(seconds: 15));
    _startQuestionTimer();
  }

  /// INITIAL COUNTDOWN
  void startInitialCountdown({int seconds = 5}) {
    _countdownTimer?.cancel();
    _countdownEnd = DateTime.now().add(Duration(seconds: seconds));
    state = state.copyWith(
      currentIndex: -1,
      countdown: seconds,
      totalPoints: 0,
      finished: false,
      showingResult: false,
      showingFeedback: false,
      quizStarted: false,
    );
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final rem = max(0, _countdownEnd!.difference(DateTime.now()).inSeconds);
      if (rem <= 0) {
        _countdownTimer?.cancel();
        state = state.copyWith(currentIndex: 0, questionTimeLeft: 15, quizStarted: true, countdown: 0);
        _questionEnd = DateTime.now().add(const Duration(seconds: 15));
        _startQuestionTimer();
      } else {
        state = state.copyWith(countdown: rem);
      }
    });
  }

  void _startQuestionTimer({int seconds = 15}) {
    _questionTimer?.cancel();
    _questionEnd = DateTime.now().add(Duration(seconds: seconds));
    state = state.copyWith(questionTimeLeft: seconds);
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = max(0, _questionEnd!.difference(DateTime.now()).inSeconds);
      if (left <= 0) {
        _questionTimer?.cancel();
        _markAnswer(null);
        return;
      }
      state = state.copyWith(questionTimeLeft: left);
    });
  }

  /// ANSWER SELECTION
  void selectAnswer(int index) {
    if (state.showingFeedback) return;
    _questionTimer?.cancel();
    _markAnswer(index);
  }

  void _markAnswer(int? index) {
    final i = state.currentIndex;
    if (i < 0 || i >= state.questions.length) return;

    final q = state.questions[i];
    final correct = index != null && index == q.correctIndex;
    final gained = correct ? q.points : 0;

    final updated = [...state.questions];
    updated[i] = q.copyWith(selectedIndex: index);

    state = state.copyWith(
      questions: updated,
      showingFeedback: true,
      totalPoints: state.totalPoints + gained,
    );

    _saveQuizSession();

    Future.delayed(const Duration(milliseconds: 800), () async {
      final next = i + 1;
      if (next < state.questions.length) {
        state = state.copyWith(
            currentIndex: next, showingFeedback: false, questionTimeLeft: 15);
        _questionEnd = DateTime.now().add(const Duration(seconds: 15));
        _startQuestionTimer();
        _saveQuizSession();
      } else {
        state = state.copyWith(
            showingFeedback: false, finished: true, showingResult: true, quizStarted: false);
        _clearQuizSession();
        await _finishFlow();
      }
    });
  }

  /// FINISH FLOW & CREDIT SCORE
  Future<void> _finishFlow() async {
    final user = _auth.currentUser;
    final newCount =
        (state.questionsAnsweredToday + state.questions.length).clamp(0, maxDailyQuestions);
    await _saveDailyProgress(newCount);

    ref.read(creditScoreProvider.notifier).state += state.totalPoints.toDouble();

    state = state.copyWith(
        questionsAnsweredToday: newCount,
        dailyLimitReached: newCount >= maxDailyQuestions,
        quizStarted: false);

    if (user != null) {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final userRef = _firestore.collection('users').doc(user.uid);
      final dailyRef = _firestore
          .collection('quizScores')
          .doc(today)
          .collection('players')
          .doc(user.uid);

      try {
        await _firestore.runTransaction((txn) async {
          txn.set(userRef,
              {'creditScore': FieldValue.increment(state.totalPoints)},
              SetOptions(merge: true));
          txn.set(
              dailyRef,
              {
                'name': user.displayName ?? user.email ?? 'Anonymous',
                'score': FieldValue.increment(state.totalPoints),
                'timestamp': FieldValue.serverTimestamp(),
                'photoUrl': (await userRef.get()).data()?['photoUrl'],
              },
              SetOptions(merge: true));
        });
      } catch (_) {}
    }

    await _buildLeaderboard();
  }

  /// LEADERBOARD
  Future<void> _buildLeaderboard() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final snap = await _firestore
          .collection('quizScores')
          .doc(today)
          .collection('players')
          .orderBy('score', descending: true)
          .limit(50)
          .get();

      final list = snap.docs.map((d) {
        final data = d.data();
        return UserScore(
          uid: d.id,
          name: (data['name'] ?? d.id).toString(),
          points: ((data['score'] ?? 0) as num).toInt(),
          photoUrl: data['photoUrl']?.toString(),
        );
      }).toList();

      state = state.copyWith(
          leaderboard: list, confetti: state.totalPoints >= 80);
    } catch (_) {
      state =
          state.copyWith(leaderboard: [], confetti: state.totalPoints >= 80);
    }
  }

  /// RESTART QUIZ
  void restartQuiz() {
    _countdownTimer?.cancel();
    _questionTimer?.cancel();
    _clearQuizSession();
    _init();
  }

  /// -------------------------------
  /// Utility: retry loading questions
  /// -------------------------------
  void retryLoad() {
    loadQuestions();
  }

  /// -------------------------------
  /// Utility: sync countdown & question timers
  /// Call this after resuming app or restoring state
  /// -------------------------------
  void syncTimers() {
    if (state.finished || state.loading) return;

    // Sync initial countdown
    if (state.currentIndex < 0) {
      if (_countdownEnd != null) {
        final rem = max(0, _countdownEnd!.difference(DateTime.now()).inSeconds);
        if (rem <= 0) {
          _countdownTimer?.cancel();
          state = state.copyWith(
              currentIndex: 0, countdown: 0, questionTimeLeft: 15, quizStarted: true);
          _questionEnd = DateTime.now().add(const Duration(seconds: 15));
          _startQuestionTimer();
        } else {
          state = state.copyWith(countdown: rem);
          _countdownTimer?.cancel();
          _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            final r = max(0, _countdownEnd!.difference(DateTime.now()).inSeconds);
            if (r <= 0) {
              _countdownTimer?.cancel();
              state = state.copyWith(
                  currentIndex: 0, countdown: 0, questionTimeLeft: 15, quizStarted: true);
              _questionEnd = DateTime.now().add(const Duration(seconds: 15));
              _startQuestionTimer();
              return;
            }
            state = state.copyWith(countdown: r);
          });
        }
      } else {
        // if we have no countdown end but currentIndex < 0, start a fresh countdown
        startInitialCountdown(seconds: state.countdown);
      }
    }

    // Sync question timer
    if (state.currentIndex >= 0) {
      if (_questionEnd != null) {
        final left = max(0, _questionEnd!.difference(DateTime.now()).inSeconds);
        if (left <= 0) {
          _questionTimer?.cancel();
          _markAnswer(null);
        } else {
          state = state.copyWith(questionTimeLeft: left);
          _questionTimer?.cancel();
          _questionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            final l = max(0, _questionEnd!.difference(DateTime.now()).inSeconds);
            if (l <= 0) {
              _questionTimer?.cancel();
              _markAnswer(null);
              return;
            }
            state = state.copyWith(questionTimeLeft: l);
          });
        }
      } else {
        // missing end time -> start fresh for current question
        _questionEnd = DateTime.now().add(Duration(seconds: state.questionTimeLeft));
        _startQuestionTimer(seconds: state.questionTimeLeft);
      }
    }
  }
}

/// -------------------------------
/// Data Models
/// -------------------------------
class QuizQuestion {
  final String id; // ✅ Added
  final String question;
  final List<String> options;
  final int correctIndex;
  final int points;
  final int? selectedIndex;

  QuizQuestion({
    required this.id, // ✅ Added
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.points,
    this.selectedIndex,
  });

  QuizQuestion copyWith({
    String? id, // ✅ Added
    String? question,
    List<String>? options,
    int? correctIndex,
    int? points,
    int? selectedIndex,
  }) {
    return QuizQuestion(
      id: id ?? this.id, // ✅ Added
      question: question ?? this.question,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      points: points ?? this.points,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }

  // Serialize to Map (needed for SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'id': id, // ✅ Added
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'points': points,
      'selectedIndex': selectedIndex,
    };
  }

  // Deserialize from Map
  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] ?? UniqueKey().toString(), // ✅ Fallback to unique id if missing
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
      points: map['points'] ?? 0,
      selectedIndex: map['selectedIndex'],
    );
  }
}

/// Simple leaderboard item
class UserScore {
  final String uid;
  final String name;
  final int points;
  final String? photoUrl;

  UserScore({
    required this.uid,
    required this.name,
    required this.points,
    this.photoUrl,
  });

  UserScore copyWith({String? uid, String? name, int? points, String? photoUrl}) {
    return UserScore(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      points: points ?? this.points,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

// lib/quizzespage.dart
// UI Part (QuizzesPage and child widgets)

class QuizzesPage extends ConsumerStatefulWidget {
  const QuizzesPage({super.key});
  @override
  ConsumerState<QuizzesPage> createState() => _QuizzesPageViewState();
}

class _QuizzesPageViewState extends ConsumerState<QuizzesPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _bgController;
  late ConfettiController _confettiControllerLocal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _confettiControllerLocal =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgController.dispose();
    _confettiControllerLocal.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(quizNotifierProvider.notifier).syncTimers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizNotifierProvider);
    final notifier = ref.read(quizNotifierProvider.notifier);
    final mq = MediaQuery.of(context);

    const primaryGreen = Color(0xFF4CAF50);
    const mssnGreenA = Color(0xFF2E7D32);
    const mssnGreenC = Color(0xFF66BB6A);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final back = dark ? Colors.black : Colors.white;
    final contentWhite = Colors.white;

    if (state.confetti) {
      try {
        _confettiControllerLocal.play();
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: back,
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          final g1 = Color.lerp(primaryGreen, mssnGreenA, t)!;
          final g2 = Color.lerp(mssnGreenA, mssnGreenC, t)!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.9 + t * 1.8, -1),
                end: Alignment(0.9 - t * 1.8, 1),
                colors: [g1.withOpacity(0.95), g2.withOpacity(0.9)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: mq.size.width > 900 ? 64 : 16,
                    vertical: mq.size.width > 900 ? 24 : 12),
                child: Column(
                  children: [
                    // top bar
                    Row(
                      children: [
                        _iconCircle(Icons.close,
                            onTap: () => Navigator.of(context).pop(),
                            tint: contentWhite),
                        const SizedBox(width: 12),
                        _iconCircle(Icons.volume_up,
                            onTap: () {}, tint: contentWhite),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _openLeaderboardPage(context, state),
                          child: _TopRightProgress(
                              state: state, primaryColor: primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // main area
                    Expanded(
                      child: Builder(
                        builder: (_) {
                          if (state.loading) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white));
                          }
                          if (state.fetchError) {
                            return _ErrorScreen(onRetry: () => notifier.retryLoad());
                          }
                          if (state.dailyLimitReached) {
                            return const _DailyLimitReachedScreen();
                          }
                          if (state.currentIndex < 0) {
                            return _CircularCountdown(
                                countdown: state.countdown,
                                primaryColor: primaryGreen);
                          }
                          if (state.finished) {
                            return _FinishedScreen(
                              totalPoints: state.totalPoints,
                              quizzesCompleted:
                                  state.questionsAnsweredToday,
                              onViewLeaderboard: () =>
                                  _openLeaderboardPage(context, state),
                            );
                          }
                          return _buildQuestionArea(state, notifier);
                        },
                      ),
                    ),

                    // footer
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'You have ${state.totalPoints} points in this session.',
                            style: TextStyle(
                                color: contentWhite.withOpacity(0.92)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openLeaderboardPage(context, state),
                          icon: const Icon(Icons.leaderboard_rounded),
                          label: const Text('Leaderboard'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: contentWhite,
                              foregroundColor: primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.topRight,
                      child: ConfettiWidget(
                        confettiController: _confettiControllerLocal,
                        blastDirectionality: BlastDirectionality.explosive,
                        emissionFrequency: 0.02,
                        numberOfParticles: 30,
                        maxBlastForce: 12,
                        minBlastForce: 5,
                        gravity: 0.2,
                        colors: const [
                          Colors.green,
                          Colors.white,
                          Colors.lightGreenAccent
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _iconCircle(IconData icon,
      {required VoidCallback onTap, Color tint = Colors.white}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: tint),
      ),
    );
  }

  Widget _TopRightProgress(
      {required QuizState state, required Color primaryColor}) {
    final total = state.questions.isNotEmpty ? state.questions.length : 10;
    final current =
        (state.currentIndex >= 0 && !state.finished) ? state.currentIndex + 1 : 0;
    final percent = (current / total).clamp(0.0, 1.0);

    return CircularPercentIndicator(
      radius: 34,
      lineWidth: 6,
      percent: percent,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Q$current/$total',
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('${(percent * 100).toInt()}%',
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
      backgroundColor: Colors.white24,
      progressColor: Colors.white,
      circularStrokeCap: CircularStrokeCap.round,
    );
  }

  Widget _CircularCountdown(
      {required int countdown, required Color primaryColor}) {
    final size = min(MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height) *
        0.55;
    final radius = size * 0.45;
    final pct = ((5 - countdown) / 5).clamp(0.0, 1.0);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularPercentIndicator(
          radius: radius,
          lineWidth: 16,
          percent: pct,
          circularStrokeCap: CircularStrokeCap.round,
          center: Center(
              child: Text(countdown > 0 ? '$countdown' : 'Go',
                  style: TextStyle(
                      fontSize: radius * 0.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))),
          progressColor: Colors.white,
          backgroundColor: Colors.white10,
        ),
        const SizedBox(height: 18),
        Text('Get ready',
            style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildQuestionArea(QuizState state, QuizNotifier notifier) {
    final idx = state.currentIndex;
    final q = state.questions[idx];
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, primary, secondary) => SharedAxisTransition(
        animation: primary,
        secondaryAnimation: secondary,
        transitionType: SharedAxisTransitionType.vertical,
        child: child,
      ),
      child: _QuestionCard(
        key: ValueKey<int>(idx),
        question: q,
        index: idx,
        total: state.questions.length,
        timeLeft: state.questionTimeLeft,
        totalPointsSoFar: state.totalPoints,
        showingFeedback: state.showingFeedback,
        onSelect: (i) => notifier.selectAnswer(i),
      ),
    );
  }

  void _openLeaderboardPage(BuildContext c, QuizState state) {
    if (!mounted) return;
    Navigator.of(c).push(MaterialPageRoute(
        builder: (_) =>
            LeaderboardPage(leaderboard: state.leaderboard, confetti: state.confetti)));
  }
}

class LeaderboardPage extends ConsumerStatefulWidget {
  final List<UserScore> leaderboard;
  final bool confetti;

  const LeaderboardPage({
    super.key,
    required this.leaderboard,
    required this.confetti,
  });

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  late ConfettiController _confettiController;
  late List<UserScore> sortedLeaderboard;

  @override
  void initState() {
    super.initState();

    // Sort leaderboard descending by points
    sortedLeaderboard = List<UserScore>.from(widget.leaderboard)
      ..sort((a, b) => b.points.compareTo(a.points));

    // Initialize confetti
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.confetti) {
        _confettiController.play();
        // Reset confetti flag in provider safely (use notifier to set state)
        final current = ref.read(quizNotifierProvider);
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        ref.read(quizNotifierProvider.notifier).state =
            current.copyWith(confetti: false);
      }

      // Optional: sync leaderboard to provider
      ref.read(leaderboardProvider.notifier).setLeaderboard(sortedLeaderboard.cast<UserScore>());
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        backgroundColor: primaryGreen,
      ),
      backgroundColor: isDark ? Colors.black : Colors.grey[900],
      body: Stack(
        children: [
          if (sortedLeaderboard.isEmpty)
            const Center(
              child: Text(
                'No leaderboard data yet.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          else
            ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: sortedLeaderboard.length,
              separatorBuilder: (_, __) => const Divider(
                color: Colors.white12,
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final user = sortedLeaderboard[index];
                final rank = index + 1;

                final bgColor = switch (rank) {
                  1 => primaryGreen.withOpacity(0.25),
                  2 => primaryGreen.withOpacity(0.18),
                  3 => primaryGreen.withOpacity(0.12),
                  _ => Colors.transparent,
                };

                final Widget rankWidget = switch (rank) {
                  1 => const Icon(Icons.emoji_events,
                      color: Colors.amberAccent, size: 26),
                  2 => const Icon(Icons.emoji_events,
                      color: Colors.grey, size: 24),
                  3 => const Icon(Icons.emoji_events,
                      color: Color(0xFFCD7F32), size: 24),
                  _ => Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                };

                return Container(
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 30, child: Center(child: rankWidget)),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white24,
                        child: user.photoUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                        // Optionally you can display NetworkImage if photoUrl exists
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${user.points} pts',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 25,
                gravity: 0.3,
                colors: const [
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.white,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// -------------------------------
/// Error screen for failed question load
/// -------------------------------
class _ErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          const Text('Failed to load quiz questions.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Please check your assets or retry.',
              style: TextStyle(color: dark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4CAF50)),
          ),
        ]),
      ),
    );
  }
}

/// -------------------------------
/// Daily limit reached screen
/// -------------------------------
class _DailyLimitReachedScreen extends StatelessWidget {
  const _DailyLimitReachedScreen();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_clock, color: Colors.white, size: 64),
          const SizedBox(height: 12),
          Text('Daily Limit Reached',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('You have completed today’s quiz. Come back tomorrow!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white)),
        ]),
      ),
    );
  }
}

/// -------------------------------
/// Finished Screen (after quiz end)
/// -------------------------------
class _FinishedScreen extends StatelessWidget {
  final int totalPoints;
  final int quizzesCompleted;
  final VoidCallback onViewLeaderboard;

  const _FinishedScreen({
    required this.totalPoints,
    required this.quizzesCompleted,
    required this.onViewLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF4CAF50);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 56, color: primaryGreen),
            const SizedBox(height: 12),
            Text(
              'Quiz for today finished',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nice work — you earned $totalPoints points. Come back tomorrow to try again!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: onViewLeaderboard,
                  icon: const Icon(Icons.leaderboard_rounded),
                  label: const Text('View Leaderboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$quizzesCompleted/10 daily quizzes completed',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------------------
/// Question Card with numbering & improved option UI
/// -------------------------------

class _QuestionCard extends StatefulWidget {
  final QuizQuestion question;
  final int index;
  final int total;
  final int timeLeft;
  final int totalPointsSoFar;
  final bool showingFeedback;
  final void Function(int) onSelect;

  const _QuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.total,
    required this.timeLeft,
    required this.totalPointsSoFar,
    required this.showingFeedback,
    required this.onSelect,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF4CAF50);
    final pct = (widget.timeLeft / 15).clamp(0.0, 1.0);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final optionTextColor = dark ? Colors.white : Colors.black87;
    final questionNumber = widget.index + 1;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (!dark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight * 0.55,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Text(
                'Question $questionNumber of ${widget.total}',
                style: TextStyle(
                    color: dark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
              const SizedBox(height: 8),

              // Timer
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  final s = 1 + sin(_pulse.value * 2 * pi) * 0.02;
                  return Transform.scale(
                    scale: s,
                    child: CircularPercentIndicator(
                      radius: MediaQuery.of(context).size.width * 0.12,
                      lineWidth: 6.0,
                      percent: pct,
                      center: Text(
                        '${widget.timeLeft}s',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen),
                      ),
                      progressColor: primaryGreen,
                      backgroundColor:
                          dark ? Colors.white24 : Colors.black12,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Question text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.question.question,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Option cards
              ...List.generate(widget.question.options.length, (i) {
                final option = widget.question.options[i];
                final selected = widget.question.selectedIndex == i;
                final correct = i == widget.question.correctIndex;
                Color bgColor = dark ? Colors.white10 : Colors.white;
                Color borderColor =
                    dark ? Colors.white12 : Colors.grey.shade300;
                Color txtColor = optionTextColor;

                if (widget.showingFeedback) {
                  if (selected && correct) {
                    bgColor = primaryGreen;
                    borderColor = primaryGreen;
                    txtColor = Colors.white;
                  } else if (selected && !correct) {
                    bgColor = Colors.redAccent;
                    borderColor = Colors.redAccent;
                    txtColor = Colors.white;
                  } else if (correct) {
                    bgColor = Colors.green.shade700;
                    borderColor = Colors.green.shade700;
                    txtColor = Colors.white;
                  }
                } else if (selected) {
                  bgColor = primaryGreen.withOpacity(0.9);
                  borderColor = primaryGreen;
                  txtColor = Colors.white;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      if (!dark)
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap:
                        widget.showingFeedback ? null : () => widget.onSelect(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: dark
                                    ? Colors.white24
                                    : Colors.grey.shade400,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: TextStyle(
                                color: txtColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: txtColor,
                                fontSize: 15.5,
                              ),
                            ),
                          ),
                          if (widget.showingFeedback)
                            Icon(
                              correct
                                  ? Icons.check_circle
                                  : (selected
                                      ? Icons.cancel
                                      : Icons.circle_outlined),
                              color: correct
                                  ? Colors.greenAccent
                                  : (selected
                                      ? Colors.redAccent
                                      : Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Points Progress
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (widget.totalPointsSoFar % 100) / 100,
                        backgroundColor:
                            dark ? Colors.white10 : Colors.black12,
                        color: primaryGreen,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.totalPointsSoFar} pts',
                    style: TextStyle(
                      color: dark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
