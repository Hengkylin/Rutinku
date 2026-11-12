import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:rutinku_flutter/services/app_logger.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('rutinku_log_test');
    await AppLogger.init(directory: dir, printToConsole: false);
  });

  tearDown(() async {
    await AppLogger.dispose();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('log ditulis ke file dengan waktu, level, dan sumber', () async {
    AppLogger.get('habit').info('Rutinitas disimpan');

    final logs = await AppLogger.readLogs();

    expect(logs, contains('INFO'));
    expect(logs, contains('[rutinku.habit]'));
    expect(logs, contains('Rutinitas disimpan'));
    expect(logs, matches(RegExp(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}')));
  });

  test('error dan stack trace ikut dicatat', () async {
    try {
      throw StateError('data rusak');
    } catch (e, s) {
      AppLogger.get('sync').severe('Gagal restore', e, s);
    }

    final logs = await AppLogger.readLogs();

    expect(logs, contains('SEVERE'));
    expect(logs, contains('Gagal restore'));
    expect(logs, contains('Bad state: data rusak'));
    expect(logs, contains('app_logger_test.dart')); // baris stack trace
  });

  test('log dari library lain (mis. Supabase) ikut tertangkap', () async {
    Logger('supabase.auth').warning('Notifying exception otp_expired');

    expect(await AppLogger.readLogs(), contains('[supabase.auth]'));
  });

  test('level di bawah INFO (mis. URL deep link Supabase) tidak dicatat', () async {
    Logger('supabase.supabase_flutter')
        .finest('handle deeplink uri: io.supabase.rutinku://x?code=rahasia');

    expect(await AppLogger.readLogs(), isNot(contains('rahasia')));
  });

  test('file dirotasi saat melewati batas ukuran', () async {
    await AppLogger.dispose();
    await AppLogger.init(directory: dir, printToConsole: false, maxFileBytes: 300);
    final log = AppLogger.get('rotasi');

    for (var i = 0; i < 20; i++) {
      log.info('baris log nomor $i yang cukup panjang untuk memicu rotasi');
    }
    final logs = await AppLogger.readLogs();

    expect(File('${dir.path}/${AppLogger.fileName}.1').existsSync(), isTrue);
    expect(logs, contains('nomor 19')); // log terbaru tetap ada
    expect(logs, isNot(contains('nomor 0 '))); // log terlama terbuang
  });

  test('clearLogs mengosongkan log', () async {
    AppLogger.get('habit').info('akan dihapus');
    await AppLogger.readLogs();

    await AppLogger.clearLogs();

    expect(await AppLogger.readLogs(), isEmpty);
  });

  test('maskEmail menyamarkan alamat email', () {
    expect(AppLogger.maskEmail('hengky.1@student.ac.id'), 'h***@student.ac.id');
    expect(AppLogger.maskEmail('bukan-email'), '***');
  });
}
