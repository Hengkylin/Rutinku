import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase (Autentikasi & Cloud Sync)
  await Supabase.initialize(
    url: 'https://vlwkzlbyxnxqnflbjuap.supabase.co',
    publishableKey: 'sb_publishable_3ZAEbf26hWeNslmmYvYYKg_feKdqK_O',
  );

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