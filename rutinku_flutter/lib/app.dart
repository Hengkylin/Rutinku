import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_routes.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';

class App extends StatelessWidget {
  const App({super.key, this.home});

  /// Override opsional (mis. untuk pengujian). Jika null, home ditentukan
  /// dari status login Supabase.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rutinku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Sudah login -> Dashboard, belum login -> AuthScreen
      home: home ??
          (Supabase.instance.client.auth.currentUser != null
              ? const MainScreen()
              : const AuthScreen()),
      routes: AppRoutes.routes,
    );
  }
}