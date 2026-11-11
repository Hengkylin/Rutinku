import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'routes/app_routes.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'widgets/app_snackbar.dart';

class App extends StatefulWidget {
  const App({super.key, this.home, this.authService});

  /// Override opsional (mis. untuk pengujian). Jika null, home ditentukan
  /// dari status login Supabase.
  final Widget? home;

  /// Override opsional (mis. mock saat pengujian).
  final AuthService? authService;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  /// Dipakai untuk menampilkan pesan dari luar widget tree (listener auth).
  final _navigatorKey = GlobalKey<NavigatorState>();

  late final AuthService _auth = widget.authService ?? AuthService();
  StreamSubscription<AuthState>? _authSubscription;

  User? get _currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null; // Supabase belum diinisialisasi (mis. saat pengujian).
    }
  }

  @override
  void initState() {
    super.initState();
    _listenAuthStateChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Hanya mendengarkan *error* auth. Event sukses (mis. passwordRecovery
  /// dari verifikasi kode reset) tidak memicu navigasi di sini: layar
  /// Masukkan Kode yang membuka Password Baru, agar tidak terbuka dua kali.
  void _listenAuthStateChanges() {
    try {
      _authSubscription = _auth.onAuthStateChange.listen(
        (_) {},
        // Error stream auth tidak boleh membuat aplikasi crash. Error dari
        // link email (mis. link verifikasi pendaftaran kedaluwarsa)
        // ditampilkan ke pengguna; error lain (mis. refresh token
        // kedaluwarsa) diabaikan karena sesi akan diminta ulang lewat Login.
        onError: _onAuthError,
      );
    } catch (_) {
      // Supabase belum diinisialisasi (mis. saat pengujian).
    }
  }

  void _onAuthError(Object error) {
    final message = AuthService.linkErrorMessage(error);
    if (message == null) return;

    final context = _navigatorKey.currentContext;
    if (context == null) {
      // Error datang sebelum Navigator siap (cold start dari link email).
      WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthError(error));
      return;
    }
    showAppSnackBar(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Rutinku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Jika currentUser == null -> LoginScreen, selain itu -> MainScreen
      home: widget.home ??
          (_currentUser == null ? const LoginScreen() : const MainScreen()),
      routes: AppRoutes.routes,
    );
  }
}
