import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'services/app_logger.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log disiapkan paling awal agar error saat start-up ikut tercatat.
  await AppLogger.init();
  AppLogger.installErrorHandlers();
  await AppLogger.logStartup();
  final log = AppLogger.get('main');

  // Inisialisasi Supabase (Autentikasi & Cloud Sync). `debug: false` karena
  // log Supabase sudah diteruskan oleh AppLogger (menghindari baris ganda).
  try {
    await Supabase.initialize(
      url: 'https://vlwkzlbyxnxqnflbjuap.supabase.co',
      publishableKey: 'sb_publishable_3ZAEbf26hWeNslmmYvYYKg_feKdqK_O',
      debug: false,
    );
    log.info('Supabase siap');
  } catch (e, s) {
    log.severe('Gagal inisialisasi Supabase', e, s);
    rethrow;
  }

  // Inisialisasi Smart Reminder & minta izin notifikasi
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermission();

  // Bungkus App() dengan ProviderScope
  runApp(const ProviderScope(child: App()));
}
