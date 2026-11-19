import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_logger.dart';

/// Sumber waktu yang bisa diganti di tes (`clockProvider.overrideWithValue`).
typedef Clock = DateTime Function();

final clockProvider = Provider<Clock>((ref) => DateTime.now);

/// Tanggal "hari ini" (tanpa jam) yang dipakai seluruh UI.
///
/// Berganti otomatis tepat setelah pukul 00:00 (timer) dan setiap kali
/// aplikasi kembali ke depan (resume), sehingga dashboard, streak, kalender,
/// dan analitik ikut dihitung ulang walaupun aplikasi tidak ditutup
/// semalaman (issue #4). Widget cukup `ref.watch(todayProvider)`.
final todayProvider =
    NotifierProvider<TodayNotifier, DateTime>(TodayNotifier.new);

class TodayNotifier extends Notifier<DateTime> {
  static final _log = AppLogger.get('hari');

  late Clock _clock;
  Timer? _midnightTimer;

  @override
  DateTime build() {
    _clock = ref.watch(clockProvider);

    final observer = _ResumeObserver(refresh);
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() {
      _midnightTimer?.cancel();
      WidgetsBinding.instance.removeObserver(observer);
    });

    _scheduleNextMidnight();
    return dateOnly(_clock());
  }

  /// Memeriksa ulang tanggal sekarang; state hanya berubah (dan UI hanya
  /// digambar ulang) jika hari benar-benar sudah berganti.
  void refresh() {
    final today = dateOnly(_clock());
    if (today != state) {
      _log.info('Pergantian hari terdeteksi: ${_fmt(state)} -> ${_fmt(today)}');
      state = today;
    }
    _scheduleNextMidnight();
  }

  void _scheduleNextMidnight() {
    _midnightTimer?.cancel();
    final now = _clock();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    // +1 detik agar timer pasti jatuh setelah pergantian hari.
    _midnightTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      refresh,
    );
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _ResumeObserver extends WidgetsBindingObserver {
  _ResumeObserver(this.onResume);

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
