import 'package:flutter/material.dart';
import '../screens/calendar_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/register_screen.dart';
import '../screens/sync_screen.dart';

class AppRoutes {
  static const String main = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String calendar = '/calendar';
  static const String sync = '/sync';

  // Catatan: route '/' (main) tidak didaftarkan karena halaman awal ditentukan
  // oleh `MaterialApp.home` (LoginScreen / MainScreen) di app.dart.
  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    dashboard: (context) => const MainScreen(),
    calendar: (context) => const CalendarScreen(),
    sync: (context) => const SyncScreen(),
  };
}
