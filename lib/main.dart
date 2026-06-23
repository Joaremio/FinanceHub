import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pages/auth_gate.dart';
import 'pages/register_page.dart';
import 'services/theme_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FinanceHubApp());
}

class FinanceHubApp extends StatefulWidget {
  const FinanceHubApp({super.key});

  @override
  State<FinanceHubApp> createState() => _FinanceHubAppState();
}

class _FinanceHubAppState extends State<FinanceHubApp> {
  final ThemePreferences _themePreferences = ThemePreferences();
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTheme());
  }

  Future<void> _loadTheme() async {
    final darkMode = await _themePreferences.loadDarkMode();
    if (!mounted) return;
    setState(() => _darkMode = darkMode);
  }

  void _setDarkMode(bool enabled) {
    setState(() => _darkMode = enabled);
    unawaited(_themePreferences.saveDarkMode(enabled));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthGate(
          darkMode: _darkMode,
          onDarkModeChanged: _setDarkMode,
        ),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}
