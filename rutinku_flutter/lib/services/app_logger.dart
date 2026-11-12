import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Sistem log aplikasi untuk menelusuri masalah saat aplikasi berjalan,
/// termasuk di build release (APK).
///
/// * Semua log `package:logging` diteruskan: log aplikasi (`rutinku.*`) dan
///   log internal library seperti Supabase (`supabase.*`).
/// * Setiap baris dicetak ke konsol/logcat (tag `flutter`) **dan** disimpan ke
///   file di penyimpanan aplikasi. File dirotasi saat melewati
///   [maxFileBytes] (disimpan 1 cadangan `.1`), jadi ukuran total terbatas.
/// * Level minimum INFO, sehingga log FINE/FINEST (mis. URL deep link berisi
///   kode dari Supabase) tidak pernah tersimpan.
/// * Error yang tidak tertangkap dicatat lewat [installErrorHandlers].
///
/// Jangan mencatat password, token, atau kode OTP. Samarkan email dengan
/// [maskEmail].
class AppLogger {
  AppLogger._();

  static const String fileName = 'rutinku_log.txt';
  static const int defaultMaxFileBytes = 512 * 1024;

  static Directory? _directory;
  static int _maxFileBytes = defaultMaxFileBytes;
  static bool _printToConsole = true;
  static StreamSubscription<LogRecord>? _subscription;
  static Future<void> _pendingWrite = Future<void>.value();

  /// Logger bernama `rutinku.<name>`, mis. `AppLogger.get('auth')`.
  static Logger get(String name) => Logger('rutinku.$name');

  /// Menyiapkan logger. [directory] default: folder dokumen aplikasi; jika
  /// tidak tersedia (mis. saat pengujian), log hanya dicetak ke konsol.
  static Future<void> init({
    Directory? directory,
    bool printToConsole = true,
    int maxFileBytes = defaultMaxFileBytes,
  }) async {
    await dispose();
    _printToConsole = printToConsole;
    _maxFileBytes = maxFileBytes;
    _directory = directory ?? await _defaultDirectory();

    Logger.root.level = Level.INFO;
    _subscription = Logger.root.onRecord.listen(_handleRecord);
  }

  /// Berhenti mendengarkan log dan menunggu semua penulisan selesai.
  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _pendingWrite;
    _directory = null;
  }

  /// Mencatat error Flutter (build/layout) dan error async yang tidak
  /// tertangkap. Dipanggil sekali di `main()`, tidak dipakai di pengujian.
  static void installErrorHandlers() {
    final log = get('crash');
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      log.severe(
        'Flutter error: ${details.exceptionAsString()}',
        details.exception,
        details.stack,
      );
      previousOnError?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      log.shout('Error tidak tertangkap', error, stack);
      return true; // sudah ditangani: jangan tutup aplikasi
    };
  }

  /// Baris pembuka setiap sesi: versi aplikasi, mode build, dan OS, agar
  /// jelas log berasal dari build mana.
  static Future<void> logStartup() async {
    var version = 'tidak diketahui';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {
      // Platform tanpa plugin (mis. pengujian): versi tidak dicatat.
    }
    const mode = kReleaseMode
        ? 'release'
        : kProfileMode
            ? 'profile'
            : 'debug';
    get('app').info(
      '===== Aplikasi dimulai | versi $version | mode $mode | '
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion} =====',
    );
  }

  /// Isi log (cadangan lama lalu yang terbaru), setelah penulisan selesai.
  static Future<String> readLogs() async {
    await _pendingWrite;
    final buffer = StringBuffer();
    for (final file in [_backupFile, _currentFile]) {
      if (file != null && await file.exists()) {
        buffer.write(await file.readAsString());
      }
    }
    return buffer.toString();
  }

  /// Menghapus semua log tersimpan.
  static Future<void> clearLogs() async {
    await _pendingWrite;
    for (final file in [_backupFile, _currentFile]) {
      if (file != null && await file.exists()) await file.delete();
    }
  }

  /// `hengky@mail.com` → `h***@mail.com`, agar email tidak tersimpan utuh.
  static String maskEmail(String email) {
    final at = email.indexOf('@');
    if (at < 1) return '***';
    return '${email[0]}***${email.substring(at)}';
  }

  /// Satu baris log: waktu, level, sumber, pesan, lalu error & stack trace.
  @visibleForTesting
  static String format(LogRecord record) {
    final buffer = StringBuffer()
      ..write(_timestamp(record.time))
      ..write(' ')
      ..write(record.level.name.padRight(7))
      ..write(' [${record.loggerName}] ')
      ..write(record.message);
    if (record.error != null) buffer.write('\n    error: ${record.error}');
    if (record.stackTrace != null) {
      final frames = record.stackTrace.toString().trimRight().split('\n');
      for (final frame in frames.take(15)) {
        buffer.write('\n    $frame');
      }
    }
    return buffer.toString();
  }

  static void _handleRecord(LogRecord record) {
    final line = format(record);
    if (_printToConsole) debugPrint(line);
    if (_directory == null) return;
    _pendingWrite = _pendingWrite
        .then((_) => _append(line))
        .catchError((Object _) {}); // gagal menulis log tidak boleh crash
  }

  static Future<void> _append(String line) async {
    final file = _currentFile!;
    if (await file.exists() && await file.length() >= _maxFileBytes) {
      final backup = _backupFile!;
      if (await backup.exists()) await backup.delete();
      await file.rename(backup.path);
    }
    await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
  }

  static File? get _currentFile =>
      _directory == null ? null : File('${_directory!.path}/$fileName');

  static File? get _backupFile =>
      _directory == null ? null : File('${_directory!.path}/$fileName.1');

  static Future<Directory?> _defaultDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return null;
    }
  }

  static String _timestamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.$ms';
  }
}
