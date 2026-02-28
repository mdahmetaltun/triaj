import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'presentation/triage_home_page.dart';

class TriageMobileApp extends StatefulWidget {
  const TriageMobileApp({super.key});

  @override
  State<TriageMobileApp> createState() => _TriageMobileAppState();
}

class _TriageMobileAppState extends State<TriageMobileApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleThemeMode() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  ThemeData _buildTheme(Brightness brightness) {
    const seed = Color(0xFF9B6BFF);
    final isDark = brightness == Brightness.dark;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: baseScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF140F24)
          : const Color(0xFFFFF4FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF211833) : const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2A1F40) : const Color(0xFFFFFBFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF4A3970) : const Color(0xFFE5D6F8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF4A3970) : const Color(0xFFE5D6F8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: seed, width: 1.2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTS / STS Triyaj',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: TriageHomePage(
        themeMode: _themeMode,
        onToggleTheme: _toggleThemeMode,
      ),
    );
  }
}
