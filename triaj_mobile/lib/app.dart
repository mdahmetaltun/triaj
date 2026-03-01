import 'package:flutter/material.dart';

import 'presentation/triage_home_page.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_bootstrap.dart';

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
    final textTheme = ThemeData(brightness: brightness).textTheme;

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
      home: _AuthGate(themeMode: _themeMode, onToggleTheme: _toggleThemeMode),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.themeMode, required this.onToggleTheme});

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      setState(() {
        _error = 'Google giriş başarısız: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isReady) {
      return TriageHomePage(
        themeMode: widget.themeMode,
        onToggleTheme: widget.onToggleTheme,
      );
    }

    return StreamBuilder(
      stream: _authService.authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != null) {
          return TriageHomePage(
            themeMode: widget.themeMode,
            onToggleTheme: widget.onToggleTheme,
          );
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF4FB), Color(0xFFFFEFD8)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFFF9F68)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x668B5CF6),
                                blurRadius: 30,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Text(
                            '🏥',
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Triyaj Karar Sistemi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Devam etmek için Google ile giriş yap.',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _signIn,
                            icon: const Icon(Icons.login_rounded),
                            label: Text(
                              _busy ? 'Bağlanıyor...' : 'Google ile Giriş Yap',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB42318),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
