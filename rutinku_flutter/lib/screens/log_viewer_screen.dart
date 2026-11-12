import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_logger.dart';
import '../widgets/app_snackbar.dart';

/// Halaman untuk melihat, menyalin, dan menghapus log aplikasi di perangkat.
/// Dipakai penguji/pengguna untuk mengirim log ke pengembang saat ada masalah
/// (di APK release, log tidak bisa diambil lewat `adb run-as`).
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({
    super.key,
    this.readLogs = AppLogger.readLogs,
    this.clearLogs = AppLogger.clearLogs,
  });

  final Future<String> Function() readLogs;
  final Future<void> Function() clearLogs;

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  static const _navy = Color(0xFF1E293B);

  /// Batas baris yang dirender agar layar tetap ringan; tombol Salin tetap
  /// menyalin seluruh log.
  static const _maxDisplayedLines = 1500;

  late Future<String> _logs = widget.readLogs();

  void _reload() {
    setState(() {
      _logs = widget.readLogs();
    });
  }

  Future<void> _copyAll() async {
    final logs = await widget.readLogs();
    await Clipboard.setData(ClipboardData(text: logs));
    if (!mounted) return;
    showAppSnackBar(
      context,
      'Log disalin. Tempel di chat/email untuk dikirim ke pengembang.',
    );
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus semua log?'),
        content: const Text(
          'Log yang dihapus tidak bisa dikembalikan. Salin dulu jika masih '
          'diperlukan untuk laporan masalah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            key: const Key('log_clear_confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.clearLogs();
    if (!mounted) return;
    _reload();
    showAppSnackBar(context, 'Log dihapus');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Log Aplikasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _navy,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            key: const Key('log_reload_button'),
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _reload,
          ),
          IconButton(
            key: const Key('log_copy_button'),
            tooltip: 'Salin semua',
            icon: const Icon(Icons.copy_all_rounded, color: Colors.white),
            onPressed: _copyAll,
          ),
          IconButton(
            key: const Key('log_clear_button'),
            tooltip: 'Hapus log',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFE2E8F0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Text(
              'Saat melaporkan masalah, tekan ikon salin lalu kirim isinya ke '
              'pengembang. Log tidak berisi password atau kode OTP.',
              style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: _logs,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Gagal membaca log: ${snapshot.error}'),
                  );
                }
                final logs = snapshot.data ?? '';
                if (logs.trim().isEmpty) {
                  return const Center(child: Text('Belum ada log'));
                }
                return _buildLogText(logs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogText(String logs) {
    final lines = logs.trimRight().split('\n');
    final shown = lines.length > _maxDisplayedLines
        ? lines.sublist(lines.length - _maxDisplayedLines)
        : lines;

    return Scrollbar(
      child: SingleChildScrollView(
        reverse: true, // mulai dari log terbaru (paling bawah)
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText(
            shown.join('\n'),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}
