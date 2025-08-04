import 'package:bank_app/Pages/notifications_page.dart';
import 'package:bank_app/Pages/updated_registration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/theme_provider.dart';
import 'pages/auth_page.dart';         // Add your actual registration page import
import 'pages/transactions_page.dart';        // Add your actual transactions page import
import 'utils/app_theme.dart';
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
    final isDarkMode = ref.watch(isDarkModeProvider);

    return MaterialApp(
      title: 'SmartOUI Banking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthPage(),
        '/register': (context) => const RegistrationPage2(), // Use your actual registration page class
        '/transactions': (context) => const TransactionsPage(), // Use your actual transactions page class
        '/notifications': (context) => const NotificationsPage(),
      },
    );
  }
}
