import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DbNeighborsApp());
}

class DbNeighborsApp extends StatelessWidget {
  const DbNeighborsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'dB Neighbors',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) return const HomeScreen();
          return const AuthScreen();
        },
      ),
    );
  }
}

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A1A2E),
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    scaffoldBackgroundColor: const Color(0xFFF8F8F8),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4ADE80),
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: const Color(0xFF0F0F1A),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.graphic_eq, size: 64, color: Color(0xFF4ADE80)),
            SizedBox(height: 16),
            Text('dB Neighbors', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
