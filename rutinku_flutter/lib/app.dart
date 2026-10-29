import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_routes.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

class App extends StatelessWidget {
  const App({super.key, this.home});

  /// Override opsional (mis. untuk pengujian). Jika null, home ditentukan
  /// dari status login Supabase.
  final Widget? home;

  User? get _currentUser {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;

    return MaterialApp(
      title: 'Rutinku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Jika currentUser == null -> LoginScreen, selain itu -> MainScreen
      home: home ??
          (currentUser == null ? const LoginScreen() : const MainScreen()),
      routes: AppRoutes.routes,
    );
  }
}
