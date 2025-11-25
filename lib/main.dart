import 'package:bank_app/Pages/event_page.dart';
import 'package:bank_app/Pages/notifications_page.dart';
import 'package:bank_app/Pages/prayer_times_page.dart';
import 'package:bank_app/Pages/quiz_page.dart';
import 'package:bank_app/Pages/quran_page.dart';
import 'package:bank_app/Pages/reminders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/theme_provider.dart';   
import 'pages/auth_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBwBERtzMfNnKeQMcfqt_iQO5gV7dZo6uc",
        authDomain: "bankapp-8deff.firebaseapp.com",
        projectId: "bankapp-8deff",
        storageBucket: "bankapp-8deff.firebasestorage.app",
        messagingSenderId: "355307598766",
        appId: "1:355307598766:web:3dbac791f6c928a56dce3f",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: BankingApp(),
    ),
  );
}

class BankingApp extends ConsumerWidget {
  const BankingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);   
    final lightTheme = ref.watch(lightThemeProvider); 
    final darkTheme = ref.watch(darkThemeProvider);   

    return MaterialApp(
      title: 'SmartOUI Banking',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,         
      darkTheme: darkTheme,     
      themeMode: themeMode,      
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthPage(),
        '/quran': (context) => const QuranPage(),
        '/prayertimes': (context) => const PrayerTimesPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/quizzes': (context) => QuizzesPage(),
        '/events': (context) => EventsPage(),
        '/reminders': (context) => RemindersPage(),
      },
    );
  }
}
