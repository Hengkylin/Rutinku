import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Smart Reminder & minta izin notifikasi
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermission();

  // Bungkus App() dengan ProviderScope
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}