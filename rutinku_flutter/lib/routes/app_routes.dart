import 'package:flutter/material.dart';
import '../screens/calendar_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/sync_screen.dart';

class AppRoutes {
  static const String main = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String calendar = '/calendar';
  static const String sync = '/sync';

  static final Map<String, WidgetBuilder> routes = {
    main: (context) => const MainScreen(),
    login: (context) => const LoginScreen(),
    dashboard: (context) => const MainScreen(),
    calendar: (context) => const CalendarScreen(),
    sync: (context) => const SyncScreen(),
  };
}